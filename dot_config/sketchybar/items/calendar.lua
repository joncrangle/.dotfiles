local settings = require 'settings'
local colors = require 'colors'

local cal = sbar.add('item', 'calendar', {
  icon = {
    color = colors.calendar,
    padding_left = 12,
    font = { style = settings.font.style_map['Bold'], size = 14.0 },
  },
  label = {
    color = colors.calendar,
    padding_right = 12,
    align = 'right',
    font = { family = settings.font.text, style = settings.font.style_map['Bold'], size = 14.0 },
  },
  position = 'center',
  background = {
    color = colors.inactive_bg,
    border_color = colors.calendar,
    corner_radius = 10,
    height = 24,
  },
  update_freq = 15,
})

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
