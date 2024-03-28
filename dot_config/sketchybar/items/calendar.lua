local settings = require 'settings'
local colors = require 'colors'

-- Padding item required because of bracket
sbar.add('item', { position = 'right', width = settings.group_paddings })

local cal = sbar.add('item', {
  icon = {
    color = colors.active_bg,
    padding_left = 8,
    font = {
      style = settings.font.style_map['Heavy'],
      size = 12.0,
    },
  },
  label = {
    color = colors.active_bg,
    padding_right = 8,
    width = 49,
    align = 'right',
    font = { family = settings.font.numbers, style = settings.font.style_map['Black'] },
  },
  position = 'right',
  update_freq = 30,
  padding_left = 1,
  padding_right = 1,
})

-- Double border for calendar using a single item bracket
sbar.add('bracket', { cal.name }, {
  background = {
    color = colors.transparent,
    height = 24,
  },
})

-- Padding item required because of bracket
sbar.add('item', { position = 'right', width = settings.group_paddings })

---@diagnostic disable-next-line: unused-local
cal:subscribe({ 'forced', 'routine', 'system_woke' }, function(env)
  cal:set { icon = os.date '%a. %d %b.', label = os.date '%H:%M' }
end)
