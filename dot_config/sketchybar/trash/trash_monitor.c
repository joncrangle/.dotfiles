#include <CoreServices/CoreServices.h>
#include <dirent.h>
#include <dispatch/dispatch.h>
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// --- Global State ---
static bool g_is_foreground = false;
static FSEventStreamRef g_stream =
    NULL; // Global reference to the stream for cleanup
static int g_last_trash_count = -1; // Stores the last known count

// --- Conditional Logging ---
void log_to_terminal(const char *format, ...) {
  if (!g_is_foreground)
    return;
  va_list args;
  va_start(args, format);
  vprintf(format, args);
  va_end(args);
  fflush(stdout);
}

int get_trash_count() {
  int count = 0;
  const char *home_path = getenv("HOME");
  if (!home_path)
    return 0;

  char trash_path[1024];
  snprintf(trash_path, sizeof(trash_path), "%s/.Trash", home_path);

  DIR *dir = opendir(trash_path);
  if (dir == NULL)
    return 0;

  struct dirent *entry;
  while ((entry = readdir(dir)) != NULL) {
    if (strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0 &&
        strcmp(entry->d_name, ".DS_Store") != 0) {
      count++;
    }
  }
  closedir(dir);
  return count;
}

void update_sketchybar_trash() {
  int count = get_trash_count();

  // Only update if the count has changed
  if (count == g_last_trash_count) {
    log_to_terminal("Trash count unchanged (%d), skipping update.\n", count);
    return;
  }

  g_last_trash_count = count; // Update the last known count

  char command[512];
  const char *sketchybar_path = "/opt/homebrew/bin/sketchybar";
  snprintf(command, sizeof(command),
           "'%s' --trigger trash_change TRASH_COUNT=%d", sketchybar_path,
           count);

  log_to_terminal("Executing command: %s\n", command);
  int result = system(command);

  if (result != 0) {
    log_to_terminal("Command may have failed with exit code %d\n", result);
  } else {
    log_to_terminal("Command executed.\n");
  }
}

void fsevents_callback(ConstFSEventStreamRef streamRef,
                       void *clientCallBackInfo, size_t numEvents,
                       void *eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[]) {
  (void)streamRef;
  (void)clientCallBackInfo;
  (void)numEvents;
  (void)eventPaths;
  (void)eventFlags;
  (void)eventIds;
  log_to_terminal(
      "FSEvents callback triggered. Checking for trash changes...\n");
  update_sketchybar_trash();
}

void signal_handler(int signum) {
  log_to_terminal("\nSignal %d received, shutting down...\n", signum);
  if (g_stream) {
    FSEventStreamStop(g_stream);
    FSEventStreamInvalidate(g_stream);
    FSEventStreamRelease(g_stream);
  }
  exit(0);
}

int main(int argc, char **argv) {
  // If called with '--count', it prints the number of items and exits.
  if (argc > 1 && strcmp(argv[1], "--count") == 0) {
    printf("%d", get_trash_count());
    return 0;
  }

  g_is_foreground = isatty(STDOUT_FILENO);

  signal(SIGINT, signal_handler);  // Catch CTRL+C
  signal(SIGTERM, signal_handler); // Catch kill command

  log_to_terminal("Trash monitor starting up...\n");

  const char *home_path = getenv("HOME");
  if (!home_path) {
    log_to_terminal("FATAL: HOME environment variable not set.\n");
    return 1;
  }

  char trash_path[1024];
  snprintf(trash_path, sizeof(trash_path), "%s/.Trash", home_path);

  CFStringRef path_to_watch = CFStringCreateWithCString(
      kCFAllocatorDefault, trash_path, kCFStringEncodingUTF8);
  if (!path_to_watch) {
    log_to_terminal("FATAL: Could not create CFString for path.\n");
    return 1;
  }

  CFArrayRef pathsToWatch = CFArrayCreate(NULL, (const void **)&path_to_watch,
                                          1, &kCFTypeArrayCallBacks);
  CFRelease(path_to_watch);

  if (!pathsToWatch) {
    log_to_terminal("FATAL: Could not create CFArray for paths.\n");
    return 1;
  }

  FSEventStreamContext context = {0, NULL, NULL, NULL, NULL};
  g_stream = FSEventStreamCreate( // Assign to global stream
      kCFAllocatorDefault, fsevents_callback, &context, pathsToWatch,
      kFSEventStreamEventIdSinceNow, 1.0, kFSEventStreamCreateFlagFileEvents);

  CFRelease(pathsToWatch);

  if (!g_stream) {
    log_to_terminal("FATAL: Failed to create FSEventStream.\n");
    return 1;
  }

  FSEventStreamSetDispatchQueue(g_stream, dispatch_get_main_queue());
  if (!FSEventStreamStart(g_stream)) {
    log_to_terminal("FATAL: Failed to start FSEventStream.\n");
    FSEventStreamInvalidate(g_stream);
    FSEventStreamRelease(g_stream);
    return 1;
  }

  log_to_terminal("Monitoring trash directory: %s\n", trash_path);

  update_sketchybar_trash();
  dispatch_main();

  // Unreachable
  return 0;
}
