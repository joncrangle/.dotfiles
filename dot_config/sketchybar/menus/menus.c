#include <Carbon/Carbon.h>
#include <signal.h>
#include <stdbool.h>
#include <sys/stat.h>
#include <unistd.h>

// Global state
static float g_menu_opacity = 1.0f;
static bool g_should_exit = false;

extern int SLSMainConnectionID();
extern void SLSSetMenuBarVisibilityOverrideOnDisplay(int cid, int did,
                                                     bool enabled);
extern void SLSSetMenuBarInsetAndAlpha(int cid, double u1, double u2,
                                       float alpha);
extern void _SLPSGetFrontProcess(ProcessSerialNumber *psn);
extern void SLSGetConnectionIDForPSN(int cid, ProcessSerialNumber *psn,
                                     int *cid_out);
extern void SLSConnectionGetPID(int cid, pid_t *pid_out);

#define STATE_FILE "/tmp/menubar_opacity_state"

void cleanup_and_exit(int sig) {
  g_should_exit = true;
  int cid = SLSMainConnectionID();
  SLSSetMenuBarVisibilityOverrideOnDisplay(cid, 0, false);
  SLSSetMenuBarInsetAndAlpha(cid, 0, 1, 1.0);
  printf("Menu bar daemon stopped - opacity restored\n");
  fflush(stdout);
  _exit(0); // async-signal-safe exit
}

void ax_init() {
  const void *keys[] = {kAXTrustedCheckOptionPrompt};
  const void *values[] = {kCFBooleanTrue};

  CFDictionaryRef options = CFDictionaryCreate(
      kCFAllocatorDefault, keys, values, 1,
      &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

  bool trusted = AXIsProcessTrustedWithOptions(options);
  CFRelease(options);
  if (!trusted)
    exit(1);
}

void ax_perform_click(AXUIElementRef element) {
  if (!element)
    return;

  // Temporarily show menu bar when using menu
  int cid = SLSMainConnectionID();
  SLSSetMenuBarVisibilityOverrideOnDisplay(cid, 0, false);
  SLSSetMenuBarInsetAndAlpha(cid, 0, 1, 1.0);

  AXUIElementPerformAction(element, kAXCancelAction);
  usleep(150000);
  AXUIElementPerformAction(element, kAXPressAction);

  usleep(1000000); // 1 second

  if (g_menu_opacity == 0.0f) {
    for (int i = 0; i < 3; i++) {
      SLSSetMenuBarInsetAndAlpha(cid, 0, 1, 0.0);
      SLSSetMenuBarVisibilityOverrideOnDisplay(cid, 0, true);
      SLSSetMenuBarInsetAndAlpha(cid, 0, 1, 0.0);
      usleep(100000);
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
  return title;
}

void ax_select_menu_option(AXUIElementRef app, int id) {
  AXUIElementRef menubars_ref = NULL;
  CFArrayRef children_ref = NULL;

  AXError error = AXUIElementCopyAttributeValue(app, kAXMenuBarAttribute,
                                                (CFTypeRef *)&menubars_ref);
  if (error == kAXErrorSuccess) {
    error = AXUIElementCopyAttributeValue(
        menubars_ref, kAXVisibleChildrenAttribute, (CFTypeRef *)&children_ref);

    if (error == kAXErrorSuccess) {
      uint32_t count = CFArrayGetCount(children_ref);
      if (id < count) {
        AXUIElementRef item = CFArrayGetValueAtIndex(children_ref, id);
        ax_perform_click(item);
      }
      CFRelease(children_ref);
    }
    CFRelease(menubars_ref);
  }
}

void ax_print_menu_options(AXUIElementRef app) {
  AXUIElementRef menubars_ref = NULL;
  CFArrayRef children_ref = NULL;

  AXError error = AXUIElementCopyAttributeValue(app, kAXMenuBarAttribute,
                                                (CFTypeRef *)&menubars_ref);
  if (error == kAXErrorSuccess) {
    error = AXUIElementCopyAttributeValue(
        menubars_ref, kAXVisibleChildrenAttribute, (CFTypeRef *)&children_ref);

    if (error == kAXErrorSuccess) {
      uint32_t count = CFArrayGetCount(children_ref);

      for (int i = 1; i < count; i++) {
        AXUIElementRef item = CFArrayGetValueAtIndex(children_ref, i);
        CFTypeRef title = ax_get_title(item);

        if (title) {
          char buffer[512];
          if (CFStringGetCString(title, buffer, sizeof(buffer),
                                 kCFStringEncodingUTF8)) {
            printf("%s\n", buffer);
          }
          CFRelease(title);
        }
      }
      CFRelease(children_ref);
    }
    CFRelease(menubars_ref);
  }
}

AXUIElementRef ax_get_extra_menu_item(char *alias) {
  pid_t pid = 0;
  CGRect bounds = CGRectNull;
  CFArrayRef window_list =
      CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID);

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

    if (layer != 0x19)
      continue;
    if (!CGRectMakeWithDictionaryRepresentation(bounds_ref, &bounds))
      continue;

    char owner_buffer[256], name_buffer[256], buffer[512];
    CFStringGetCString(owner_ref, owner_buffer, sizeof(owner_buffer),
                       kCFStringEncodingUTF8);
    CFStringGetCString(name_ref, name_buffer, sizeof(name_buffer),
                       kCFStringEncodingUTF8);
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
  if (error == kAXErrorSuccess) {
    error = AXUIElementCopyAttributeValue(extras, kAXVisibleChildrenAttribute,
                                          (CFTypeRef *)&children_ref);

    if (error == kAXErrorSuccess) {
      uint32_t count = CFArrayGetCount(children_ref);
      for (uint32_t i = 0; i < count; i++) {
        AXUIElementRef item = CFArrayGetValueAtIndex(children_ref, i);
        CFTypeRef position_ref = NULL;
        CFTypeRef size_ref = NULL;
        AXUIElementCopyAttributeValue(item, kAXPositionAttribute,
                                      &position_ref);
        AXUIElementCopyAttributeValue(item, kAXSizeAttribute, &size_ref);
        if (!position_ref || !size_ref)
          continue;

        CGPoint position = CGPointZero;
        AXValueGetValue(position_ref, kAXValueCGPointType, &position);
        CGSize size = CGSizeZero;
        AXValueGetValue(size_ref, kAXValueCGSizeType, &size);
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
    if (extras)
      CFRelease(extras);
  }

  CFRelease(app);
  return result;
}

void ax_select_menu_extra(char *alias) {
  AXUIElementRef item = ax_get_extra_menu_item(alias);
  if (!item)
    return;

  int cid = SLSMainConnectionID();
  SLSSetMenuBarVisibilityOverrideOnDisplay(cid, 0, false);
  SLSSetMenuBarInsetAndAlpha(cid, 0, 1, 1.0);

  ax_perform_click(item);
  usleep(1000000);

  if (g_menu_opacity == 0.0f) {
    for (int i = 0; i < 3; i++) {
      SLSSetMenuBarInsetAndAlpha(cid, 0, 1, 0.0);
      SLSSetMenuBarVisibilityOverrideOnDisplay(cid, 0, true);
      SLSSetMenuBarInsetAndAlpha(cid, 0, 1, 0.0);
      usleep(100000);
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
  if (fscanf(file, "%f", &opacity) == 1) {
    fclose(file);
    return opacity;
  }

  fclose(file);
  return 1.0f;
}

void write_opacity_state(float opacity) {
  FILE *file = fopen(STATE_FILE, "w");
  if (file) {
    fprintf(file, "%f", opacity);
    fclose(file);
  }
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
    usleep(100000); // Give system time to process
    SLSSetMenuBarInsetAndAlpha(cid, 0, 1, opacity);
  }

  write_opacity_state(opacity);
  printf("Menu bar opacity set to %.1f\n", opacity);
}

void toggle_menu_opacity() {
  float new_opacity = (g_menu_opacity == 0.0f) ? 1.0f : 0.0f;
  set_menu_opacity(new_opacity);
}

void run_daemon() {
  printf("Starting menu bar daemon...\n");
  printf("Use './menus -t' to toggle opacity\n");
  printf("Press Ctrl+C to stop daemon\n");

  signal(SIGINT, cleanup_and_exit);
  signal(SIGTERM, cleanup_and_exit);

  ax_init();

  g_menu_opacity = read_opacity_state();
  set_menu_opacity(g_menu_opacity); // Use the fixed function

  printf("Menu bar daemon running (opacity: %.1f)\n", g_menu_opacity);

  while (!g_should_exit) {
    sleep(2);

    // Check if state file has been updated by toggle command
    float current_state = read_opacity_state();
    if (current_state != g_menu_opacity) {
      g_menu_opacity = current_state;
      printf("Opacity changed to %.1f\n", g_menu_opacity);
    }

    // Only enforce hiding if opacity should be 0
    if (g_menu_opacity == 0.0f) {
      SLSSetMenuBarInsetAndAlpha(SLSMainConnectionID(), 0, 1, 0.0);
      SLSSetMenuBarVisibilityOverrideOnDisplay(SLSMainConnectionID(), 0, true);
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
    toggle_menu_opacity();
  } else if (strcmp(argv[1], "-l") == 0) {
    AXUIElementRef app = ax_get_front_app();
    if (!app)
      return 1;
    ax_print_menu_options(app);
    CFRelease(app);
  } else if (argc == 3 && strcmp(argv[1], "-s") == 0) {
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
  }

  return 0;
}
