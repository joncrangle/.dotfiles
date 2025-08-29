local colors = require 'colors'
local settings = require 'settings'
local app_icons = require 'app_icons'

local workspaces = {}
local focused_workspace = nil
local previous_workspace = nil

local function update_workspace_icons(space_name)
  sbar.exec('aerospace list-windows --format "%{app-name}" --json --workspace ' .. space_name, function(windows)
    local icon_line = ''
    local no_app = true
    for _, app in ipairs(windows) do
      no_app = false
      local lookup = app_icons[app['app-name']]
      local icon = ((lookup == nil) and app_icons['default'] or lookup)
      icon_line = icon_line .. ' ' .. icon
    end
    if no_app then
      icon_line = ' —'
      workspaces[space_name]:set { icon = { drawing = false }, label = { drawing = false } }
    else
      sbar.animate('tanh', 10, function()
        workspaces[space_name]:set { label = { string = icon_line, drawing = true }, icon = { drawing = true } }
      end)
    end
  end)
end

local function move_pip_to_current_workspace()
  if not focused_workspace then
    return
  end

  sbar.exec('aerospace list-windows --format "%{window-id}%{app-name}%{window-title}" --json --all', function(windows)
    for _, window in ipairs(windows) do
      local app_name = window['app-name']
      local window_id = window['window-id']
      local window_title = window['window-title']

      if app_name == 'Zen' and window_title == 'Picture-in-Picture' then
        if window_id and window_id ~= '' then
          sbar.exec('aerospace move-node-to-workspace --window-id ' .. window_id .. ' ' .. focused_workspace)
        end
      end
    end
  end)
end

sbar.exec('aerospace list-workspaces --monitor all --format "%{workspace}%{monitor-appkit-nsscreen-screens-id}" --json', function(spaces)
  local last_workspace = nil

  for _, entry in ipairs(spaces) do
    local space_name = entry.workspace
    local monitor_id = entry['monitor-appkit-nsscreen-screens-id']
    last_workspace = space_name

    local space = sbar.add('item', 'space.' .. space_name, {
      display = monitor_id,
      icon = {
        font = { family = settings.font.numbers, style = settings.font.style_map['Black'] },
        string = ' ' .. space_name,
        padding_left = 6,
        padding_right = 0,
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
        padding_left = 6,
        padding_right = 0,
      },
    })

    update_workspace_icons(space_name)

    workspaces[space_name] = space

    space:subscribe('front_app_switched', function()
      if previous_workspace ~= space_name or focused_workspace ~= space_name then
        update_workspace_icons(space_name)
      end
    end)

    space:subscribe('aerospace_workspace_change', function(env)
      focused_workspace = env.FOCUSED
      previous_workspace = env.PREVIOUS

      move_pip_to_current_workspace()

      if focused_workspace == space_name then
        space:set {
          icon = { string = space_name, color = colors.crust },
          label = { color = colors.crust },
          background = { color = colors.mauve },
        }
      else
        space:set {
          icon = { string = space_name, color = colors.text },
          label = { color = colors.text },
          background = { color = colors.surface0 },
        }
      end
      if previous_workspace == space_name or focused_workspace == space_name then
        update_workspace_icons(space_name)
      end
    end)

    space:subscribe('mouse.clicked', function()
      sbar.exec('aerospace workspace ' .. space_name)
    end)

    space:subscribe('mouse.exited', function()
      if focused_workspace == space_name then
        space:set { background = { color = colors.mauve } }
      else
        space:set {
          icon = { color = colors.text },
          label = { color = colors.text },
          background = { color = colors.surface0 },
        }
      end
    end)

    space:subscribe('mouse.entered', function()
      space:set {
        icon = { color = colors.crust },
        label = { color = colors.crust },
        background = { color = colors.pink },
      }
    end)
  end
  sbar.exec('sketchybar --reorder space.' .. last_workspace .. ' front_app')
end)
