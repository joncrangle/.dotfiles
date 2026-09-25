hl.on('hyprland.start', function()
  -- 1. Essential environment exports (must run before portals/apps)
  hl.exec_cmd 'dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP'
  hl.exec_cmd 'systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP'
  hl.exec_cmd '~/.config/hypr/scripts/xdg.sh'

  -- 2. Core system daemons & UI
  hl.exec_cmd '/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1'
  hl.exec_cmd 'noctalia'
  hl.exec_cmd 'hypridle'

  -- 3. Lock screen on startup
  hl.exec_cmd '~/.config/hypr/scripts/startup.sh'

  -- 4. Look & feel
  hl.exec_cmd 'gsettings set org.gnome.desktop.interface cursor-theme catppuccin-mocha-dark-cursors'
  hl.exec_cmd 'gsettings set org.gnome.desktop.interface color-scheme prefer-dark'

  -- 5. Background utilities
  hl.exec_cmd 'vicinae server'
  hl.exec_cmd 'dropbox'
  hl.exec_cmd 'wl-paste --type text --watch cliphist store'
  hl.exec_cmd 'wl-paste --type image --watch cliphist store'

  -- 6. Workspace applications
  hl.exec_cmd '[workspace 1 silent] wezterm'
  hl.exec_cmd '[workspace 2 silent] browser'
end)
