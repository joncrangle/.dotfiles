local colors = require 'colors'
local settings = require 'settings'
local app_icons = require 'helpers.app_icons'

local spaces = {}

for i = 1, 10, 1 do
  local space = sbar.add('space', 'space.' .. i, {
    space = i,
    icon = {
      font = { family = settings.font.numbers, style = settings.font.style_map['Black'] },
      string = i,
      padding_left = 6,
      padding_right = 4,
      color = colors.inactive_fg,
      highlight_color = colors.active_fg,
    },
    label = {
      padding_right = 12,
      color = colors.inactive_fg,
      highlight_color = colors.black,
      font = 'sketchybar-app-font:Regular:12.0',
      y_offset = -1,
    },
    background = {
      color = colors.inactive_bg,
      height = 24,
    },
  })

  spaces[i] = space

  space:subscribe('space_change', function(env)
    local selected = env.SELECTED == 'true'
    space:set {
      icon = { string = (selected and '' or '') .. ' ' .. i, highlight = selected },
      label = { highlight = selected },
      background = selected and { color = colors.active_bg } or { color = colors.inactive_bg },
    }
  end)

  space:subscribe('mouse.clicked', function(env)
    local op = (env.BUTTON == 'right') and '--destroy' or '--focus'
    sbar.exec('yabai -m space ' .. op .. ' ' .. env.SID)
  end)

  space:subscribe('mouse.exited', function()
    space:set { popup = { drawing = false } }
  end)
end

local space_window_observer = sbar.add('item', {
  drawing = false,
  updates = true,
})

space_window_observer:subscribe('space_windows_change', function(env)
  local icon_line = ''
  local no_app = true
  for app, _ in pairs(env.INFO.apps) do
    no_app = false
    local lookup = app_icons[app]
    local icon = ((lookup == nil) and app_icons['default'] or lookup)
    icon_line = icon_line .. ' ' .. icon
  end

  if no_app then
    icon_line = ' —'
  end
  sbar.animate('tanh', 10, function()
    spaces[env.INFO.space]:set { label = icon_line }
  end)
end)
