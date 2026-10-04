#include "sketchybar.h"

#include <CoreServices/CoreServices.h>
#include <dirent.h>
#include <dispatch/dispatch.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <signal.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <unistd.h>

#define LOCK_FILE "/tmp/trash_monitor.lock"
#define SKETCHYBAR_NAME "sketchybar"
#define FSEVENT_LATENCY 1.0

/* -------------------------------------------------------------------------- */
/* Global state                                                               */
/* -------------------------------------------------------------------------- */

static bool g_is_foreground = false;
static bool g_shutting_down = false;
static bool g_stream_started = false;

static FSEventStreamRef g_stream = NULL;
static int g_last_trash_count = -1;
static int g_lock_fd = -1;

/*
 * Keeping references to these sources alive for the lifetime of the process
 * is intentional.
 */
static dispatch_source_t g_sigint_source = NULL;
static dispatch_source_t g_sigterm_source = NULL;

/* -------------------------------------------------------------------------- */
/* Logging                                                                    */
/* -------------------------------------------------------------------------- */

static void log_to_terminal(const char *format, ...) {
  if (!g_is_foreground) {
    return;
  }

  va_list args;
  va_start(args, format);
  vprintf(format, args);
  va_end(args);

  fflush(stdout);
}

/* -------------------------------------------------------------------------- */
/* Single-instance lock                                                       */
/* -------------------------------------------------------------------------- */

enum lock_result {
  LOCK_RESULT_ERROR = -1,
  LOCK_RESULT_BUSY = 0,
  LOCK_RESULT_ACQUIRED = 1,
};

static enum lock_result acquire_lock(void) {
  g_lock_fd = open(LOCK_FILE, O_CREAT | O_RDWR | O_CLOEXEC | O_NOFOLLOW, 0600);

  if (g_lock_fd < 0) {
    return LOCK_RESULT_ERROR;
  }

  struct stat st;
  if (fstat(g_lock_fd, &st) < 0 || !S_ISREG(st.st_mode) ||
      st.st_uid != geteuid()) {
    int saved_errno = errno != 0 ? errno : EPERM;

    close(g_lock_fd);
    g_lock_fd = -1;

    errno = saved_errno;
    return LOCK_RESULT_ERROR;
  }

  /*
   * Older versions created the lock file as 0644. Tighten an existing file
   * to the permissions used by this version.
   */
  if (fchmod(g_lock_fd, 0600) < 0) {
    int saved_errno = errno;

    close(g_lock_fd);
    g_lock_fd = -1;

    errno = saved_errno;
    return LOCK_RESULT_ERROR;
  }

  for (;;) {
    if (flock(g_lock_fd, LOCK_EX | LOCK_NB) == 0) {
      break;
    }

    if (errno == EINTR) {
      continue;
    }

    if (errno == EWOULDBLOCK || errno == EAGAIN) {
      close(g_lock_fd);
      g_lock_fd = -1;
      return LOCK_RESULT_BUSY;
    }

    int saved_errno = errno;

    close(g_lock_fd);
    g_lock_fd = -1;

    errno = saved_errno;
    return LOCK_RESULT_ERROR;
  }

  /*
   * The PID is informational only. flock() provides the actual singleton
   * guarantee.
   */
  if (ftruncate(g_lock_fd, 0) == 0) {
    (void)dprintf(g_lock_fd, "%d\n", getpid());
  }

  return LOCK_RESULT_ACQUIRED;
}

static void release_lock(void) {
  if (g_lock_fd < 0) {
    return;
  }

  /*
   * Do not unlink the lock file. Closing the descriptor releases the flock.
   * Unlinking after unlocking introduces an inode race that can allow two
   * monitor instances to coexist.
   */
  close(g_lock_fd);
  g_lock_fd = -1;
}

/* -------------------------------------------------------------------------- */
/* Trash path/count                                                           */
/* -------------------------------------------------------------------------- */

static bool get_trash_path(char *buffer, size_t size) {
  const char *home = getenv("HOME");

  if (home == NULL || home[0] == '\0') {
    errno = ENOENT;
    return false;
  }

  int length = snprintf(buffer, size, "%s/.Trash", home);

  if (length < 0) {
    return false;
  }

  if ((size_t)length >= size) {
    errno = ENAMETOOLONG;
    return false;
  }

  return true;
}

static int get_trash_count(void) {
  char trash_path[PATH_MAX];

  if (!get_trash_path(trash_path, sizeof(trash_path))) {
    return -1;
  }

  DIR *dir = opendir(trash_path);
  if (dir == NULL) {
    return -1;
  }

  int count = 0;
  int saved_errno = 0;

  errno = 0;

  for (;;) {
    struct dirent *entry = readdir(dir);

    if (entry == NULL) {
      saved_errno = errno;
      break;
    }

    if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0 ||
        strcmp(entry->d_name, ".DS_Store") == 0) {
      continue;
    }

    if (count == INT_MAX) {
      saved_errno = EOVERFLOW;
      break;
    }

    count++;
  }

  if (closedir(dir) < 0 && saved_errno == 0) {
    saved_errno = errno;
  }

  if (saved_errno != 0) {
    errno = saved_errno;
    return -1;
  }

  return count;
}

/* -------------------------------------------------------------------------- */
/* SketchyBar notification                                                    */
/* -------------------------------------------------------------------------- */

static enum sketchybar_send_status trigger_trash_change(int count) {
  char command[128];

  int length = snprintf(command, sizeof(command),
                        "--trigger trash_change TRASH_COUNT=%d", count);

  if (length < 0 || (size_t)length >= sizeof(command)) {
    return SKETCHYBAR_SEND_FAILED;
  }

  return sketchybar_send(command, SKETCHYBAR_NAME, NULL);
}

static bool update_sketchybar_trash(bool force) {
  int count = get_trash_count();

  if (count < 0) {
    int saved_errno = errno;

    log_to_terminal("Failed to read Trash: %s\n", strerror(saved_errno));

    errno = saved_errno;
    return false;
  }

  if (!force && count == g_last_trash_count) {
    log_to_terminal("Trash count unchanged (%d), skipping update.\n", count);
    return true;
  }

  log_to_terminal("Updating Trash count: %d\n", count);

  enum sketchybar_send_status status = trigger_trash_change(count);

  if (status == SKETCHYBAR_SEND_FAILED) {
    /*
     * Do not change g_last_trash_count. A later FSEvent can retry the same
     * value after SketchyBar becomes reachable again.
     */
    log_to_terminal(
        "Failed to deliver Trash update to SketchyBar; will retry on a "
        "future event.\n");

    return false;
  }

  /*
   * SENT_NO_ACK still means the Mach send itself succeeded. Retrying merely
   * because the response timed out could trigger the same SketchyBar event
   * twice, so treat it as delivered.
   */
  if (status == SKETCHYBAR_SENT_NO_ACK) {
    log_to_terminal(
        "Trash update sent to SketchyBar, but no acknowledgement was "
        "received.\n");
  } else {
    log_to_terminal("Trash update acknowledged by SketchyBar.\n");
  }

  g_last_trash_count = count;
  return true;
}

/* -------------------------------------------------------------------------- */
/* FSEvents                                                                   */
/* -------------------------------------------------------------------------- */

static void fsevents_callback(ConstFSEventStreamRef stream_ref,
                              void *client_callback_info, size_t num_events,
                              void *event_paths,
                              const FSEventStreamEventFlags event_flags[],
                              const FSEventStreamEventId event_ids[]) {
  (void)stream_ref;
  (void)client_callback_info;
  (void)num_events;
  (void)event_paths;
  (void)event_flags;
  (void)event_ids;

  log_to_terminal(
      "FSEvents callback triggered. Checking for Trash changes...\n");

  (void)update_sketchybar_trash(false);
}

static void destroy_stream(void) {
  if (g_stream == NULL) {
    return;
  }

  if (g_stream_started) {
    FSEventStreamStop(g_stream);
    g_stream_started = false;
  }

  FSEventStreamInvalidate(g_stream);
  FSEventStreamRelease(g_stream);
  g_stream = NULL;
}

/* -------------------------------------------------------------------------- */
/* Process cleanup                                                            */
/* -------------------------------------------------------------------------- */

static void process_cleanup(void) {
  destroy_stream();
  cleanup_sketchybar();
  release_lock();
}

/* -------------------------------------------------------------------------- */
/* Signal handling                                                            */
/* -------------------------------------------------------------------------- */

/*
 * This is invoked by libdispatch on the main queue, rather than as a POSIX
 * async signal handler. It is therefore safe to use stdio, CoreFoundation,
 * FSEvents and the SketchyBar IPC cleanup code here.
 */
static void shutdown_monitor(int signum) {
  if (g_shutting_down) {
    return;
  }

  g_shutting_down = true;

  log_to_terminal("\nSignal %d received, shutting down...\n", signum);

  /*
   * exit() runs process_cleanup() via atexit().
   */
  exit(0);
}

static void signal_dispatch_handler(void *context) {
  int signum = (int)(intptr_t)context;
  shutdown_monitor(signum);
}

static bool setup_signal_sources(void) {
  /*
   * Dispatch signal sources require the corresponding POSIX signals to be
   * ignored so that normal signal delivery does not terminate the process.
   */
  if (signal(SIGINT, SIG_IGN) == SIG_ERR) {
    return false;
  }

  if (signal(SIGTERM, SIG_IGN) == SIG_ERR) {
    return false;
  }

  g_sigint_source = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGINT,
                                           0, dispatch_get_main_queue());

  if (g_sigint_source == NULL) {
    return false;
  }

  dispatch_set_context(g_sigint_source, (void *)(intptr_t)SIGINT);
  dispatch_source_set_event_handler_f(g_sigint_source, signal_dispatch_handler);

  g_sigterm_source = dispatch_source_create(
      DISPATCH_SOURCE_TYPE_SIGNAL, SIGTERM, 0, dispatch_get_main_queue());

  if (g_sigterm_source == NULL) {
    return false;
  }

  dispatch_set_context(g_sigterm_source, (void *)(intptr_t)SIGTERM);
  dispatch_source_set_event_handler_f(g_sigterm_source,
                                      signal_dispatch_handler);

  dispatch_resume(g_sigint_source);
  dispatch_resume(g_sigterm_source);

  return true;
}

/* -------------------------------------------------------------------------- */
/* FSEvent stream setup                                                       */
/* -------------------------------------------------------------------------- */

static bool setup_fsevents(const char *trash_path) {
  CFStringRef path_to_watch = CFStringCreateWithFileSystemRepresentation(
      kCFAllocatorDefault, trash_path);

  if (path_to_watch == NULL) {
    return false;
  }

  const void *values[] = {
      path_to_watch,
  };

  CFArrayRef paths_to_watch =
      CFArrayCreate(kCFAllocatorDefault, values, 1, &kCFTypeArrayCallBacks);

  CFRelease(path_to_watch);

  if (paths_to_watch == NULL) {
    return false;
  }

  FSEventStreamContext context = {
      .version = 0,
      .info = NULL,
      .retain = NULL,
      .release = NULL,
      .copyDescription = NULL,
  };

  g_stream = FSEventStreamCreate(
      kCFAllocatorDefault, fsevents_callback, &context, paths_to_watch,
      kFSEventStreamEventIdSinceNow, FSEVENT_LATENCY,
      kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagWatchRoot);

  CFRelease(paths_to_watch);

  if (g_stream == NULL) {
    return false;
  }

  FSEventStreamSetDispatchQueue(g_stream, dispatch_get_main_queue());

  if (!FSEventStreamStart(g_stream)) {
    FSEventStreamInvalidate(g_stream);
    FSEventStreamRelease(g_stream);
    g_stream = NULL;
    return false;
  }

  g_stream_started = true;
  return true;
}

/* -------------------------------------------------------------------------- */
/* CLI                                                                        */
/* -------------------------------------------------------------------------- */

static void usage(const char *program) {
  fprintf(stderr,
          "Usage:\n"
          "  %s          monitor Trash and notify SketchyBar\n"
          "  %s --count  print current Trash item count\n",
          program, program);
}

/* -------------------------------------------------------------------------- */
/* Main                                                                       */
/* -------------------------------------------------------------------------- */

int main(int argc, char **argv) {
  g_is_foreground = isatty(STDOUT_FILENO);

  if (argc == 2 && strcmp(argv[1], "--count") == 0) {
    int count = get_trash_count();

    if (count < 0) {
      fprintf(stderr, "Failed to read Trash: %s\n", strerror(errno));
      return 1;
    }

    /*
     * Preserve the previous interface: print only the integer, with no
     * trailing newline.
     */
    printf("%d", count);
    return 0;
  }

  if (argc != 1) {
    usage(argv[0]);
    return 1;
  }

  enum lock_result lock_result = acquire_lock();

  if (lock_result == LOCK_RESULT_BUSY) {
    /*
     * A monitor is already running. This commonly happens when SketchyBar is
     * reloaded and launches the helper again.
     *
     * Resend the current count before exiting so the newly started/reloaded
     * SketchyBar does not have to wait for the next filesystem event to learn
     * the current Trash state.
     */
    (void)update_sketchybar_trash(true);
    cleanup_sketchybar();
    return 0;
  }

  if (lock_result == LOCK_RESULT_ERROR) {
    if (g_is_foreground) {
      fprintf(stderr, "Failed to acquire monitor lock: %s\n", strerror(errno));
    }

    return 1;
  }

  if (atexit(process_cleanup) != 0) {
    release_lock();
    return 1;
  }

  log_to_terminal("Trash monitor starting up...\n");

  char trash_path[PATH_MAX];

  if (!get_trash_path(trash_path, sizeof(trash_path))) {
    if (g_is_foreground) {
      fprintf(stderr, "Failed to determine Trash path: %s\n", strerror(errno));
    }

    return 1;
  }

  if (!setup_signal_sources()) {
    log_to_terminal("FATAL: Failed to configure signal handling.\n");
    return 1;
  }

  if (!setup_fsevents(trash_path)) {
    log_to_terminal("FATAL: Failed to create/start FSEventStream.\n");
    return 1;
  }

  log_to_terminal("Monitoring Trash directory: %s\n", trash_path);

  /*
   * Always synchronize SketchyBar once on startup.
   */
  (void)update_sketchybar_trash(true);

  dispatch_main();

  /* dispatch_main() never returns. */
  return 0;
}
