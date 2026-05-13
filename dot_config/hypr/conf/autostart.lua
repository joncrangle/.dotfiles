hl.on('hyprland.start', function()
  hl.exec_cmd '~/.config/hypr/scripts/xdg.sh'
  hl.exec_cmd '/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1'
  hl.exec_cmd 'systemctl --user enable ssh-agent.service'
  hl.exec_cmd 'qs -c noctalia-shell'

  -- Lock screen after everything starts
  hl.exec_cmd '~/.config/hypr/scripts/startup.sh'

  -- Startup apps
  hl.exec_cmd 'gsettings set org.gnome.desktop.interface cursor-theme catppuccin-mocha-dark-cursors'
  hl.exec_cmd 'vicinae server'
  hl.exec_cmd 'hypridle'
  hl.exec_cmd '[workspace 1 silent] wezterm'
  hl.exec_cmd '[workspace 2 silent] browser'
  hl.exec_cmd 'dropbox'

  -- Load cliphist history
  hl.exec_cmd 'wl-paste --type text --watch cliphist store'
  hl.exec_cmd 'wl-paste --type image --watch cliphist store'

  -- Environment for xdg-desktop-portal-hyprland
  hl.exec_cmd 'dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP'
  hl.exec_cmd 'systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP'
  hl.exec_cmd 'dbus-update-activation-environment --systemd --all'
end)
