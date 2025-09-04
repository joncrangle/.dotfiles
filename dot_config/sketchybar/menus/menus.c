#include <Carbon/Carbon.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdbool.h>
#include <sys/stat.h>
#include <unistd.h>

// Constants
#define STATE_FILE "/tmp/menubar_opacity_state"
#define LOCK_FILE "/tmp/menubar_opacity.lock"
#define MENU_BAR_LAYER 0x19
#define MAX_BUFFER_SIZE 1024
#define SHORT_DELAY_US 50000
#define MEDIUM_DELAY_US 100000
#define LONG_DELAY_US 1000000

// Global state
static float g_menu_opacity = 1.0f;
static volatile sig_atomic_t g_should_exit = 0;

extern int SLSMainConnectionID();
extern void SLSSetMenuBarVisibilityOverrideOnDisplay(int cid, int did,
                                                     bool enabled);
extern void SLSSetMenuBarInsetAndAlpha(int cid, double u1, double u2,
                                       float alpha);
extern void _SLPSGetFrontProcess(ProcessSerialNumber *psn);
extern void SLSGetConnectionIDForPSN(int cid, ProcessSerialNumber *psn,
                                     int *cid_out);
extern void SLSConnectionGetPID(int cid, pid_t *pid_out);

// Safe signal handler
void cleanup_and_exit(int sig) {
  g_should_exit = 1;
  int cid = SLSMainConnectionID();
  SLSSetMenuBarVisibilityOverrideOnDisplay(cid, 0, false);
  SLSSetMenuBarInsetAndAlpha(cid, 0, 1, 1.0);
  // Remove lock file if it exists
  unlink(LOCK_FILE);
  _exit(0); // async-signal-safe exit
}

// File locking for race condition prevention
int acquire_lock() {
  int fd = open(LOCK_FILE, O_CREAT | O_EXCL | O_WRONLY, 0644);
  if (fd == -1) {
    if (errno == EEXIST) {
      // Check if the process holding the lock is still alive
      FILE *lock_file = fopen(LOCK_FILE, "r");
      if (lock_file) {
        pid_t lock_pid;
        if (fscanf(lock_file, "%d", &lock_pid) == 1) {
          fclose(lock_file);
          if (kill(lock_pid, 0) == -1 && errno == ESRCH) {
            // Process is dead, remove stale lock
            unlink(LOCK_FILE);
            return acquire_lock(); // Retry
          }
        } else {
          fclose(lock_file);
        }
      }
      return -1; // Lock held by active process
    }
    return -1;
  }

  // Write our PID to the lock file
  FILE *lock_file = fdopen(fd, "w");
  if (lock_file) {
    fprintf(lock_file, "%d\n", getpid());
    fclose(lock_file);
  } else {
    close(fd);
  }

  return fd;
}

void release_lock() { unlink(LOCK_FILE); }

void ax_init() {
  const void *keys[] = {kAXTrustedCheckOptionPrompt};
  const void *values[] = {kCFBooleanTrue};

  CFDictionaryRef options = CFDictionaryCreate(
      kCFAllocatorDefault, keys, values, 1,
      &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

  bool trusted = AXIsProcessTrustedWithOptions(options);
  CFRelease(options);
  if (!trusted) {
    fprintf(stderr, "Accessibility permissions required\n");
    exit(1);
  }
}

void ax_perform_click(AXUIElementRef element) {
  if (!element)
    return;

  // Temporarily show menu bar when using menu
  int cid = SLSMainConnectionID();
  SLSSetMenuBarVisibilityOverrideOnDisplay(cid, 0, false);
  SLSSetMenuBarInsetAndAlpha(cid, 0, 1, 1.0);

  AXError error = AXUIElementPerformAction(element, kAXCancelAction);
  if (error != kAXErrorSuccess) {
    fprintf(stderr, "Warning: Cancel action failed\n");
  }

  usleep(150000);

  error = AXUIElementPerformAction(element, kAXPressAction);
  if (error != kAXErrorSuccess) {
    fprintf(stderr, "Warning: Press action failed\n");
  }

  usleep(LONG_DELAY_US); // 1 second

  if (g_menu_opacity == 0.0f) {
    for (int i = 0; i < 3; i++) {
      SLSSetMenuBarInsetAndAlpha(cid, 0, 1, 0.0);
      SLSSetMenuBarVisibilityOverrideOnDisplay(cid, 0, true);
      SLSSetMenuBarInsetAndAlpha(cid, 0, 1, 0.0);
      usleep(MEDIUM_DELAY_US);
    }
  } else {
    SLSSetMenuBarInsetAndAlpha(cid, 0, 1, g_menu_opacity);
  }
}

CFStringRef ax_get_title(AXUIElementRef element) {
  CFTypeRef title = NULL;
  AXError error =
      AXUIElementCopyAttributeValue(element, kAXTitleAttribute, &title);

  if (error != kAXErrorSuccess)
    return NULL;
  return (CFStringRef)title;
}

void ax_select_menu_option(AXUIElementRef app, int id) {
  AXUIElementRef menubars_ref = NULL;
  CFArrayRef children_ref = NULL;

  AXError error = AXUIElementCopyAttributeValue(app, kAXMenuBarAttribute,
                                                (CFTypeRef *)&menubars_ref);
  if (error != kAXErrorSuccess) {
    fprintf(stderr, "Failed to get menu bar\n");
    return;
  }

  error = AXUIElementCopyAttributeValue(
      menubars_ref, kAXVisibleChildrenAttribute, (CFTypeRef *)&children_ref);

  if (error == kAXErrorSuccess) {
    uint32_t count = CFArrayGetCount(children_ref);
    if (id < count) {
      AXUIElementRef item = CFArrayGetValueAtIndex(children_ref, id);
      ax_perform_click(item);
    } else {
      fprintf(stderr, "Menu item %d not found (max: %d)\n", id, count - 1);
    }
    CFRelease(children_ref);
  } else {
    fprintf(stderr, "Failed to get menu children\n");
  }

  CFRelease(menubars_ref);
}

void ax_print_menu_options(AXUIElementRef app) {
  AXUIElementRef menubars_ref = NULL;
  CFArrayRef children_ref = NULL;

  AXError error = AXUIElementCopyAttributeValue(app, kAXMenuBarAttribute,
                                                (CFTypeRef *)&menubars_ref);
  if (error != kAXErrorSuccess) {
    fprintf(stderr, "Failed to get menu bar\n");
    return;
  }

  error = AXUIElementCopyAttributeValue(
      menubars_ref, kAXVisibleChildrenAttribute, (CFTypeRef *)&children_ref);

  if (error == kAXErrorSuccess) {
    uint32_t count = CFArrayGetCount(children_ref);

    for (int i = 1; i < count; i++) {
      AXUIElementRef item = CFArrayGetValueAtIndex(children_ref, i);
      CFStringRef title = ax_get_title(item);

      if (title) {
        char buffer[MAX_BUFFER_SIZE];
        if (CFStringGetCString(title, buffer, sizeof(buffer),
                               kCFStringEncodingUTF8)) {
          printf("%s\n", buffer);
        }
        CFRelease(title); // Fix memory leak
      }
    }
    CFRelease(children_ref);
  } else {
    fprintf(stderr, "Failed to get menu children\n");
  }

  CFRelease(menubars_ref);
}

AXUIElementRef ax_get_extra_menu_item(char *alias) {
  pid_t pid = 0;
  CGRect bounds = CGRectNull;
  CFArrayRef window_list =
      CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID);

  if (!window_list) {
    fprintf(stderr, "Failed to get window list\n");
    return NULL;
  }

  int window_count = CFArrayGetCount(window_list);
  for (int i = 0; i < window_count; ++i) {
    CFDictionaryRef dictionary = CFArrayGetValueAtIndex(window_list, i);
    if (!dictionary)
      continue;

    CFStringRef owner_ref =
        CFDictionaryGetValue(dictionary, kCGWindowOwnerName);
    CFNumberRef owner_pid_ref =
        CFDictionaryGetValue(dictionary, kCGWindowOwnerPID);
    CFStringRef name_ref = CFDictionaryGetValue(dictionary, kCGWindowName);
    CFNumberRef layer_ref = CFDictionaryGetValue(dictionary, kCGWindowLayer);
    CFDictionaryRef bounds_ref =
        CFDictionaryGetValue(dictionary, kCGWindowBounds);

    if (!name_ref || !owner_ref || !owner_pid_ref || !layer_ref || !bounds_ref)
      continue;

    long long int layer = 0;
    CFNumberGetValue(layer_ref, CFNumberGetType(layer_ref), &layer);
    uint64_t owner_pid = 0;
    CFNumberGetValue(owner_pid_ref, CFNumberGetType(owner_pid_ref), &owner_pid);

    if (layer != MENU_BAR_LAYER)
      continue;
    if (!CGRectMakeWithDictionaryRepresentation(bounds_ref, &bounds))
      continue;

    char owner_buffer[MAX_BUFFER_SIZE / 2], name_buffer[MAX_BUFFER_SIZE / 2],
        buffer[MAX_BUFFER_SIZE];
    if (!CFStringGetCString(owner_ref, owner_buffer, sizeof(owner_buffer),
                            kCFStringEncodingUTF8) ||
        !CFStringGetCString(name_ref, name_buffer, sizeof(name_buffer),
                            kCFStringEncodingUTF8)) {
      continue;
    }

    snprintf(buffer, sizeof(buffer), "%s,%s", owner_buffer, name_buffer);

    if (strcmp(buffer, alias) == 0) {
      pid = owner_pid;
      break;
    }
  }
  CFRelease(window_list);

  if (!pid)
    return NULL;

  AXUIElementRef app = AXUIElementCreateApplication(pid);
  if (!app)
    return NULL;

  AXUIElementRef result = NULL;
  CFTypeRef extras = NULL;
  CFArrayRef children_ref = NULL;
  AXError error =
      AXUIElementCopyAttributeValue(app, kAXExtrasMenuBarAttribute, &extras);
  if (error == kAXErrorSuccess && extras) {
    error = AXUIElementCopyAttributeValue(extras, kAXVisibleChildrenAttribute,
                                          (CFTypeRef *)&children_ref);

    if (error == kAXErrorSuccess && children_ref) {
      uint32_t count = CFArrayGetCount(children_ref);
      for (uint32_t i = 0; i < count; i++) {
        AXUIElementRef item = CFArrayGetValueAtIndex(children_ref, i);
        CFTypeRef position_ref = NULL;
        CFTypeRef size_ref = NULL;

        AXError pos_error = AXUIElementCopyAttributeValue(
            item, kAXPositionAttribute, &position_ref);
        AXError size_error =
            AXUIElementCopyAttributeValue(item, kAXSizeAttribute, &size_ref);

        if (pos_error != kAXErrorSuccess || size_error != kAXErrorSuccess) {
          if (position_ref)
            CFRelease(position_ref);
          if (size_ref)
            CFRelease(size_ref);
          continue;
        }

        CGPoint position = CGPointZero;
        CGSize size = CGSizeZero;
        AXValueGetValue((AXValueRef)position_ref, kAXValueCGPointType,
                        &position);
        AXValueGetValue((AXValueRef)size_ref, kAXValueCGSizeType, &size);

        CFRelease(position_ref);
        CFRelease(size_ref);

        if (fabs(position.x - bounds.origin.x) <= 10) {
          CFRetain(item);
          result = item;
          break;
        }
      }
      CFRelease(children_ref);
    }
    CFRelease(extras);
  }

  CFRelease(app);
  return result;
}

void ax_select_menu_extra(char *alias) {
  AXUIElementRef item = ax_get_extra_menu_item(alias);
  if (!item) {
    fprintf(stderr, "Menu extra '%s' not found\n", alias);
    return;
  }

  int cid = SLSMainConnectionID();
  SLSSetMenuBarVisibilityOverrideOnDisplay(cid, 0, false);
  SLSSetMenuBarInsetAndAlpha(cid, 0, 1, 1.0);

  ax_perform_click(item);
  usleep(LONG_DELAY_US);

  if (g_menu_opacity == 0.0f) {
    for (int i = 0; i < 3; i++) {
      SLSSetMenuBarInsetAndAlpha(cid, 0, 1, 0.0);
      SLSSetMenuBarVisibilityOverrideOnDisplay(cid, 0, true);
      SLSSetMenuBarInsetAndAlpha(cid, 0, 1, 0.0);
      usleep(MEDIUM_DELAY_US);
    }
  } else {
    SLSSetMenuBarInsetAndAlpha(cid, 0, 1, g_menu_opacity);
  }

  CFRelease(item);
}

AXUIElementRef ax_get_front_app() {
  ProcessSerialNumber psn;
  _SLPSGetFrontProcess(&psn);
  int target_cid;
  SLSGetConnectionIDForPSN(SLSMainConnectionID(), &psn, &target_cid);

  pid_t pid;
  SLSConnectionGetPID(target_cid, &pid);
  return AXUIElementCreateApplication(pid);
}

float read_opacity_state() {
  FILE *file = fopen(STATE_FILE, "r");
  if (!file) {
    return 1.0f;
  }

  float opacity;
  int result = fscanf(file, "%f", &opacity);
  fclose(file);

  if (result != 1 || opacity < 0.0f || opacity > 1.0f) {
    fprintf(stderr,
            "Warning: Invalid opacity value in state file, using 1.0\n");
    return 1.0f;
  }

  return opacity;
}

bool write_opacity_state(float opacity) {
  // Write to temporary file first, then rename for atomicity
  char temp_file[MAX_BUFFER_SIZE];
  snprintf(temp_file, sizeof(temp_file), "%s.tmp", STATE_FILE);

  FILE *file = fopen(temp_file, "w");
  if (!file) {
    fprintf(stderr, "Error: Cannot write to state file: %s\n", strerror(errno));
    return false;
  }

  if (fprintf(file, "%.2f\n", opacity) < 0) {
    fprintf(stderr, "Error: Failed to write opacity value\n");
    fclose(file);
    unlink(temp_file);
    return false;
  }

  if (fclose(file) != 0) {
    fprintf(stderr, "Error: Failed to close state file: %s\n", strerror(errno));
    unlink(temp_file);
    return false;
  }

  if (rename(temp_file, STATE_FILE) != 0) {
    fprintf(stderr, "Error: Failed to update state file: %s\n",
            strerror(errno));
    unlink(temp_file);
    return false;
  }

  return true;
}

void set_menu_opacity(float opacity) {
  g_menu_opacity = opacity;
  int cid = SLSMainConnectionID();

  if (opacity == 0.0f) {
    // Hide menu bar - use override then set alpha to 0
    SLSSetMenuBarVisibilityOverrideOnDisplay(cid, 0, true);
    SLSSetMenuBarInsetAndAlpha(cid, 0, 1, 0.0);
  } else {
    // Show menu bar - clear override first, then set alpha
    SLSSetMenuBarVisibilityOverrideOnDisplay(cid, 0, false);
    usleep(MEDIUM_DELAY_US); // Give system time to process
    SLSSetMenuBarInsetAndAlpha(cid, 0, 1, opacity);
  }

  if (write_opacity_state(opacity)) {
    printf("Menu bar opacity set to %.1f\n", opacity);
  } else {
    fprintf(stderr, "Warning: Failed to save opacity state\n");
  }
}

bool toggle_menu_opacity() {
  if (acquire_lock() == -1) {
    fprintf(stderr, "Error: Another toggle operation in progress\n");
    return false;
  }

  float new_opacity = (g_menu_opacity == 0.0f) ? 1.0f : 0.0f;
  set_menu_opacity(new_opacity);

  release_lock();
  return true;
}

void run_daemon() {
  printf("Starting menu bar daemon...\n");
  printf("Use './menus -t' to toggle opacity\n");
  printf("Press Ctrl+C to stop daemon\n");

  signal(SIGINT, cleanup_and_exit);
  signal(SIGTERM, cleanup_and_exit);

  ax_init();

  g_menu_opacity = read_opacity_state();
  set_menu_opacity(g_menu_opacity);

  printf("Menu bar daemon running (opacity: %.1f)\n", g_menu_opacity);

  while (!g_should_exit) {
    sleep(2);

    // Check if state file has been updated by toggle command
    float current_state = read_opacity_state();
    if (fabs(current_state - g_menu_opacity) > 0.01f) { // Use float comparison
      g_menu_opacity = current_state;
      printf("Opacity changed to %.1f\n", g_menu_opacity);
    }

    // Only enforce hiding if opacity should be 0
    if (g_menu_opacity == 0.0f) {
      int cid = SLSMainConnectionID();
      SLSSetMenuBarInsetAndAlpha(cid, 0, 1, 0.0);
      SLSSetMenuBarVisibilityOverrideOnDisplay(cid, 0, true);
    }
  }

  cleanup_and_exit(0);
}

int main(int argc, char **argv) {
  if (argc == 1) {
    printf("Usage: %s [-l | -s id/alias | -t | -d]\n", argv[0]);
    printf("  -l          List menu options\n");
    printf("  -s id/alias Select menu option by id or menu extra by alias\n");
    printf("  -t          Toggle menu bar opacity\n");
    printf("  -d          Run as daemon\n");
    exit(0);
  }

  ax_init();

  if (strcmp(argv[1], "-d") == 0) {
    run_daemon();
  } else if (strcmp(argv[1], "-t") == 0) {
    g_menu_opacity = read_opacity_state();
    if (!toggle_menu_opacity()) {
      exit(1);
    }
  } else if (strcmp(argv[1], "-l") == 0) {
    AXUIElementRef app = ax_get_front_app();
    if (!app) {
      fprintf(stderr, "Error: Cannot get front application\n");
      return 1;
    }
    ax_print_menu_options(app);
    CFRelease(app);
  } else if (argc == 3 && strcmp(argv[1], "-s") == 0) {
    int id = 0;
    if (sscanf(argv[2], "%d", &id) == 1) {
      AXUIElementRef app = ax_get_front_app();
      if (!app) {
        fprintf(stderr, "Error: Cannot get front application\n");
        return 1;
      }
      ax_select_menu_option(app, id);
      CFRelease(app);
    } else {
      ax_select_menu_extra(argv[2]);
    }
  } else {
    fprintf(stderr, "Error: Invalid arguments\n");
    return 1;
  }

  return 0;
}
