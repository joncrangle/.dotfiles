local settings = require 'settings'
local colors = require 'colors'

local cal = sbar.add('item', {
  icon = {
    color = colors.active_bg,
    font = {
      style = settings.font.style_map['Heavy'],
      size = 14.0,
    },
  },
  label = {
    color = colors.hover_bg,
    align = 'right',
    font = { family = settings.font.numbers, style = settings.font.style_map['Black'], size = 14.0 },
  },
  position = 'right',
  update_freq = 15,
})

local function update()
  local date = os.date('%a. %d %b.')
  local time = os.date('%I:%M %p'):gsub('^0', '')
  cal:set({ icon = date, label = time })
end

cal:subscribe('routine', update)
cal:subscribe('forced', update)
