#include <ApplicationServices/ApplicationServices.h>
#include <Carbon/Carbon.h>
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <unistd.h>

#define STATE_FILE_MENU "/tmp/menubar_state"
#define STATE_FILE_DOCK "/tmp/dock_state"

#define LOCK_FILE "/tmp/uiviz.lock"

#define LOOP_DELAY 1

static bool g_menu_hidden = true;
static bool g_dock_hidden = true;
static volatile sig_atomic_t g_should_exit = 0;

static int g_lock_fd = -1;

//
// SkyLight dynamic loading
//

typedef int (*SLSMainConnectionID_t)(void);
typedef void (*SLSSetMenuBarVisibilityOverrideOnDisplay_t)(int, int, bool);
typedef void (*SLSSetMenuBarInsetAndAlpha_t)(int, double, double, float);

static SLSMainConnectionID_t SLSMainConnectionID_ptr;
static SLSSetMenuBarVisibilityOverrideOnDisplay_t
    SLSSetMenuBarVisibilityOverrideOnDisplay_ptr;
static SLSSetMenuBarInsetAndAlpha_t SLSSetMenuBarInsetAndAlpha_ptr;

void skylight_init() {
  void *handle =
      dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
             RTLD_LAZY);

  if (!handle) {
    fprintf(stderr, "Failed to load SkyLight\n");
    exit(1);
  }

  SLSMainConnectionID_ptr = dlsym(handle, "SLSMainConnectionID");
  SLSSetMenuBarVisibilityOverrideOnDisplay_ptr =
      dlsym(handle, "SLSSetMenuBarVisibilityOverrideOnDisplay");
  SLSSetMenuBarInsetAndAlpha_ptr = dlsym(handle, "SLSSetMenuBarInsetAndAlpha");

  if (!SLSMainConnectionID_ptr ||
      !SLSSetMenuBarVisibilityOverrideOnDisplay_ptr ||
      !SLSSetMenuBarInsetAndAlpha_ptr) {
    fprintf(stderr, "Failed resolving SkyLight symbols\n");
    exit(1);
  }
}

//
// State helpers
//

bool read_state(const char *path) {
  FILE *f = fopen(path, "r");
  if (!f)
    return false;

  int v = 0;
  fscanf(f, "%d", &v);
  fclose(f);

  return v == 1;
}

void write_state(const char *path, bool v) {
  FILE *f = fopen(path, "w");
  if (!f)
    return;

  fprintf(f, "%d\n", v ? 1 : 0);
  fclose(f);
}

//
// Locking
//

bool acquire_lock() {
  g_lock_fd = open(LOCK_FILE, O_CREAT | O_RDWR, 0644);

  if (g_lock_fd < 0)
    return false;

  if (flock(g_lock_fd, LOCK_EX | LOCK_NB) < 0) {
    close(g_lock_fd);
    g_lock_fd = -1;
    return false;
  }

  return true;
}

void release_lock() {
  if (g_lock_fd >= 0) {
    flock(g_lock_fd, LOCK_UN);
    close(g_lock_fd);
    g_lock_fd = -1;
  }
}

//
// Menu bar control
//

void hide_menu() {
  int cid = SLSMainConnectionID_ptr();

  SLSSetMenuBarVisibilityOverrideOnDisplay_ptr(cid, 0, true);

  /* push bar offscreen */
  SLSSetMenuBarInsetAndAlpha_ptr(cid, -200.0, 1.0, 0.0f);
}

void show_menu() {
  int cid = SLSMainConnectionID_ptr();

  SLSSetMenuBarVisibilityOverrideOnDisplay_ptr(cid, 0, false);
  SLSSetMenuBarInsetAndAlpha_ptr(cid, 0.0, 1.0, 1.0f);
}

void set_menu(bool hide) {
  g_menu_hidden = hide;

  if (hide)
    hide_menu();
  else
    show_menu();

  write_state(STATE_FILE_MENU, hide);
}

//
// Dock control (your proven trick)
//

void hide_dock() {
  system("defaults write com.apple.dock autohide -bool true");
  system("defaults write com.apple.dock autohide-delay -float 1000");
  system("defaults write com.apple.dock autohide-time-modifier -float 0");
  system("killall Dock");
}

void show_dock() {
  system("defaults write com.apple.dock autohide -bool true");
  system("defaults write com.apple.dock autohide-delay -float 0");
  system("defaults write com.apple.dock autohide-time-modifier -float 0.1");
  system("killall Dock");
}

void set_dock(bool hide) {
  g_dock_hidden = hide;

  if (hide)
    hide_dock();
  else
    show_dock();

  write_state(STATE_FILE_DOCK, hide);
}

//
// Cleanup
//

void cleanup(int sig) {
  (void)sig;

  printf("\nRestoring UI\n");

  show_menu();
  show_dock();

  unlink(STATE_FILE_MENU);
  unlink(STATE_FILE_DOCK);

  exit(0);
}

//
// Toggle helpers
//

void toggle_menu() {
  if (!acquire_lock())
    return;

  bool state = read_state(STATE_FILE_MENU);

  set_menu(!state);

  printf("Menu: %s\n", !state ? "hidden" : "visible");

  release_lock();
}

void toggle_dock() {
  if (!acquire_lock())
    return;

  bool state = read_state(STATE_FILE_DOCK);

  set_dock(!state);

  printf("Dock: %s\n", !state ? "hidden" : "visible");

  release_lock();
}

//
// Daemon
//

void run_daemon() {
  signal(SIGINT, cleanup);
  signal(SIGTERM, cleanup);

  /* default hidden */
  set_menu(true);
  set_dock(true);

  printf("UI daemon running\n");

  while (!g_should_exit) {
    bool menu_file = read_state(STATE_FILE_MENU);
    bool dock_file = read_state(STATE_FILE_DOCK);

    if (menu_file != g_menu_hidden)
      set_menu(menu_file);

    if (dock_file != g_dock_hidden)
      set_dock(dock_file);

    /* enforce hide each loop (macOS resets it) */
    if (g_menu_hidden)
      hide_menu();

    sleep(LOOP_DELAY);
  }
}

//
// Main
//

int main(int argc, char **argv) {
  skylight_init();

  if (argc < 2) {
    printf("Usage:\n");
    printf("  -d   run daemon (default both hidden)\n");
    printf("  -t   toggle both\n");
    printf("  -tm  toggle menu\n");
    printf("  -td  toggle dock\n");
    return 1;
  }

  if (!strcmp(argv[1], "-d"))
    run_daemon();

  else if (!strcmp(argv[1], "-t")) {
    toggle_menu();
    toggle_dock();
  }

  else if (!strcmp(argv[1], "-tm"))
    toggle_menu();

  else if (!strcmp(argv[1], "-td"))
    toggle_dock();

  return 0;
}
