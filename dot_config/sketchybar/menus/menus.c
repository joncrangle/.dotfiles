#include <ApplicationServices/ApplicationServices.h>
#include <Carbon/Carbon.h>
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <math.h>
#include <signal.h>
#include <spawn.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/event.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

extern char **environ;

#define STATE_FILE_MENU "/tmp/uiviz_menu"
#define STATE_FILE_DOCK "/tmp/uiviz_dock"
#define DAEMON_LOCK_FILE "/tmp/uiviz.daemon.lock"
#define STATE_LOCK_FILE "/tmp/uiviz.state.lock"

/* -------------------------------------------------------------------------- */
/* SkyLight                                                                   */
/* -------------------------------------------------------------------------- */

typedef int (*SLSMainConnectionID_t)(void);
typedef void (*SLSSetMenuBarVisibilityOverrideOnDisplay_t)(int, int, bool);
typedef void (*SLSSetMenuBarInsetAndAlpha_t)(int, double, double, float);

typedef void (*SLSGetConnectionIDForPSN_t)(int, ProcessSerialNumber *, int *);

typedef void (*SLSConnectionGetPID_t)(int, pid_t *);
typedef void (*_SLPSGetFrontProcess_t)(ProcessSerialNumber *);

static void *skylight_handle;

static SLSMainConnectionID_t fn_conn;
static SLSSetMenuBarVisibilityOverrideOnDisplay_t fn_vis;
static SLSSetMenuBarInsetAndAlpha_t fn_inset;
static SLSGetConnectionIDForPSN_t fn_get_cid_for_psn;
static SLSConnectionGetPID_t fn_conn_get_pid;
static _SLPSGetFrontProcess_t fn_front_process;

static bool skylight_init(void) {
  if (skylight_handle)
    return true;

  skylight_handle =
      dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
             RTLD_LAZY);

  if (!skylight_handle) {
    fprintf(stderr, "SkyLight: %s\n", dlerror());
    return false;
  }

  fn_conn =
      (SLSMainConnectionID_t)dlsym(skylight_handle, "SLSMainConnectionID");

  fn_vis = (SLSSetMenuBarVisibilityOverrideOnDisplay_t)dlsym(
      skylight_handle, "SLSSetMenuBarVisibilityOverrideOnDisplay");

  fn_inset = (SLSSetMenuBarInsetAndAlpha_t)dlsym(skylight_handle,
                                                 "SLSSetMenuBarInsetAndAlpha");

  fn_get_cid_for_psn = (SLSGetConnectionIDForPSN_t)dlsym(
      skylight_handle, "SLSGetConnectionIDForPSN");

  fn_conn_get_pid =
      (SLSConnectionGetPID_t)dlsym(skylight_handle, "SLSConnectionGetPID");

  fn_front_process =
      (_SLPSGetFrontProcess_t)dlsym(skylight_handle, "_SLPSGetFrontProcess");

  if (!fn_conn || !fn_vis || !fn_inset) {
    fprintf(stderr, "Required SkyLight symbols are unavailable\n");
    return false;
  }

  /*
   * The PSN-related symbols are optional. They are needed only for
   * front-application menu access (-l and numeric -s).
   */

  return true;
}

/* -------------------------------------------------------------------------- */
/* State                                                                      */
/* -------------------------------------------------------------------------- */

typedef enum {
  ST_UNKNOWN = -1,
  ST_VISIBLE = 0,
  ST_HIDDEN = 1,
} UIState;

static UIState read_state(const char *path) {
  int fd = open(path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
  if (fd < 0)
    return ST_UNKNOWN;

  struct stat st;
  if (fstat(fd, &st) < 0 || !S_ISREG(st.st_mode) || st.st_uid != geteuid()) {
    close(fd);
    return ST_UNKNOWN;
  }

  FILE *f = fdopen(fd, "r");
  if (!f) {
    close(fd);
    return ST_UNKNOWN;
  }

  int value = -1;
  int result = fscanf(f, "%d", &value);
  fclose(f);

  if (result != 1)
    return ST_UNKNOWN;

  if (value == 0)
    return ST_VISIBLE;

  if (value == 1)
    return ST_HIDDEN;

  return ST_UNKNOWN;
}

static bool write_all(int fd, const void *buf, size_t len) {
  const char *p = buf;

  while (len > 0) {
    ssize_t written = write(fd, p, len);

    if (written < 0) {
      if (errno == EINTR)
        continue;

      return false;
    }

    p += written;
    len -= (size_t)written;
  }

  return true;
}

static bool write_state(const char *path, bool hidden) {
  char tmp[PATH_MAX];

  int n = snprintf(tmp, sizeof(tmp), "%s.tmp.XXXXXX", path);
  if (n < 0 || (size_t)n >= sizeof(tmp)) {
    errno = ENAMETOOLONG;
    return false;
  }

  int fd = mkstemp(tmp);
  if (fd < 0)
    return false;

  /*
   * mkstemp() already creates the file mode 0600, but make that
   * explicit in case platform behavior changes.
   */
  if (fchmod(fd, 0600) < 0) {
    int saved = errno;
    close(fd);
    unlink(tmp);
    errno = saved;
    return false;
  }

  const char *value = hidden ? "1\n" : "0\n";

  if (!write_all(fd, value, 2)) {
    int saved = errno;
    close(fd);
    unlink(tmp);
    errno = saved;
    return false;
  }

  if (close(fd) < 0) {
    int saved = errno;
    unlink(tmp);
    errno = saved;
    return false;
  }

  /*
   * rename() gives readers an atomic transition from the old state
   * file to the new one.
   */
  if (rename(tmp, path) < 0) {
    int saved = errno;
    unlink(tmp);
    errno = saved;
    return false;
  }

  return true;
}

/* -------------------------------------------------------------------------- */
/* Child processes                                                            */
/* -------------------------------------------------------------------------- */

static int run_status(char *const argv[]) {
  pid_t pid;

  int spawn_result = posix_spawn(&pid, argv[0], NULL, NULL, argv, environ);

  if (spawn_result != 0) {
    errno = spawn_result;
    return -1;
  }

  int status;

  for (;;) {
    pid_t result = waitpid(pid, &status, 0);

    if (result >= 0)
      break;

    if (errno == EINTR)
      continue;

    return -1;
  }

  if (WIFEXITED(status))
    return WEXITSTATUS(status);

  if (WIFSIGNALED(status))
    return 128 + WTERMSIG(status);

  return -1;
}

static void run(char *const argv[]) { (void)run_status(argv); }

/* -------------------------------------------------------------------------- */
/* Menu / Dock                                                                */
/* -------------------------------------------------------------------------- */

static void apply_menu(bool hide) {
  int cid = fn_conn();

  if (hide) {
    fn_vis(cid, 0, true);
    fn_inset(cid, -200.0, 1.0, 0.0f);
  } else {
    fn_vis(cid, 0, false);
    fn_inset(cid, 0.0, 1.0, 1.0f);
  }
}

static void wait_for_dock(void) {
  char *pgrep[] = {
      "/usr/bin/pgrep",
      "Dock",
      NULL,
  };

  for (int i = 0; i < 30; i++) {
    usleep(100000);

    if (run_status(pgrep) == 0)
      return;
  }
}

static void apply_dock(bool hide) {
  /*
   * This intentionally keeps Dock autohide enabled in both states.
   *
   * "hidden":
   *   autohide-delay = 1000
   *   animation       = 0
   *
   * "visible":
   *   autohide-delay = 0
   *   animation       = 0.1
   */

  char *autohide[] = {
      "/usr/bin/defaults",
      "write",
      "com.apple.dock",
      "autohide",
      "-bool",
      "true",
      NULL,
  };

  run(autohide);

  if (hide) {
    char *delay[] = {
        "/usr/bin/defaults",
        "write",
        "com.apple.dock",
        "autohide-delay",
        "-float",
        "1000",
        NULL,
    };

    char *speed[] = {
        "/usr/bin/defaults",
        "write",
        "com.apple.dock",
        "autohide-time-modifier",
        "-float",
        "0",
        NULL,
    };

    run(delay);
    run(speed);
  } else {
    char *delay[] = {
        "/usr/bin/defaults",
        "write",
        "com.apple.dock",
        "autohide-delay",
        "-float",
        "0",
        NULL,
    };

    char *speed[] = {
        "/usr/bin/defaults",
        "write",
        "com.apple.dock",
        "autohide-time-modifier",
        "-float",
        "0.1",
        NULL,
    };

    run(delay);
    run(speed);
  }

  char *kill[] = {
      "/usr/bin/killall",
      "Dock",
      NULL,
  };

  run(kill);
  wait_for_dock();
}

/* -------------------------------------------------------------------------- */
/* Locks                                                                      */
/* -------------------------------------------------------------------------- */

static int daemon_fd = -1;
static int state_fd = -1;

static int open_lock_file(const char *path) {
  int fd = open(path, O_CREAT | O_RDWR | O_CLOEXEC | O_NOFOLLOW, 0600);

  if (fd < 0)
    return -1;

  struct stat st;

  if (fstat(fd, &st) < 0 || !S_ISREG(st.st_mode) || st.st_uid != geteuid()) {
    int saved = errno ? errno : EPERM;
    close(fd);
    errno = saved;
    return -1;
  }

  /*
   * Tighten permissions if this was created by an older version
   * of the program using 0644.
   */
  if (fchmod(fd, 0600) < 0) {
    int saved = errno;
    close(fd);
    errno = saved;
    return -1;
  }

  return fd;
}

static bool singleton_lock(void) {
  daemon_fd = open_lock_file(DAEMON_LOCK_FILE);

  if (daemon_fd < 0) {
    perror("open daemon lock");
    return false;
  }

  for (;;) {
    if (flock(daemon_fd, LOCK_EX | LOCK_NB) == 0)
      return true;

    if (errno == EINTR)
      continue;

    if (errno == EWOULDBLOCK || errno == EAGAIN) {
      /*
       * Another daemon already owns the lock.
       */
      close(daemon_fd);
      daemon_fd = -1;
      return false;
    }

    perror("flock daemon");
    close(daemon_fd);
    daemon_fd = -1;
    return false;
  }
}

static bool state_lock(void) {
  if (state_fd >= 0) {
    errno = EDEADLK;
    return false;
  }

  state_fd = open_lock_file(STATE_LOCK_FILE);

  if (state_fd < 0)
    return false;

  for (;;) {
    if (flock(state_fd, LOCK_EX) == 0)
      return true;

    if (errno == EINTR)
      continue;

    int saved = errno;
    close(state_fd);
    state_fd = -1;
    errno = saved;
    return false;
  }
}

static void state_unlock(void) {
  if (state_fd < 0)
    return;

  while (flock(state_fd, LOCK_UN) < 0 && errno == EINTR)
    ;

  close(state_fd);
  state_fd = -1;
}

/* -------------------------------------------------------------------------- */
/* State file watcher                                                         */
/* -------------------------------------------------------------------------- */

struct Watch {
  int fd;
  const char *path;
};

static bool watch_register(int kq, struct Watch *watch) {
  if (watch->fd >= 0) {
    close(watch->fd);
    watch->fd = -1;
  }

  watch->fd = open(watch->path, O_EVTONLY | O_CLOEXEC | O_NOFOLLOW);

  if (watch->fd < 0)
    return false;

  struct kevent ev;

  EV_SET(&ev, watch->fd, EVFILT_VNODE, EV_ADD | EV_CLEAR,
         NOTE_WRITE | NOTE_DELETE | NOTE_RENAME, 0, watch);

  if (kevent(kq, &ev, 1, NULL, 0, NULL) < 0) {
    int saved = errno;
    close(watch->fd);
    watch->fd = -1;
    errno = saved;
    return false;
  }

  return true;
}

/* -------------------------------------------------------------------------- */
/* Daemonization                                                              */
/* -------------------------------------------------------------------------- */

static bool daemonize(void) {
  pid_t pid = fork();

  if (pid < 0) {
    perror("fork");
    return false;
  }

  if (pid > 0)
    _exit(0);

  if (setsid() < 0)
    return false;

  pid = fork();

  if (pid < 0)
    return false;

  if (pid > 0)
    _exit(0);

  if (chdir("/") < 0)
    return false;

  int fd = open("/dev/null", O_RDWR);

  if (fd >= 0) {
    if (dup2(fd, STDIN_FILENO) < 0 || dup2(fd, STDOUT_FILENO) < 0 ||
        dup2(fd, STDERR_FILENO) < 0) {
      if (fd > STDERR_FILENO)
        close(fd);

      return false;
    }

    if (fd > STDERR_FILENO)
      close(fd);
  }

  return true;
}

/* -------------------------------------------------------------------------- */
/* Daemon                                                                     */
/* -------------------------------------------------------------------------- */

static void daemon_cleanup(int kq, struct Watch *menu_watch,
                           struct Watch *dock_watch) {
  /*
   * Keep the state files consistent with what we leave on screen.
   */
  if (state_lock()) {
    (void)write_state(STATE_FILE_MENU, false);
    (void)write_state(STATE_FILE_DOCK, false);

    apply_menu(false);
    apply_dock(false);

    state_unlock();
  } else {
    /*
     * Best effort if the state lock itself cannot be acquired.
     */
    apply_menu(false);
    apply_dock(false);
  }

  if (menu_watch && menu_watch->fd >= 0)
    close(menu_watch->fd);

  if (dock_watch && dock_watch->fd >= 0)
    close(dock_watch->fd);

  if (kq >= 0)
    close(kq);

  if (daemon_fd >= 0) {
    (void)flock(daemon_fd, LOCK_UN);
    close(daemon_fd);
    daemon_fd = -1;
  }
}

static int run_daemon(void) {
  /*
   * Take the singleton lock before forking. flock() is retained
   * through fork because the children inherit the same open file
   * description.
   */
  if (!singleton_lock()) {
    /*
     * Treat an already-running daemon as success.
     */
    return daemon_fd < 0 ? 0 : 1;
  }

  if (!daemonize())
    return 1;

  /*
   * Initialize SkyLight in the final daemon rather than creating a
   * SkyLight connection and subsequently forking it.
   */
  if (!skylight_init())
    return 1;

  int kq = kqueue();

  if (kq < 0)
    return 1;

  struct kevent sigs[2];

  EV_SET(&sigs[0], SIGTERM, EVFILT_SIGNAL, EV_ADD, 0, 0, NULL);

  EV_SET(&sigs[1], SIGINT, EVFILT_SIGNAL, EV_ADD, 0, 0, NULL);

  if (kevent(kq, sigs, 2, NULL, 0, NULL) < 0) {
    close(kq);
    return 1;
  }

  signal(SIGTERM, SIG_IGN);
  signal(SIGINT, SIG_IGN);

  struct kevent timer;

  EV_SET(&timer, 1, EVFILT_TIMER, EV_ADD | EV_ENABLE, 0, 1000, NULL);

  if (kevent(kq, &timer, 1, NULL, 0, NULL) < 0) {
    close(kq);
    return 1;
  }

  struct Watch menu_watch = {
      .fd = -1,
      .path = STATE_FILE_MENU,
  };

  struct Watch dock_watch = {
      .fd = -1,
      .path = STATE_FILE_DOCK,
  };

  bool menu_hidden = true;
  bool dock_hidden = true;

  /*
   * Preserve the original startup semantics: starting the daemon
   * begins with both the menu bar and Dock hidden.
   *
   * Hold the shared state lock while creating the initial files,
   * installing vnode watches, and applying the initial state. This
   * prevents a CLI toggle from slipping into the gap between those
   * operations.
   */
  if (!state_lock()) {
    close(kq);
    return 1;
  }

  bool state_ok =
      write_state(STATE_FILE_MENU, true) && write_state(STATE_FILE_DOCK, true);

  bool watches_ok = false;

  if (state_ok) {
    watches_ok =
        watch_register(kq, &menu_watch) && watch_register(kq, &dock_watch);
  }

  if (state_ok && watches_ok) {
    apply_menu(true);
    apply_dock(true);
  }

  state_unlock();

  if (!state_ok || !watches_ok) {
    daemon_cleanup(kq, &menu_watch, &dock_watch);
    return 1;
  }

  bool running = true;

  while (running) {
    struct kevent ev;

    int count = kevent(kq, NULL, 0, &ev, 1, NULL);

    if (count < 0) {
      if (errno == EINTR)
        continue;

      break;
    }

    if (count == 0)
      continue;

    if (ev.filter == EVFILT_SIGNAL) {
      running = false;
      continue;
    }

    if (ev.filter == EVFILT_TIMER) {
      /*
       * Serialize this periodic re-hide with -s and toggle
       * operations. Also reread the state while locked so a timer
       * cannot act on a stale menu_hidden value after a CLI toggle.
       */
      if (!state_lock())
        continue;

      UIState state = read_state(STATE_FILE_MENU);

      if (state != ST_UNKNOWN)
        menu_hidden = state == ST_HIDDEN;

      if (menu_hidden)
        apply_menu(true);

      state_unlock();
      continue;
    }

    if (ev.filter != EVFILT_VNODE)
      continue;

    struct Watch *watch = ev.udata;

    if (!watch)
      continue;

    /*
     * A CLI state update uses atomic rename(). Re-establish the
     * vnode watch on the new inode while the shared state lock is
     * held.
     */
    if (!state_lock())
      continue;

    if (ev.fflags & (NOTE_DELETE | NOTE_RENAME))
      (void)watch_register(kq, watch);

    UIState menu_state = read_state(STATE_FILE_MENU);
    UIState dock_state = read_state(STATE_FILE_DOCK);

    if (menu_state != ST_UNKNOWN) {
      bool new_hidden = menu_state == ST_HIDDEN;

      if (new_hidden != menu_hidden) {
        menu_hidden = new_hidden;
        apply_menu(menu_hidden);
      }
    }

    if (dock_state != ST_UNKNOWN) {
      bool new_hidden = dock_state == ST_HIDDEN;

      if (new_hidden != dock_hidden) {
        dock_hidden = new_hidden;
        apply_dock(dock_hidden);
      }
    }

    state_unlock();
  }

  daemon_cleanup(kq, &menu_watch, &dock_watch);
  return 0;
}

/* -------------------------------------------------------------------------- */
/* CLI state toggles                                                          */
/* -------------------------------------------------------------------------- */

static bool toggle_one(const char *path) {
  if (!state_lock()) {
    perror("state lock");
    return false;
  }

  UIState state = read_state(path);

  /*
   * Unknown state behaves like visible, so the first toggle hides.
   */
  bool new_hidden = state != ST_HIDDEN;

  bool ok = write_state(path, new_hidden);

  int saved = errno;
  state_unlock();
  errno = saved;

  if (!ok)
    perror("write state");

  return ok;
}

static bool toggle_both(void) {
  if (!state_lock()) {
    perror("state lock");
    return false;
  }

  UIState menu_state = read_state(STATE_FILE_MENU);
  UIState dock_state = read_state(STATE_FILE_DOCK);

  bool menu_hidden = menu_state != ST_HIDDEN;
  bool dock_hidden = dock_state != ST_HIDDEN;

  /*
   * Both files are updated under one shared lock, preventing the
   * daemon from observing the intermediate state.
   */
  bool menu_ok = write_state(STATE_FILE_MENU, menu_hidden);

  bool dock_ok = write_state(STATE_FILE_DOCK, dock_hidden);

  int saved = errno;
  state_unlock();
  errno = saved;

  if (!menu_ok || !dock_ok) {
    perror("write state");
    return false;
  }

  return true;
}

/* -------------------------------------------------------------------------- */
/* Accessibility                                                              */
/* -------------------------------------------------------------------------- */

static bool ax_init(void) {
  const void *keys[] = {
      kAXTrustedCheckOptionPrompt,
  };

  const void *values[] = {
      kCFBooleanTrue,
  };

  CFDictionaryRef opts = CFDictionaryCreate(
      kCFAllocatorDefault, keys, values, 1,
      &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

  if (!opts)
    return false;

  bool trusted = AXIsProcessTrustedWithOptions(opts);

  CFRelease(opts);

  if (!trusted) {
    fprintf(stderr, "Accessibility permission required\n");
    return false;
  }

  return true;
}

static bool ax_perform_click(AXUIElementRef element) {
  if (!element)
    return false;

  /*
   * Preserve the original cancellation step. Some status extras
   * otherwise leave an existing menu/popup in a state that ignores
   * the subsequent press.
   */
  (void)AXUIElementPerformAction(element, kAXCancelAction);

  usleep(150000);

  return AXUIElementPerformAction(element, kAXPressAction) == kAXErrorSuccess;
}

static CFStringRef ax_get_title(AXUIElementRef element) {
  CFTypeRef value = NULL;

  if (AXUIElementCopyAttributeValue(element, kAXTitleAttribute, &value) !=
      kAXErrorSuccess) {
    return NULL;
  }

  if (!value)
    return NULL;

  if (CFGetTypeID(value) != CFStringGetTypeID()) {
    CFRelease(value);
    return NULL;
  }

  return (CFStringRef)value;
}

static char *cfstring_copy_utf8(CFStringRef string) {
  if (!string)
    return NULL;

  CFIndex length = CFStringGetLength(string);

  CFIndex max =
      CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8);

  if (max < 0)
    return NULL;

  if (max >= LONG_MAX)
    return NULL;

  max += 1;

  char *buf = malloc((size_t)max);

  if (!buf)
    return NULL;

  if (!CFStringGetCString(string, buf, max, kCFStringEncodingUTF8)) {
    free(buf);
    return NULL;
  }

  return buf;
}

/*
 * Return the front application through the same SkyLight PSN lookup
 * used by the original implementation.
 *
 * Caller owns the returned AXUIElementRef.
 */
static AXUIElementRef ax_get_front_app(void) {
  if (!fn_front_process || !fn_get_cid_for_psn || !fn_conn_get_pid) {
    fprintf(stderr, "SkyLight PSN symbols unavailable\n");
    return NULL;
  }

  ProcessSerialNumber psn = {0, 0};

  fn_front_process(&psn);

  int target_cid = 0;
  fn_get_cid_for_psn(fn_conn(), &psn, &target_cid);

  if (target_cid <= 0) {
    fprintf(stderr, "Could not determine front application connection\n");
    return NULL;
  }

  pid_t pid = 0;
  fn_conn_get_pid(target_cid, &pid);

  if (pid <= 0) {
    fprintf(stderr, "Could not determine front application PID\n");
    return NULL;
  }

  return AXUIElementCreateApplication(pid);
}

/* -------------------------------------------------------------------------- */
/* Front application menu                                                     */
/* -------------------------------------------------------------------------- */

static bool ax_print_menu_options(AXUIElementRef app) {
  AXUIElementRef menubar = NULL;
  CFArrayRef children = NULL;

  if (AXUIElementCopyAttributeValue(app, kAXMenuBarAttribute,
                                    (CFTypeRef *)&menubar) != kAXErrorSuccess) {
    return false;
  }

  bool ok = false;

  if (AXUIElementCopyAttributeValue(menubar, kAXVisibleChildrenAttribute,
                                    (CFTypeRef *)&children) ==
      kAXErrorSuccess) {
    CFIndex count = CFArrayGetCount(children);

    /*
     * Preserve the original behavior of skipping index 0, normally
     * the Apple menu.
     */
    for (CFIndex i = 1; i < count; i++) {
      AXUIElementRef item = (AXUIElementRef)CFArrayGetValueAtIndex(children, i);

      CFStringRef title = ax_get_title(item);

      if (!title)
        continue;

      char *text = cfstring_copy_utf8(title);

      if (text) {
        printf("%lld: %s\n", (long long)i, text);

        free(text);
      }

      CFRelease(title);
    }

    ok = true;
    CFRelease(children);
  }

  CFRelease(menubar);
  return ok;
}

static bool ax_select_menu_option(AXUIElementRef app, int id) {
  AXUIElementRef menubar = NULL;
  CFArrayRef children = NULL;

  if (id < 0)
    return false;

  if (AXUIElementCopyAttributeValue(app, kAXMenuBarAttribute,
                                    (CFTypeRef *)&menubar) != kAXErrorSuccess) {
    return false;
  }

  bool ok = false;

  if (AXUIElementCopyAttributeValue(menubar, kAXVisibleChildrenAttribute,
                                    (CFTypeRef *)&children) ==
      kAXErrorSuccess) {
    CFIndex count = CFArrayGetCount(children);

    if ((CFIndex)id < count) {
      AXUIElementRef item =
          (AXUIElementRef)CFArrayGetValueAtIndex(children, (CFIndex)id);

      ok = ax_perform_click(item);
    } else {
      fprintf(stderr, "Menu item index out of range: %d\n", id);
    }

    CFRelease(children);
  }

  CFRelease(menubar);
  return ok;
}

/* -------------------------------------------------------------------------- */
/* Status-bar extras                                                          */
/* -------------------------------------------------------------------------- */

static bool window_alias_matches(CFStringRef owner_ref, CFStringRef name_ref,
                                 const char *alias) {
  if (!owner_ref || !name_ref || !alias)
    return false;

  if (CFGetTypeID(owner_ref) != CFStringGetTypeID() ||
      CFGetTypeID(name_ref) != CFStringGetTypeID()) {
    return false;
  }

  char *owner = cfstring_copy_utf8(owner_ref);

  char *name = cfstring_copy_utf8(name_ref);

  if (!owner || !name) {
    free(owner);
    free(name);
    return false;
  }

  size_t owner_len = strlen(owner);
  size_t name_len = strlen(name);

  if (owner_len > SIZE_MAX - name_len - 2) {
    free(owner);
    free(name);
    return false;
  }

  size_t combined_len = owner_len + name_len + 2;

  char *combined = malloc(combined_len);

  if (!combined) {
    free(owner);
    free(name);
    return false;
  }

  snprintf(combined, combined_len, "%s,%s", owner, name);

  bool matches = strcmp(combined, alias) == 0;

  free(combined);
  free(owner);
  free(name);

  return matches;
}

/*
 * Find a status-bar extra by its "OwnerName,WindowName" alias using
 * CGWindowList, then locate the corresponding AX element.
 */
static bool ax_select_menu_extra(const char *alias) {
  pid_t pid = 0;
  CGRect bounds = CGRectNull;

  CFArrayRef window_list =
      CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID);

  if (!window_list) {
    fprintf(stderr, "Could not read window list\n");
    return false;
  }

  CFIndex count = CFArrayGetCount(window_list);

  for (CFIndex i = 0; i < count; i++) {
    CFDictionaryRef info = CFArrayGetValueAtIndex(window_list, i);

    if (!info)
      continue;

    CFStringRef owner_ref = CFDictionaryGetValue(info, kCGWindowOwnerName);

    CFStringRef name_ref = CFDictionaryGetValue(info, kCGWindowName);

    CFNumberRef pid_ref = CFDictionaryGetValue(info, kCGWindowOwnerPID);

    CFNumberRef layer_ref = CFDictionaryGetValue(info, kCGWindowLayer);

    CFDictionaryRef bounds_ref = CFDictionaryGetValue(info, kCGWindowBounds);

    if (!owner_ref || !name_ref || !pid_ref || !layer_ref || !bounds_ref) {
      continue;
    }

    if (CFGetTypeID(pid_ref) != CFNumberGetTypeID() ||
        CFGetTypeID(layer_ref) != CFNumberGetTypeID()) {
      continue;
    }

    int64_t layer = 0;

    if (!CFNumberGetValue(layer_ref, kCFNumberSInt64Type, &layer)) {
      continue;
    }

    /*
     * Preserve the original menu-extra window layer test.
     */
    if (layer != 0x19)
      continue;

    CGRect rect = CGRectNull;

    if (!CGRectMakeWithDictionaryRepresentation(bounds_ref, &rect)) {
      continue;
    }

    if (!window_alias_matches(owner_ref, name_ref, alias)) {
      continue;
    }

    int64_t raw_pid = 0;

    if (!CFNumberGetValue(pid_ref, kCFNumberSInt64Type, &raw_pid)) {
      continue;
    }

    if (raw_pid <= 0 || raw_pid > INT_MAX) {
      continue;
    }

    pid = (pid_t)raw_pid;
    bounds = rect;
    break;
  }

  CFRelease(window_list);

  if (pid <= 0) {
    fprintf(stderr, "Menu extra not found: %s\n", alias);

    return false;
  }

  AXUIElementRef app = AXUIElementCreateApplication(pid);

  if (!app)
    return false;

  CFTypeRef extras = NULL;
  CFArrayRef children = NULL;

  AXUIElementRef result = NULL;
  double best_delta = INFINITY;

  if (AXUIElementCopyAttributeValue(app, kAXExtrasMenuBarAttribute, &extras) ==
          kAXErrorSuccess &&
      extras) {
    if (AXUIElementCopyAttributeValue(
            (AXUIElementRef)extras, kAXVisibleChildrenAttribute,
            (CFTypeRef *)&children) == kAXErrorSuccess &&
        children) {
      CFIndex child_count = CFArrayGetCount(children);

      /*
       * The CGWindow and AX APIs expose different objects, so map
       * them by horizontal position.
       *
       * Instead of accepting the first item within 10 points, choose
       * the closest candidate. This avoids arbitrary selection when
       * tightly packed menu extras happen to overlap that tolerance.
       */
      for (CFIndex i = 0; i < child_count; i++) {
        AXUIElementRef item =
            (AXUIElementRef)CFArrayGetValueAtIndex(children, i);

        CFTypeRef position_ref = NULL;

        if (AXUIElementCopyAttributeValue(item, kAXPositionAttribute,
                                          &position_ref) != kAXErrorSuccess ||
            !position_ref) {
          continue;
        }

        CGPoint position = CGPointZero;
        bool position_ok = false;

        if (CFGetTypeID(position_ref) == AXValueGetTypeID()) {
          position_ok = AXValueGetValue((AXValueRef)position_ref,
                                        kAXValueCGPointType, &position);
        }

        CFRelease(position_ref);

        if (!position_ok)
          continue;

        double delta = fabs(position.x - bounds.origin.x);

        if (delta < best_delta) {
          if (result)
            CFRelease(result);

          result = item;
          CFRetain(result);
          best_delta = delta;
        }
      }

      CFRelease(children);
    }

    CFRelease(extras);
  }

  CFRelease(app);

  /*
   * Retain the original ±10 point tolerance.
   */
  if (!result || best_delta > 10.0) {
    if (result)
      CFRelease(result);

    fprintf(stderr, "Could not locate matching AX menu extra\n");

    return false;
  }

  /*
   * Serialize the temporary menu-bar reveal with:
   *
   *   - state toggles
   *   - daemon vnode updates
   *   - daemon's one-second menu re-hide timer
   *
   * This removes the race where the daemon could hide the bar
   * halfway through the AX click.
   */
  if (!state_lock()) {
    perror("state lock");
    CFRelease(result);
    return false;
  }

  UIState menu_state = read_state(STATE_FILE_MENU);

  /*
   * If the state is unavailable, prefer leaving the menu visible
   * rather than unexpectedly hiding a user's normal menu bar.
   */
  bool restore_hidden = menu_state == ST_HIDDEN;

  apply_menu(false);
  usleep(50000);

  bool clicked = ax_perform_click(result);

  /*
   * Restore the requested state rather than unconditionally hiding
   * the menu bar.
   */
  apply_menu(restore_hidden);

  state_unlock();
  CFRelease(result);

  return clicked;
}

/* -------------------------------------------------------------------------- */
/* Argument parsing                                                           */
/* -------------------------------------------------------------------------- */

static bool parse_menu_index(const char *value, int *out) {
  if (!value || !*value || !out)
    return false;

  errno = 0;

  char *end = NULL;

  long parsed = strtol(value, &end, 10);

  /*
   * The entire argument must be numeric.
   *
   * This is important for aliases such as:
   *
   *   1Password,...
   *
   * sscanf("%d") would incorrectly interpret that as menu item 1.
   */
  if (errno != 0 || end == value || *end != '\0' || parsed < 0 ||
      parsed > INT_MAX) {
    return false;
  }

  *out = (int)parsed;
  return true;
}

static void usage(const char *name) {
  fprintf(stderr,
          "Usage:\n"
          "  %s -d        run daemon\n"
          "  %s -tm       toggle menu bar\n"
          "  %s -td       toggle dock\n"
          "  %s -t        toggle both\n"
          "  %s -l        list front app's menu bar items\n"
          "  %s -s <id>   click front app menu bar item by index\n"
          "  %s -s <str>  click status bar extra by 'Owner,Name' alias\n",
          name, name, name, name, name, name, name);
}

/* -------------------------------------------------------------------------- */
/* Main                                                                       */
/* -------------------------------------------------------------------------- */

int main(int argc, char **argv) {
  if (argc < 2) {
    usage(argv[0]);
    return 1;
  }

  if (strcmp(argv[1], "-d") == 0) {
    if (argc != 2) {
      usage(argv[0]);
      return 1;
    }

    return run_daemon();
  }

  if (strcmp(argv[1], "-tm") == 0) {
    if (argc != 2) {
      usage(argv[0]);
      return 1;
    }

    return toggle_one(STATE_FILE_MENU) ? 0 : 1;
  }

  if (strcmp(argv[1], "-td") == 0) {
    if (argc != 2) {
      usage(argv[0]);
      return 1;
    }

    return toggle_one(STATE_FILE_DOCK) ? 0 : 1;
  }

  if (strcmp(argv[1], "-t") == 0) {
    if (argc != 2) {
      usage(argv[0]);
      return 1;
    }

    return toggle_both() ? 0 : 1;
  }

  if (strcmp(argv[1], "-l") == 0) {
    if (argc != 2) {
      usage(argv[0]);
      return 1;
    }

    if (!skylight_init() || !ax_init()) {
      return 1;
    }

    AXUIElementRef app = ax_get_front_app();

    if (!app)
      return 1;

    bool ok = ax_print_menu_options(app);

    CFRelease(app);

    return ok ? 0 : 1;
  }

  if (strcmp(argv[1], "-s") == 0) {
    if (argc != 3) {
      usage(argv[0]);
      return 1;
    }

    if (!skylight_init() || !ax_init()) {
      return 1;
    }

    int id;

    if (parse_menu_index(argv[2], &id)) {
      AXUIElementRef app = ax_get_front_app();

      if (!app)
        return 1;

      bool ok = ax_select_menu_option(app, id);

      CFRelease(app);

      return ok ? 0 : 1;
    }

    return ax_select_menu_extra(argv[2]) ? 0 : 1;
  }

  fprintf(stderr, "Unknown option: %s\n", argv[1]);

  usage(argv[0]);
  return 1;
}
