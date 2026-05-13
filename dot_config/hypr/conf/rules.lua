-- Browsers - tile
hl.window_rule { match = { class = 'Microsoft-edge' }, tile = true }
hl.window_rule { match = { class = 'Brave-browser' }, tile = true }
hl.window_rule { match = { class = 'Chromium' }, tile = true }

-- System utilities - float
hl.window_rule { match = { class = 'pavucontrol' }, float = true }
hl.window_rule { match = { class = 'blueman-manager' }, float = true }
hl.window_rule { match = { class = 'nm-connection-editor' }, float = true }
hl.window_rule { match = { class = 'qalculate-gtk' }, float = true }
hl.window_rule { match = { class = 'kvantummanager' }, float = true }
hl.window_rule { match = { class = 'org.gnome.Settings' }, float = true }
hl.window_rule { match = { class = 'nwg-look' }, float = true }

-- Media apps - workspace 5 silent
hl.window_rule { match = { title = 'Spotify.*' }, workspace = '5 silent' }
hl.window_rule { match = { title = 'Plexamp' }, workspace = '5 silent' }

-- Browser Picture in Picture
hl.window_rule { match = { title = 'Picture-in-Picture' }, float = true, pin = true, move = { '69.5%', '4%' } }

hl.layer_rule {
  name = 'vicinae',
  match = { namespace = 'vicinae' },
  blur = true,
  no_anim = true,
  ignore_alpha = 0,
}

hl.layer_rule {
  name = 'noctalia',
  match = { namespace = 'noctalia-background-.*' },
  ignore_alpha = 0.5,
  blur = true,
  blur_popups = true,
}
