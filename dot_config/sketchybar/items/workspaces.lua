local colors = require 'colors'
local settings = require 'settings'
local app_icons = require 'app_icons'
local item_order = ''
local focused_workspace = nil

local function update_workspace_icons(space, space_name)
  sbar.exec('aerospace list-windows --format %{app-name} --workspace ' .. space_name, function(windows)
    local icon_line = ''
    local no_app = true
    for app in windows:gmatch '[^\r\n]+' do
      no_app = false
      local lookup = app_icons[app]
      local icon = ((lookup == nil) and app_icons['default'] or lookup)
      icon_line = icon_line .. ' ' .. icon
    end
    if no_app then
      icon_line = ' —'
    end
    sbar.animate('tanh', 10, function()
      space:set { label = icon_line }
    end)
  end)
end

sbar.exec('aerospace list-workspaces --monitor all --empty no', function(spaces)
  -- Get the currently focused workspace first
  sbar.exec('aerospace list-workspaces --focused', function(focused_output)
    focused_workspace = focused_output:match '[^\r\n]+'

    for space_name in spaces:gmatch '[^\r\n]+' do
      local selected = focused_workspace == space_name
      local space_string = selected and '' .. ' ' .. space_name or '' .. ' ' .. space_name
      local space_color = {
        fg = selected and colors.crust or colors.text,
        bg = selected and colors.mauve or colors.surface0,
      }

      local space = sbar.add('item', 'space.' .. space_name, {
        icon = {
          font = { family = settings.font.numbers, style = settings.font.style_map['Black'] },
          string = space_string,
          padding_left = 6,
          padding_right = 4,
          color = space_color.fg,
        },
        label = {
          padding_right = 12,
          color = space_color.fg,
          font = 'sketchybar-app-font:Regular:12.0',
          highlight_color = colors.white,
          y_offset = -1,
        },
        background = {
          color = space_color.bg,
          corner_radius = 10,
          height = 24,
          padding_left = 4,
          padding_right = 4,
        },
      })

      update_workspace_icons(space, space_name)

      space:subscribe('aerospace_workspace_change', function(env)
        focused_workspace = env.FOCUSED
        selected = focused_workspace == space_name
        space_string = selected and '' .. ' ' .. space_name or '' .. ' ' .. space_name
        space_color = {
          fg = selected and colors.crust or colors.text,
          bg = selected and colors.mauve or colors.surface0,
        }
        space:set {
          icon = { string = space_string, color = space_color.fg },
          label = { color = space_color.fg },
          background = { color = space_color.bg },
        }
      end)

      space:subscribe('mouse.clicked', function()
        sbar.exec('aerospace workspace ' .. space_name)
      end)

      space:subscribe('mouse.exited', function()
        if focused_workspace == space_name then
          space:set { background = { color = colors.mauve } }
        else
          space:set { icon = { color = colors.text }, label = { color = colors.text }, background = { color = colors.surface0 } }
        end
      end)

      space:subscribe('mouse.entered', function()
        space:set { icon = { color = colors.crust }, label = { color = colors.crust }, background = { color = colors.pink } }
      end)

      space:subscribe('space_windows_change', function()
        update_workspace_icons(space, space_name)
      end)

      item_order = item_order .. ' ' .. space.name
    end
    sbar.exec('sketchybar --reorder apple_logo ' .. item_order .. ' front_app')
  end)
end)
