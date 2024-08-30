local colors = require 'colors'
local settings = require 'settings'
local app_icons = require 'app_icons'

local spaces = {}

for i = 1, 10, 1 do
  local space = sbar.add('space', 'space.' .. i, {
    space = i,
    icon = {
      font = { family = settings.font.numbers, style = settings.font.style_map['Black'] },
      string = i,
      padding_left = 6,
      padding_right = 4,
      color = colors.text,
    },
    label = {
      padding_right = 12,
      color = colors.text,
      font = 'sketchybar-app-font:Regular:12.0',
      y_offset = -1,
    },
    background = {
      color = colors.surface0,
      corner_radius = 10,
      height = 24,
      padding_left = 4,
      padding_right = 4,
    },
  })

  spaces[i] = space

  space:subscribe('space_change', function(env)
    if env.SELECTED == 'true' then
      space:set {
        icon = { string = '' .. ' ' .. i, color = colors.crust },
        label = { color = colors.crust },
        background = { color = colors.mauve }
      }
    else
      space:set {
        icon = { string = '' .. ' ' .. i, color = colors.text },
        label = { color = colors.text },
        background = { color = colors.surface0 },
      }
    end
  end)

  space:subscribe('mouse.clicked', function(env)
    local op = (env.BUTTON == 'right') and '--destroy' or '--focus'
    sbar.exec('yabai -m space ' .. op .. ' ' .. env.SID)
  end)

  space:subscribe('mouse.exited', function(env)
    if env.SELECTED == 'true' then
      space:set { background = { color = colors.mauve } }
    else
      space:set { icon = { color = colors.text }, label = { color = colors.text }, background = { color = colors.surface0 } }
    end
  end)

  space:subscribe('mouse.entered', function()
    space:set { icon = { color = colors.crust }, label = { color = colors.crust }, background = { color = colors.pink } }
  end)
end

local space_window_observer = sbar.add('item', 'space_window_observer', {
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
