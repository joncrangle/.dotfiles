local colors = require 'colors'
local settings = require 'settings'

local front_app = sbar.add('item', 'front_app', {
  display = 'active',
  icon = { drawing = false },
  padding_left = settings.paddings * 2,
  label = {
    font = {
      style = settings.font.style_map['Heavy'],
      size = 12.0,
    },
    color = colors.active_bg,
  },
  updates = true,
})

front_app:subscribe('front_app_switched', function(env)
  front_app:set { label = { string = env.INFO } }
end)

---@diagnostic disable-next-line: unused-local
front_app:subscribe('mouse.clicked', function(env)
  sbar.trigger 'swap_menus_and_spaces'
end)
