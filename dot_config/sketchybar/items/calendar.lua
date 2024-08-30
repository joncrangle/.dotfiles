local settings = require 'settings'
local colors = require 'colors'

local popup_toggle = 'sketchybar --set $NAME popup.drawing=toggle'

local cal = sbar.add('item', 'calendar', {
  click_script = popup_toggle,
  icon = {
    color = colors.peach,
    padding_left = 12,
    font = { style = settings.font.style_map['Bold'], size = 14.0 },
  },
  label = {
    color = colors.peach,
    padding_right = 12,
    align = 'right',
    font = {
      family = settings.font.text,
      style = settings.font.style_map['Bold'],
      size = 14.0
    },
  },
  position = 'center',
  popup = {
    background = { border_color = colors.peach, color = colors.surface0 },
  },
  background = {
    color = colors.surface0,
    border_color = colors.peach,
    corner_radius = 10,
    height = 24,
  },
  update_freq = 15,
})

local stdout = io.popen('cal', 'r')
if not stdout then
  return ''
end
local month = stdout:read('*all')
stdout:close()

local lines = {}
local i = 1
for line in month:gmatch('[^\n]+') do
  if line:match("%S") then
    table.insert(lines, line)
  end
  i = i + 1
end

local function format_line(line)
  local current_day = tonumber(os.date('%e')) or 0
  -- Highlight the current day by adding `|` around it
  return line:gsub('(%s)(%d+)(%s)', function(before, day, after)
    local num = tonumber(day)
    if num == current_day then
      -- Remove spaces around the current day number
      return before:match('%s') and '|' .. day .. '|' or '|' .. day .. '|' .. after
    else
      return before .. day .. after
    end
  end)
end

for idx, line in ipairs(lines) do
  local item_name = 'cal_month_line_' .. idx
  sbar.add('item', item_name, {
    position = 'popup.' .. cal.name,
    icon = { drawing = false },
    width = 180,
    label = {
      string = format_line(line),
      color = idx == 1 and colors.peach or
          idx == 2 and colors.flamingo or
          colors.maroon,
      font = {
        family = settings.font.text,
        style = settings.font.style_map['Bold'],
        size = idx == 1 and 16.0 or 14.0
      },
    },
  })
end

local function update()
  local date = os.date('%a. %d %b.')
  local time = tostring(os.date('%I:%M %p')):gsub('^0', '')
  cal:set({ icon = date, label = time })
end

cal:subscribe('routine', update)
cal:subscribe('forced', update)

cal:subscribe('mouse.entered', function()
  cal:set({ background = { border_width = 1 } })
end)
cal:subscribe('mouse.exited', function()
  cal:set({ background = { border_width = 0 } })
end)
