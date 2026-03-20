#include <ApplicationServices/ApplicationServices.h>
#include <Carbon/Carbon.h>
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <math.h>
#include <signal.h>
#include <spawn.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/event.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>

extern char **environ;

#define STATE_FILE_MENU "/tmp/uiviz_menu"
#define STATE_FILE_DOCK "/tmp/uiviz_dock"
#define DAEMON_LOCK_FILE "/tmp/uiviz.daemon.lock"
#define STATE_LOCK_FILE "/tmp/uiviz.state.lock"

/* ------------------------------------------------------------------ */
/* SkyLight                                                             */
/* ------------------------------------------------------------------ */

typedef int (*SLSMainConnectionID_t)(void);
typedef void (*SLSSetMenuBarVisibilityOverrideOnDisplay_t)(int, int, bool);
typedef void (*SLSSetMenuBarInsetAndAlpha_t)(int, double, double, float);

/* SkyLight extras needed for ax_select_menu_extra */
typedef void (*SLSGetConnectionIDForPSN_t)(int, ProcessSerialNumber *, int *);
typedef void (*SLSConnectionGetPID_t)(int, pid_t *);
typedef void (*_SLPSGetFrontProcess_t)(ProcessSerialNumber *);

static SLSMainConnectionID_t fn_conn;
static SLSSetMenuBarVisibilityOverrideOnDisplay_t fn_vis;
static SLSSetMenuBarInsetAndAlpha_t fn_inset;
static SLSGetConnectionIDForPSN_t fn_get_cid_for_psn;
static SLSConnectionGetPID_t fn_conn_get_pid;
static _SLPSGetFrontProcess_t fn_front_process;

static void skylight_init(void) {
  void *h =
      dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
             RTLD_LAZY);
  if (!h) {
    perror("SkyLight");
    exit(1);
  }

  fn_conn = dlsym(h, "SLSMainConnectionID");
  fn_vis = dlsym(h, "SLSSetMenuBarVisibilityOverrideOnDisplay");
  fn_inset = dlsym(h, "SLSSetMenuBarInsetAndAlpha");
  fn_get_cid_for_psn = dlsym(h, "SLSGetConnectionIDForPSN");
  fn_conn_get_pid = dlsym(h, "SLSConnectionGetPID");
  fn_front_process = dlsym(h, "_SLPSGetFrontProcess");

  if (!fn_conn || !fn_vis || !fn_inset) {
    fprintf(stderr, "SkyLight symbols missing\n");
    exit(1);
  }
  /* AX-related symbols are optional — only needed for -s/-l */
}

/* ------------------------------------------------------------------ */
/* State                                                                */
/* ------------------------------------------------------------------ */

typedef enum { ST_UNKNOWN = -1, ST_VISIBLE = 0, ST_HIDDEN = 1 } UIState;

static UIState read_state(const char *path) {
  FILE *f = fopen(path, "r");
  if (!f)
    return ST_UNKNOWN;

  int v;
  if (fscanf(f, "%d", &v) != 1) {
    fclose(f);
    return ST_UNKNOWN;
  }
  fclose(f);
  return v ? ST_HIDDEN : ST_VISIBLE;
}

static void write_state(const char *path, bool hidden) {
  char tmp[256];
  snprintf(tmp, sizeof(tmp), "%s.tmp", path);

  FILE *f = fopen(tmp, "w");
  if (!f)
    return;

  fprintf(f, "%d\n", hidden ? 1 : 0);
  fclose(f);
  rename(tmp, path);
}

/* ------------------------------------------------------------------ */
/* Exec                                                                 */
/* ------------------------------------------------------------------ */

static void run(char *const argv[]) {
  pid_t pid;
  if (posix_spawn(&pid, argv[0], NULL, NULL, argv, environ) == 0)
    waitpid(pid, NULL, 0);
}

/* ------------------------------------------------------------------ */
/* Menu / Dock                                                          */
/* ------------------------------------------------------------------ */

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

static void apply_dock(bool hide) {
  char *autohide[] = {"/usr/bin/defaults",
                      "write",
                      "com.apple.dock",
                      "autohide",
                      "-bool",
                      "true",
                      NULL};
  run(autohide);

  if (hide) {
    char *delay[] = {"/usr/bin/defaults",
                     "write",
                     "com.apple.dock",
                     "autohide-delay",
                     "-float",
                     "1000",
                     NULL};
    char *speed[] = {"/usr/bin/defaults",
                     "write",
                     "com.apple.dock",
                     "autohide-time-modifier",
                     "-float",
                     "0",
                     NULL};
    run(delay);
    run(speed);
  } else {
    char *delay[] = {"/usr/bin/defaults",
                     "write",
                     "com.apple.dock",
                     "autohide-delay",
                     "-float",
                     "0",
                     NULL};
    char *speed[] = {"/usr/bin/defaults",
                     "write",
                     "com.apple.dock",
                     "autohide-time-modifier",
                     "-float",
                     "0.1",
                     NULL};
    run(delay);
    run(speed);
  }

  char *kill[] = {"/usr/bin/killall", "Dock", NULL};
  run(kill);

  char *pgrep[] = {"/usr/bin/pgrep", "Dock", NULL};
  for (int i = 0; i < 30; i++) {
    usleep(100000);
    pid_t pid;
    if (posix_spawn(&pid, pgrep[0], NULL, NULL, pgrep, environ) == 0) {
      int status;
      if (waitpid(pid, &status, 0) > 0 && WIFEXITED(status) &&
          WEXITSTATUS(status) == 0)
        break;
    }
  }
}

/* ------------------------------------------------------------------ */
/* Locks                                                                */
/* ------------------------------------------------------------------ */

static int daemon_fd = -1;
static int state_fd = -1;

static void singleton_lock(void) {
  daemon_fd = open(DAEMON_LOCK_FILE, O_CREAT | O_RDWR, 0644);
  if (daemon_fd < 0)
    exit(1);
  if (flock(daemon_fd, LOCK_EX | LOCK_NB) < 0)
    exit(0); /* already running */
}

static void lock(void) {
  state_fd = open(STATE_LOCK_FILE, O_CREAT | O_RDWR, 0644);
  if (state_fd >= 0)
    flock(state_fd, LOCK_EX);
}

static void unlock(void) {
  if (state_fd >= 0) {
    flock(state_fd, LOCK_UN);
    close(state_fd);
    state_fd = -1;
  }
}

/* ------------------------------------------------------------------ */
/* Watch                                                                */
/* ------------------------------------------------------------------ */

struct Watch {
  int fd;
  const char *path;
};

static void watch_register(int kq, struct Watch *w) {
  if (w->fd >= 0)
    close(w->fd);

  w->fd = open(w->path, O_EVTONLY | O_CREAT, 0644);
  if (w->fd < 0)
    return;

  struct kevent ev;
  EV_SET(&ev, w->fd, EVFILT_VNODE, EV_ADD | EV_CLEAR,
         NOTE_WRITE | NOTE_DELETE | NOTE_RENAME, 0, NULL);
  kevent(kq, &ev, 1, NULL, 0, NULL);
}

/* ------------------------------------------------------------------ */
/* Daemon                                                               */
/* ------------------------------------------------------------------ */

static void daemonize(void) {
  if (fork() > 0)
    exit(0);
  setsid();
  if (fork() > 0)
    exit(0);
  chdir("/");

  int fd = open("/dev/null", O_RDWR);
  if (fd >= 0) {
    dup2(fd, 0);
    dup2(fd, 1);
    dup2(fd, 2);
    if (fd > 2)
      close(fd);
  }
}

static void run_daemon(void) {
  skylight_init();
  daemonize();
  singleton_lock();

  int kq = kqueue();

  struct kevent sigs[2];
  EV_SET(&sigs[0], SIGTERM, EVFILT_SIGNAL, EV_ADD, 0, 0, NULL);
  EV_SET(&sigs[1], SIGINT, EVFILT_SIGNAL, EV_ADD, 0, 0, NULL);
  kevent(kq, sigs, 2, NULL, 0, NULL);
  signal(SIGTERM, SIG_IGN);
  signal(SIGINT, SIG_IGN);

  struct kevent timer;
  EV_SET(&timer, 1, EVFILT_TIMER, EV_ADD | EV_ENABLE, 0, 1000, NULL);
  kevent(kq, &timer, 1, NULL, 0, NULL);

  struct Watch menu = {.fd = -1, .path = STATE_FILE_MENU};
  struct Watch dock = {.fd = -1, .path = STATE_FILE_DOCK};
  watch_register(kq, &menu);
  watch_register(kq, &dock);

  bool menu_hidden = true;
  bool dock_hidden = true;

  write_state(STATE_FILE_MENU, true);
  write_state(STATE_FILE_DOCK, true);
  apply_menu(true);
  apply_dock(true);

  struct kevent ev;
  int running = 1;

  while (running) {
    if (kevent(kq, NULL, 0, &ev, 1, NULL) <= 0)
      continue;

    if (ev.filter == EVFILT_SIGNAL) {
      running = 0;
      continue;
    }

    if (ev.filter == EVFILT_TIMER) {
      if (menu_hidden)
        apply_menu(true);
      continue;
    }

    struct Watch *w = NULL;
    if (ev.ident == (uintptr_t)menu.fd)
      w = &menu;
    else if (ev.ident == (uintptr_t)dock.fd)
      w = &dock;
    if (!w)
      continue;

    if (ev.fflags & (NOTE_DELETE | NOTE_RENAME))
      watch_register(kq, w);

    lock();
    UIState m = read_state(STATE_FILE_MENU);
    UIState d = read_state(STATE_FILE_DOCK);

    if (m != ST_UNKNOWN && (m == ST_HIDDEN) != menu_hidden) {
      menu_hidden = (m == ST_HIDDEN);
      apply_menu(menu_hidden);
    }
    if (d != ST_UNKNOWN && (d == ST_HIDDEN) != dock_hidden) {
      dock_hidden = (d == ST_HIDDEN);
      apply_dock(dock_hidden);
    }
    unlock();
  }

  apply_menu(false);
  apply_dock(false);
}

/* ------------------------------------------------------------------ */
/* CLI toggle                                                           */
/* ------------------------------------------------------------------ */

static void toggle(const char *path) {
  lock();
  UIState s = read_state(path);
  write_state(path, s == ST_HIDDEN ? false : true);
  unlock();
}

/* ------------------------------------------------------------------ */
/* Accessibility                                                        */
/* ------------------------------------------------------------------ */

static void ax_init(void) {
  const void *keys[] = {kAXTrustedCheckOptionPrompt};
  const void *values[] = {kCFBooleanTrue};
  CFDictionaryRef opts = CFDictionaryCreate(
      kCFAllocatorDefault, keys, values, 1,
      &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
  bool trusted = AXIsProcessTrustedWithOptions(opts);
  CFRelease(opts);
  if (!trusted) {
    fprintf(stderr, "Accessibility permission required\n");
    exit(1);
  }
}

static void ax_perform_click(AXUIElementRef element) {
  if (!element)
    return;
  AXUIElementPerformAction(element, kAXCancelAction);
  usleep(150000);
  AXUIElementPerformAction(element, kAXPressAction);
}

static CFStringRef ax_get_title(AXUIElementRef element) {
  CFTypeRef title = NULL;
  if (AXUIElementCopyAttributeValue(element, kAXTitleAttribute, &title) !=
      kAXErrorSuccess)
    return NULL;
  return (CFStringRef)title;
}

/* Returns the front app as an AXUIElementRef via SkyLight PSN lookup.
   Caller must CFRelease the result. */
static AXUIElementRef ax_get_front_app(void) {
  if (!fn_front_process || !fn_get_cid_for_psn || !fn_conn_get_pid) {
    fprintf(stderr, "SkyLight PSN symbols unavailable\n");
    return NULL;
  }
  ProcessSerialNumber psn;
  fn_front_process(&psn);
  int target_cid;
  fn_get_cid_for_psn(fn_conn(), &psn, &target_cid);
  pid_t pid;
  fn_conn_get_pid(target_cid, &pid);
  return AXUIElementCreateApplication(pid);
}

/* Print all visible menu bar items of the front app */
static void ax_print_menu_options(AXUIElementRef app) {
  AXUIElementRef menubar = NULL;
  CFArrayRef children = NULL;

  if (AXUIElementCopyAttributeValue(app, kAXMenuBarAttribute,
                                    (CFTypeRef *)&menubar) != kAXErrorSuccess)
    return;

  if (AXUIElementCopyAttributeValue(menubar, kAXVisibleChildrenAttribute,
                                    (CFTypeRef *)&children) ==
      kAXErrorSuccess) {
    CFIndex count = CFArrayGetCount(children);
    for (CFIndex i = 1; i < count; i++) {
      AXUIElementRef item = (AXUIElementRef)CFArrayGetValueAtIndex(children, i);
      CFStringRef title = ax_get_title(item);
      if (title) {
        CFIndex len = CFStringGetLength(title);
        char buf[2 * len + 1];
        CFStringGetCString(title, buf, sizeof(buf), kCFStringEncodingUTF8);
        printf("%lld: %s\n", (long long)i, buf);
        CFRelease(title);
      }
    }
    CFRelease(children);
  }
  CFRelease(menubar);
}

/* Click a menu bar item by index */
static void ax_select_menu_option(AXUIElementRef app, int id) {
  AXUIElementRef menubar = NULL;
  CFArrayRef children = NULL;

  if (AXUIElementCopyAttributeValue(app, kAXMenuBarAttribute,
                                    (CFTypeRef *)&menubar) != kAXErrorSuccess)
    return;

  if (AXUIElementCopyAttributeValue(menubar, kAXVisibleChildrenAttribute,
                                    (CFTypeRef *)&children) ==
      kAXErrorSuccess) {
    CFIndex count = CFArrayGetCount(children);
    if (id < count) {
      AXUIElementRef item =
          (AXUIElementRef)CFArrayGetValueAtIndex(children, id);
      ax_perform_click(item);
    }
    CFRelease(children);
  }
  CFRelease(menubar);
}

/* Find a status-bar extra by "OwnerName,WindowName" alias using CGWindowList,
   then click it while briefly revealing the menu bar. */
static void ax_select_menu_extra(const char *alias) {
  pid_t pid = 0;
  CGRect bounds = CGRectNull;

  CFArrayRef wlist =
      CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID);
  CFIndex n = CFArrayGetCount(wlist);
  for (CFIndex i = 0; i < n; i++) {
    CFDictionaryRef d = CFArrayGetValueAtIndex(wlist, i);
    if (!d)
      continue;

    CFStringRef owner_ref = CFDictionaryGetValue(d, kCGWindowOwnerName);
    CFStringRef name_ref = CFDictionaryGetValue(d, kCGWindowName);
    CFNumberRef pid_ref = CFDictionaryGetValue(d, kCGWindowOwnerPID);
    CFNumberRef layer_ref = CFDictionaryGetValue(d, kCGWindowLayer);
    CFDictionaryRef bounds_ref = CFDictionaryGetValue(d, kCGWindowBounds);

    if (!owner_ref || !name_ref || !pid_ref || !layer_ref || !bounds_ref)
      continue;

    long long layer = 0;
    CFNumberGetValue(layer_ref, kCFNumberLongLongType, &layer);
    if (layer != 0x19)
      continue;

    CGRect r = CGRectNull;
    if (!CGRectMakeWithDictionaryRepresentation(bounds_ref, &r))
      continue;

    char owner[256], name[256], combined[512];
    CFStringGetCString(owner_ref, owner, sizeof(owner), kCFStringEncodingUTF8);
    CFStringGetCString(name_ref, name, sizeof(name), kCFStringEncodingUTF8);
    snprintf(combined, sizeof(combined), "%s,%s", owner, name);

    if (strcmp(combined, alias) == 0) {
      uint64_t p = 0;
      CFNumberGetValue(pid_ref, kCFNumberSInt64Type, &p);
      pid = (pid_t)p;
      bounds = r;
      break;
    }
  }
  CFRelease(wlist);
  if (!pid) {
    fprintf(stderr, "Menu extra not found: %s\n", alias);
    return;
  }

  AXUIElementRef app = AXUIElementCreateApplication(pid);
  if (!app)
    return;

  CFTypeRef extras = NULL;
  CFArrayRef children = NULL;
  AXUIElementRef result = NULL;

  if (AXUIElementCopyAttributeValue(app, kAXExtrasMenuBarAttribute, &extras) ==
      kAXErrorSuccess) {
    if (AXUIElementCopyAttributeValue(extras, kAXVisibleChildrenAttribute,
                                      (CFTypeRef *)&children) ==
        kAXErrorSuccess) {
      CFIndex count = CFArrayGetCount(children);
      for (CFIndex i = 0; i < count; i++) {
        AXUIElementRef item =
            (AXUIElementRef)CFArrayGetValueAtIndex(children, i);
        CFTypeRef pos_ref = NULL, size_ref = NULL;
        AXUIElementCopyAttributeValue(item, kAXPositionAttribute, &pos_ref);
        AXUIElementCopyAttributeValue(item, kAXSizeAttribute, &size_ref);
        if (!pos_ref || !size_ref) {
          if (pos_ref)
            CFRelease(pos_ref);
          if (size_ref)
            CFRelease(size_ref);
          continue;
        }
        CGPoint pos = CGPointZero;
        AXValueGetValue((AXValueRef)pos_ref, kAXValueCGPointType, &pos);
        CFRelease(pos_ref);
        CFRelease(size_ref);

        if (fabs(pos.x - bounds.origin.x) <= 10) {
          result = item;
          CFRetain(result);
          break;
        }
      }
      CFRelease(children);
    }
    CFRelease(extras);
  }
  CFRelease(app);

  if (!result) {
    fprintf(stderr, "Could not locate extra element\n");
    return;
  }

  /* Briefly reveal the menu bar, click, then re-hide */
  int cid = fn_conn();
  fn_vis(cid, 0, false);
  fn_inset(cid, 0.0, 1.0, 1.0f);
  usleep(50000);

  ax_perform_click(result);

  fn_vis(cid, 0, true);
  fn_inset(cid, -200.0, 1.0, 0.0f);

  CFRelease(result);
}

/* ------------------------------------------------------------------ */
/* Main                                                                 */
/* ------------------------------------------------------------------ */

int main(int argc, char **argv) {
  if (argc < 2) {
    printf("Usage:\n"
           "  -d        run daemon\n"
           "  -tm       toggle menu bar\n"
           "  -td       toggle dock\n"
           "  -t        toggle both\n"
           "  -l        list front app's menu bar items\n"
           "  -s <id>   click menu bar item by index (front app)\n"
           "  -s <str>  click status bar extra by 'Owner,Name' alias\n");
    return 1;
  }

  if (!strcmp(argv[1], "-d")) {
    run_daemon();
  } else if (!strcmp(argv[1], "-tm")) {
    toggle(STATE_FILE_MENU);
  } else if (!strcmp(argv[1], "-td")) {
    toggle(STATE_FILE_DOCK);
  } else if (!strcmp(argv[1], "-t")) {
    toggle(STATE_FILE_MENU);
    toggle(STATE_FILE_DOCK);
  } else if (!strcmp(argv[1], "-l")) {
    skylight_init();
    ax_init();
    AXUIElementRef app = ax_get_front_app();
    if (!app)
      return 1;
    ax_print_menu_options(app);
    CFRelease(app);
  } else if (!strcmp(argv[1], "-s") && argc == 3) {
    skylight_init();
    ax_init();
    int id = 0;
    if (sscanf(argv[2], "%d", &id) == 1) {
      AXUIElementRef app = ax_get_front_app();
      if (!app)
        return 1;
      ax_select_menu_option(app, id);
      CFRelease(app);
    } else {
      ax_select_menu_extra(argv[2]);
    }
  } else {
    fprintf(stderr, "Unknown option: %s\n", argv[1]);
    return 1;
  }

  return 0;
}
