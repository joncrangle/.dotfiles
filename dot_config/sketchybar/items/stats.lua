local colors = require 'colors'
local settings = require 'settings'

-- Execute the event provider binary which provides the event "system_stats" for
-- the cpu, ram, and disk data, which is fired every 5 seconds.
sbar.exec [[
  $CONFIG_DIR/sketchybar-system-stats/target/release/stats_provider \
    --cpu usage temperature \
    --disk usage \
    --memory ram_usage &
]]

local items = {
  { name = 'cpu_temp', icon = '', env = 'CPU_TEMP' },
  { name = 'disk_usage', icon = '󰋊', env = 'DISK_USAGE' },
  { name = 'ram_usage', icon = '', env = 'RAM_USAGE' },
  { name = 'cpu_usage', icon = '󰻠', env = 'CPU_USAGE' },
}

local item_names = {}

for _, item in ipairs(items) do
  local item_name = item.name
  local item_env = item.env

  local created_item = sbar.add('item', item_name, {
    position = 'right',
    icon = {
      string = item.icon,
      font = { family = settings.font.numbers, style = settings.font.style_map['Bold'], size = 14.0 },
      color = colors.pink,
      padding_right = 0,
    },
    label = {
      font = { family = settings.font.text, style = settings.font.style_map['Bold'], size = 14.0 },
      color = colors.pink,
    },
    padding_left = 3,
    padding_right = 3,
  })

  created_item:subscribe('system_stats', function(env)
    created_item:set { label = env[item_env] }
  end)
  created_item:subscribe('mouse.clicked', function()
    sbar.exec 'open -a "/System/Applications/Utilities/Activity Monitor.app"'
  end)

  table.insert(item_names, item_name)
end

local stats = sbar.add('bracket', 'stats', item_names, {
  background = { color = colors.surface0, border_color = colors.pink, height = 24, corner_radius = 10 },
})

local function on_mouse_entered()
  stats:set { background = { border_width = 1 } }
end
local function on_mouse_exited()
  stats:set { background = { border_width = 0 } }
end

stats:subscribe('mouse.entered', on_mouse_entered)
stats:subscribe('mouse.exited', on_mouse_exited)
