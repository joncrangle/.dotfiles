local settings = require 'settings'
local colors = require 'colors'

local popup_toggle = 'sketchybar --set $NAME popup.drawing=toggle'
local added_calendar_items = false

-- Spacer to balance the media item on the right
sbar.add('item', 'media.spacer', {
  position = 'center',
  width = 0,
  icon = { drawing = false },
  label = { drawing = false },
  background = { drawing = false },
})

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
      size = 14.0,
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

local function update_calendar_items()
  local stdout = io.popen('cal', 'r')
  if not stdout then
    return ''
  end
  local month = stdout:read '*all'
  stdout:close()

  local lines = {}
  for line in month:gmatch '[^\n]+' do
    if line:match '%S' then
      table.insert(lines, line)
    end
  end

  local function format_line(line)
    local current_day = tonumber(os.date '%e') or 0
    -- Highlight the current day by adding `|` around it
    return line:gsub('(%s*)(%d+)(%s*)', function(before, day, after)
      local num = tonumber(day)
      if num == current_day then
        return before:sub(2) .. '|' .. day .. '|' .. after:sub(2)
      elseif current_day - 1 == num then
        return before .. day .. after:sub(2)
      elseif current_day + 1 == num then
        return before:sub(2) .. day .. after
      end
      return before .. day .. after
    end)
  end

  for idx, line in ipairs(lines) do
    local item_name = 'cal_month_line_' .. idx
    if not added_calendar_items then
      sbar.add('item', item_name, {
        position = 'popup.' .. cal.name,
        icon = { drawing = false },
        width = 180,
        label = {
          string = format_line(line),
          color = idx == 1 and colors.peach or idx == 2 and colors.flamingo or colors.maroon,
          font = {
            family = settings.font.text,
            style = settings.font.style_map['Bold'],
            size = idx == 1 and 16.0 or 14.0,
          },
        },
      })
    else
      sbar.set(item_name, {
        label = {
          string = format_line(line),
        },
      })
    end
  end
  added_calendar_items = true
end

update_calendar_items()

local function update_time()
  local date = os.date '%a. %d %b.'
  local time = tostring(os.date '%I:%M %p'):gsub('^0', '')
  cal:set { icon = date, label = time }
end

cal:subscribe('routine', function()
  update_time()
  update_calendar_items()
end)

cal:subscribe('forced', function()
  update_time()
  update_calendar_items()
end)

cal:subscribe('mouse.entered', function()
  cal:set { background = { border_width = 1 } }
end)
cal:subscribe('mouse.exited', function()
  cal:set { background = { border_width = 0 } }
end)
