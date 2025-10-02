#include <Carbon/Carbon.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

// --- Constants ---
#define STATE_FILE_MENU "/tmp/menubar_state"
#define STATE_FILE_DOCK "/tmp/dock_state"
#define LOCK_FILE "/tmp/uiviz.lock"
#define MENU_BAR_LAYER 0x19
#define MAX_BUFFER_SIZE 1024
#define MEDIUM_DELAY_US 100000
#define LONG_DELAY_US 1000000

// --- Global State ---
static bool g_menu_hidden = false;
static bool g_dock_hidden = false;
static volatile sig_atomic_t g_should_exit = 0;

// --- Private APIs ---
extern int SLSMainConnectionID();
extern void SLSSetMenuBarVisibilityOverrideOnDisplay(int cid, int did,
                                                     bool enabled);
extern void SLSSetMenuBarInsetAndAlpha(int cid, double u1, double u2,
                                       float alpha);
extern void _SLPSGetFrontProcess(ProcessSerialNumber *psn);
extern void SLSGetConnectionIDForPSN(int cid, ProcessSerialNumber *psn,
                                     int *cid_out);
extern void SLSConnectionGetPID(int cid, pid_t *pid_out);

// --- State Management ---
bool read_state(const char *path) {
  FILE *file = fopen(path, "r");
  if (!file)
    return false;
  int state = 0;
  fscanf(file, "%d", &state);
  fclose(file);
  return (state == 1);
}

bool write_state(const char *path, bool is_hidden) {
  char temp_path[MAX_BUFFER_SIZE];
  snprintf(temp_path, sizeof(temp_path), "%s.tmp", path);
  FILE *file = fopen(temp_path, "w");
  if (!file) {
    perror("Cannot write to state file");
    return false;
  }
  fprintf(file, "%d\n", is_hidden ? 1 : 0);
  fclose(file);
  if (rename(temp_path, path) != 0) {
    perror("Cannot update state file");
    unlink(temp_path);
    return false;
  }
  return true;
}

// --- File Locking ---
int acquire_lock() {
  int fd = open(LOCK_FILE, O_CREAT | O_EXCL | O_WRONLY, 0644);
  if (fd == -1) {
    if (errno == EEXIST) {
      fprintf(
          stderr,
          "Error: Lock file exists. Another operation may be in progress.\n");
    } else {
      perror("Error acquiring lock");
    }
    return -1;
  }
  char pid_str[16];
  snprintf(pid_str, sizeof(pid_str), "%d", getpid());
  write(fd, pid_str, strlen(pid_str));
  close(fd);
  return 0;
}

void release_lock() { unlink(LOCK_FILE); }

// --- Core Visibility Functions ---
void set_menu_visibility(bool hide) {
  g_menu_hidden = hide;
  int cid = SLSMainConnectionID();

  if (hide) {
    // Try the exact approach from working version
    SLSSetMenuBarVisibilityOverrideOnDisplay(cid, 0, true);
    SLSSetMenuBarInsetAndAlpha(cid, 0, 1, 0.0f);
  } else {
    SLSSetMenuBarVisibilityOverrideOnDisplay(cid, 0, false);
    SLSSetMenuBarInsetAndAlpha(cid, 0, 1, 1.0f);
  }

  write_state(STATE_FILE_MENU, hide);
}

void set_dock_visibility(bool hide) {
  g_dock_hidden = hide;

  if (hide) {
    // Make dock invisible with very long delay but keep autohide enabled
    system("defaults write com.apple.dock autohide -bool true");
    system("defaults write com.apple.dock autohide-delay -float 1000");
    system("defaults write com.apple.dock autohide-time-modifier -float 0");
    system("killall Dock");
  } else {
    // Instant autohide behavior - immediate response
    system("defaults write com.apple.dock autohide -bool true");
    system("defaults write com.apple.dock autohide-delay -float 0.0");
    system("defaults write com.apple.dock autohide-time-modifier -float 0.1");
    system("killall Dock");
    usleep(500000); // Give dock time to restart properly
  }

  write_state(STATE_FILE_DOCK, hide);
}

// --- Accessibility (AX) API Functions ---
void ax_init() {
  const void *keys[] = {kAXTrustedCheckOptionPrompt};
  const void *values[] = {kCFBooleanTrue};
  CFDictionaryRef options = CFDictionaryCreate(
      kCFAllocatorDefault, keys, values, 1,
      &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
  if (!AXIsProcessTrustedWithOptions(options)) {
    fprintf(stderr, "Accessibility permissions required. Please grant them in "
                    "System Settings.\n");
    CFRelease(options);
    exit(1);
  }
  CFRelease(options);
}

AXUIElementRef ax_get_front_app() {
  ProcessSerialNumber psn;
  _SLPSGetFrontProcess(&psn);

  // Use modern API instead of deprecated GetProcessPID
  int cid = SLSMainConnectionID();
  int target_cid;
  SLSGetConnectionIDForPSN(cid, &psn, &target_cid);
  pid_t pid;
  SLSConnectionGetPID(target_cid, &pid);

  return AXUIElementCreateApplication(pid);
}

void ax_perform_click(AXUIElementRef element) {
  if (!element)
    return;

  // Temporarily show menu bar to perform the click
  bool menu_was_hidden = read_state(STATE_FILE_MENU);
  if (menu_was_hidden) {
    set_menu_visibility(false);
    usleep(MEDIUM_DELAY_US * 2); // Give UI time to update
  }

  AXUIElementPerformAction(element, kAXPressAction);
  usleep(LONG_DELAY_US); // Wait for menu to open and actions to complete

  // Restore original menu bar state
  if (menu_was_hidden) {
    set_menu_visibility(true);
  }
}

CFStringRef ax_get_title(AXUIElementRef element) {
  CFTypeRef title = NULL;
  if (AXUIElementCopyAttributeValue(element, kAXTitleAttribute, &title) ==
      kAXErrorSuccess) {
    return (CFStringRef)title;
  }
  return NULL;
}

void ax_print_menu_options(AXUIElementRef app) {
  AXUIElementRef menubar_ref = NULL;
  AXUIElementCopyAttributeValue(app, kAXMenuBarAttribute,
                                (CFTypeRef *)&menubar_ref);
  if (!menubar_ref) {
    fprintf(stderr, "Failed to get menu bar.\n");
    return;
  }

  CFArrayRef children_ref = NULL;
  AXUIElementCopyAttributeValue(menubar_ref, kAXChildrenAttribute,
                                (CFTypeRef *)&children_ref);
  if (!children_ref) {
    fprintf(stderr, "Failed to get menu children.\n");
    CFRelease(menubar_ref);
    return;
  }

  CFIndex count = CFArrayGetCount(children_ref);
  printf("Available menu options:\n");
  for (CFIndex i = 0; i < count; ++i) {
    AXUIElementRef item =
        (AXUIElementRef)CFArrayGetValueAtIndex(children_ref, i);
    CFStringRef title = ax_get_title(item);
    if (title) {
      char buffer[MAX_BUFFER_SIZE];
      CFStringGetCString(title, buffer, sizeof(buffer), kCFStringEncodingUTF8);
      printf("  [%ld] %s\n", i, buffer);
      CFRelease(title);
    }
  }

  CFRelease(children_ref);
  CFRelease(menubar_ref);
}

void ax_select_menu_option(AXUIElementRef app, int index) {
  AXUIElementRef menubar_ref = NULL;
  AXUIElementCopyAttributeValue(app, kAXMenuBarAttribute,
                                (CFTypeRef *)&menubar_ref);
  if (!menubar_ref) {
    fprintf(stderr, "Failed to get menu bar for selection.\n");
    return;
  }

  CFArrayRef children_ref = NULL;
  AXUIElementCopyAttributeValue(menubar_ref, kAXChildrenAttribute,
                                (CFTypeRef *)&children_ref);
  if (!children_ref) {
    fprintf(stderr, "Failed to get menu children for selection.\n");
    CFRelease(menubar_ref);
    return;
  }

  if (index >= 0 && index < CFArrayGetCount(children_ref)) {
    AXUIElementRef item =
        (AXUIElementRef)CFArrayGetValueAtIndex(children_ref, index);
    ax_perform_click(item);
  } else {
    fprintf(stderr, "Error: Menu index %d is out of bounds.\n", index);
  }

  CFRelease(children_ref);
  CFRelease(menubar_ref);
}

// --- Signal Handling & Cleanup ---
void cleanup_and_exit(int sig) {
  (void)sig;
  g_should_exit = 1;
  int cid = SLSMainConnectionID();
  printf("\nRestoring UI and exiting...\n");
  SLSSetMenuBarVisibilityOverrideOnDisplay(cid, 0, false);
  SLSSetMenuBarInsetAndAlpha(cid, 0, 1, 1.0);

  // Restore dock defaults but keep autohide enabled
  system("defaults delete com.apple.dock autohide-delay 2>/dev/null");
  system("defaults write com.apple.dock autohide -bool true");
  system("killall Dock");

  unlink(STATE_FILE_MENU);
  unlink(STATE_FILE_DOCK);
  unlink(LOCK_FILE);
  _exit(0);
}

// --- Toggle Functions ---
void toggle_menu() {
  if (acquire_lock() != 0)
    return;
  bool is_currently_hidden = read_state(STATE_FILE_MENU);
  set_menu_visibility(!is_currently_hidden);
  printf("Menu bar visibility set to: %s\n",
         !is_currently_hidden ? "Hidden" : "Visible");
  release_lock();
}

void toggle_dock() {
  if (acquire_lock() != 0)
    return;
  bool is_currently_hidden = read_state(STATE_FILE_DOCK);
  set_dock_visibility(!is_currently_hidden);
  printf("Dock auto-hide set to: %s\n",
         !is_currently_hidden ? "Invisible" : "Normal");
  release_lock();
}

// --- Daemon ---
void run_daemon() {
  printf("Starting UI visibility daemon...\n");
  printf("Press Ctrl+C to stop and restore UI.\n");

  signal(SIGINT, cleanup_and_exit);
  signal(SIGTERM, cleanup_and_exit);

  // Always start with dock and menu hidden by default
  g_menu_hidden = true;
  g_dock_hidden = true;
  write_state(STATE_FILE_MENU, true);
  write_state(STATE_FILE_DOCK, true);

  set_menu_visibility(g_menu_hidden);
  set_dock_visibility(g_dock_hidden);

  while (!g_should_exit) {
    sleep(2);
    bool menu_state_in_file = read_state(STATE_FILE_MENU);
    if (menu_state_in_file != g_menu_hidden)
      set_menu_visibility(menu_state_in_file);

    bool dock_state_in_file = read_state(STATE_FILE_DOCK);
    if (dock_state_in_file != g_dock_hidden)
      set_dock_visibility(dock_state_in_file);

    int cid = SLSMainConnectionID();
    if (g_menu_hidden)
      SLSSetMenuBarVisibilityOverrideOnDisplay(cid, 0, true);
  }
}

// --- Main Function ---
int main(int argc, char **argv) {
  if (argc < 2) {
    fprintf(stderr, "Usage: %s [flag] [argument]\n", argv[0]);
    fprintf(stderr, "\n--- Visibility Control ---\n");
    fprintf(stderr, "  -d          Run as a daemon to maintain UI state.\n");
    fprintf(stderr, "  -t, -tb     Toggle BOTH menu bar and Dock.\n");
    fprintf(stderr, "  -tm         Toggle menu bar ONLY.\n");
    fprintf(stderr, "  -td         Toggle Dock ONLY.\n");
    fprintf(stderr, "\n--- Menu Interaction ---\n");
    fprintf(stderr, "  -l          List menu options for the frontmost app.\n");
    fprintf(stderr, "  -s [index]  Select a menu option by its index.\n");
    return 1;
  }

  const char *flag = argv[1];

  if (strcmp(flag, "-d") == 0) {
    run_daemon();
  } else if (strcmp(flag, "-t") == 0 || strcmp(flag, "-tb") == 0) {
    // Use a single lock for the combined operation
    if (acquire_lock() != 0)
      return 1;
    bool menu_hidden = read_state(STATE_FILE_MENU);
    bool dock_hidden = read_state(STATE_FILE_DOCK);
    set_menu_visibility(!menu_hidden);
    set_dock_visibility(!dock_hidden);
    printf("Menu bar visibility set to: %s\n",
           !menu_hidden ? "Hidden" : "Visible");
    printf("Dock auto-hide set to: %s\n",
           !dock_hidden ? "Invisible" : "Normal");
    release_lock();
  } else if (strcmp(flag, "-tm") == 0) {
    toggle_menu();
  } else if (strcmp(flag, "-td") == 0) {
    toggle_dock();
  } else if (strcmp(flag, "-l") == 0) {
    ax_init();
    AXUIElementRef app = ax_get_front_app();
    if (app) {
      ax_print_menu_options(app);
      CFRelease(app);
    }
  } else if (strcmp(flag, "-s") == 0) {
    if (argc < 3) {
      fprintf(stderr, "Error: -s flag requires an index argument.\n");
      return 1;
    }
    ax_init();
    int index = atoi(argv[2]);
    AXUIElementRef app = ax_get_front_app();
    if (app) {
      ax_select_menu_option(app, index);
      CFRelease(app);
    }
  } else {
    fprintf(stderr, "Error: Invalid flag '%s'\n", flag);
    return 1;
  }

  return 0;
}
