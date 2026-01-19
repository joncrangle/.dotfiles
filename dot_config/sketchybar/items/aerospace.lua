local colors = require 'colors'
local settings = require 'settings'
local app_icons = require 'app_icons'

local workspaces = {}

-- Config
local config = {
  ignore_empty = true,
}

local function get_icon(app_name)
  return app_icons[app_name] or app_icons['default']
end

local function ensure_workspace_item(name)
  if workspaces[name] then
    return workspaces[name]
  end

  local space_id = 'workspace.' .. name
  local space = sbar.add('item', space_id, {
    icon = {
      font = { family = settings.font.numbers, style = settings.font.style_map['Black'] },
      padding_left = 12,
      padding_right = 0,
      color = colors.text,
      string = name,
    },
    label = {
      font = 'sketchybar-app-font:Regular:12.0',
      padding_right = 12,
      y_offset = -1,
      color = colors.text,
      string = '—',
    },
    background = {
      color = colors.surface0,
      corner_radius = 10,
      height = 20,
      padding_left = 4,
      padding_right = 0,
    },
    click_script = 'aerospace workspace ' .. name,
    drawing = false,
  })

  workspaces[name] = space

  -- Order after 'apple_logo' and before 'front_app'
  sbar.exec('sketchybar --reorder ' .. space_id .. ' front_app')

  space:subscribe('mouse.entered', function(env)
    space:set {
      icon = { color = colors.crust },
      label = { color = colors.crust },
      background = { color = colors.pink },
    }
  end)

  space:subscribe('mouse.exited', function(env)
    sbar.trigger 'update_windows'
  end)

  return space
end

local window_observer = sbar.add('item', 'window_observer', {
  drawing = false,
  updates = true,
})

local current_order = ''

local function update_windows()
  sbar.exec("aerospace list-windows --all --format '%{workspace}|%{app-name}'", function(window_list)
    local apps_by_space = {}

    for line in window_list:gmatch '[^\r\n]+' do
      local workspace, app = line:match '^(.-)|(.*)$'
      if workspace and app then
        apps_by_space[workspace] = apps_by_space[workspace] or {}
        table.insert(apps_by_space[workspace], app)
      end
    end

    sbar.exec('aerospace list-workspaces --focused', function(focused_name)
      focused_name = focused_name:match '[^\r\n]+'

      local all_visible_spaces = {}
      if focused_name then
        all_visible_spaces[focused_name] = true
      end
      for name, _ in pairs(apps_by_space) do
        all_visible_spaces[name] = true
      end

      local sorted_spaces = {}
      for name, _ in pairs(all_visible_spaces) do
        table.insert(sorted_spaces, name)
      end
      table.sort(sorted_spaces, function(a, b)
        -- Try numeric sort first
        local an, bn = tonumber(a), tonumber(b)
        if an and bn then
          return an < bn
        end
        return a < b
      end)

      for _, name in ipairs(sorted_spaces) do
        ensure_workspace_item(name)
      end

      if #sorted_spaces > 0 then
        local desired_order = table.concat(sorted_spaces, '|')
        if desired_order ~= current_order then
          current_order = desired_order

          local order_cmd = 'sketchybar --reorder'
          for _, name in ipairs(sorted_spaces) do
            order_cmd = order_cmd .. ' workspace.' .. name
          end
          order_cmd = order_cmd .. ' front_app'
          sbar.exec(order_cmd)
        end
      end

      for name, item in pairs(workspaces) do
        local apps = apps_by_space[name]
        local is_focused = (name == focused_name)
        local should_draw = (apps ~= nil) or is_focused

        if config.ignore_empty and not should_draw then
          item:set { drawing = false }
        else
          local icon_str = ' —'
          if apps then
            icon_str = ''
            for _, app in ipairs(apps) do
              icon_str = icon_str .. ' ' .. get_icon(app)
            end
          end

          if is_focused then
            item:set {
              icon = { string = name, color = colors.crust },
              label = { string = icon_str, color = colors.crust },
              background = { color = colors.mauve, border_color = colors.text },
              drawing = true,
            }
          else
            item:set {
              icon = { string = name, color = colors.text },
              label = { string = icon_str, color = colors.text },
              background = { color = colors.surface1, border_color = colors.black },
              drawing = true,
            }
          end
        end
      end
    end)
  end)
end

window_observer:subscribe('front_app_switched', update_windows)
window_observer:subscribe('space_windows_change', update_windows)
window_observer:subscribe('aerospace_workspace_change', update_windows)
window_observer:subscribe('update_windows', update_windows)

update_windows()
