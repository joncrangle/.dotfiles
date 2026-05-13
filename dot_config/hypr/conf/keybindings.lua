local SUPER = 'SUPER'
local SHIFT = 'SHIFT'
local ALT = 'ALT'
local CTRL = 'CTRL'

local mainMod = SUPER

local function combo(...)
  return table.concat({ ... }, ' + ')
end

local function bind(mods, key, dispatcher, flags)
  local keys = key

  if mods ~= nil and mods ~= '' then
    keys = combo(mods, key)
  end

  if type(dispatcher) == 'string' then
    dispatcher = hl.dsp.exec_cmd(dispatcher)
  end

  hl.bind(keys, dispatcher, flags)
end

-- Applications
bind(mainMod, 'RETURN', 'wezterm')
bind(mainMod, 'B', 'zen-browser')
bind(mainMod, 'E', 'thunar')
bind(mainMod, 'Y', 'wezterm -e zsh -c "yazi"')
bind(mainMod, 'EQUAL', 'qalculate-gtk')
bind(combo(mainMod, SHIFT), 'C', 'hyprpicker -a')

-- Windows
bind(mainMod, 'Q', hl.dsp.window.close()) -- Kill active window
bind(mainMod, 'F', hl.dsp.window.fullscreen { action = 'toggle' }) -- Set active window to fullscreen
bind(combo(mainMod, SHIFT), 'T', function()
  hl.dispatch(hl.dsp.window.float { action = 'toggle' })
  hl.dispatch(hl.dsp.window.center())
end) -- Toggle floating mode
bind(mainMod, 'S', hl.dsp.layout 'togglesplit')
bind(mainMod, 'h', hl.dsp.focus { direction = 'left' })
bind(mainMod, 'l', hl.dsp.focus { direction = 'right' })
bind(mainMod, 'k', hl.dsp.focus { direction = 'up' })
bind(mainMod, 'j', hl.dsp.focus { direction = 'down' })
bind(combo(mainMod, SHIFT), 'h', hl.dsp.window.move { direction = 'left' })
bind(combo(mainMod, SHIFT), 'l', hl.dsp.window.move { direction = 'right' })
bind(combo(mainMod, SHIFT), 'k', hl.dsp.window.move { direction = 'up' })
bind(combo(mainMod, SHIFT), 'j', hl.dsp.window.move { direction = 'down' })
bind(mainMod, 'G', hl.dsp.group.toggle()) -- Toggle window group
bind(ALT, 'TAB', hl.dsp.group.next()) -- Tab between windows
bind(mainMod, 'mouse:272', hl.dsp.window.drag(), { mouse = true })
bind(mainMod, 'mouse:273', hl.dsp.window.resize(), { mouse = true })

-- Resize submap
bind(ALT, 'R', hl.dsp.submap 'resize')
hl.define_submap('resize', function()
  hl.bind('l', hl.dsp.window.resize { x = 10, y = 0, relative = true }, { repeating = true })
  hl.bind('h', hl.dsp.window.resize { x = -10, y = 0, relative = true }, { repeating = true })
  hl.bind('k', hl.dsp.window.resize { x = 0, y = 10, relative = true }, { repeating = true })
  hl.bind('j', hl.dsp.window.resize { x = 10, y = -10, relative = true }, { repeating = true })
  hl.bind('escape', hl.dsp.submap 'reset')
end)

-- Actions
bind(combo(mainMod, CTRL), 'Q', 'qs -c noctalia-shell ipc call sessionMenu toggle') -- Toggle power menu
bind(mainMod, 'APOSTROPHE', 'qs -c noctalia-shell ipc call controlCenter toggle') -- Toggle control center
bind(mainMod, 'SLASH', 'qs -c noctalia-shell ipc call settings toggle') -- Toggle settings menu
bind(mainMod, 'SPACE', 'vicinae toggle') -- Toggle launcher
bind(combo(mainMod, SHIFT), 'R', 'hyprctl reload') -- Reload hyprland config
bind('', 'Print', 'grimblast copysave screen') -- Screenshot
bind(SHIFT, 'Print', 'grimblast copysave area') -- Screenshot an area
bind(mainMod, 'Print', 'grimblast copysave window') -- Screenshot a window
bind(combo(mainMod, CTRL), 'L', 'qs -c noctalia-shell ipc call lockScreen lock') -- Lock screen
bind(combo(mainMod, SHIFT), 'N', 'qs -c noctalia-shell ipc call notifications toggleHistory') -- Open notification history
bind(mainMod, 'R', 'qs -c noctalia-shell ipc call screenRecorder toggle') -- Toggle screen recording

-- Workspaces
for i = 1, 10 do
  local key = i % 10
  bind(mainMod, key, hl.dsp.focus { workspace = i })
  bind(combo(mainMod, SHIFT), key, hl.dsp.window.move { workspace = i, follow = false })
end
bind(mainMod, 'mouse:272', hl.dsp.focus { workspace = 'e+1' })
bind(mainMod, 'mouse:273', hl.dsp.focus { workspace = 'e-1' })
bind(combo(mainMod, CTRL), 'down', hl.dsp.focus { workspace = 'empty' }) -- Open next empty workspace

-- Fn keys
bind('', 'XF86MonBrightnessUp', 'brightnessctl -q s +10%') -- Increase brightness
bind('', 'XF86MonBrightnessDown', 'brightnessctl -q s 10%-') -- Reduce brightness
bind('', 'XF86AudioRaiseVolume', 'wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+') -- Increase volume
bind('', 'XF86AudioLowerVolume', 'wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-') -- Reduce volume
bind('', 'XF86AudioMute', 'wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle') -- Toggle mute
bind('', 'XF86AudioPlay', 'playerctl play-pause') -- Audio play pause
bind('', 'XF86AudioPause', 'playerctl pause') -- Audio pause
bind('', 'XF86AudioNext', 'playerctl next') -- Audio next
bind('', 'XF86AudioPrev', 'playerctl previous') -- Audio previous
bind('', 'XF86AudioMicMute', 'pactl set-source-mute @DEFAULT_SOURCE@ toggle') -- Toggle microphone
bind('', 'XF86Calculator', 'qalculate-gtk') -- Open calculator
bind('', 'XF86Launch4', 'qs -c noctalia-shell ipc call screenRecorder toggle') -- Toggle screen recording
