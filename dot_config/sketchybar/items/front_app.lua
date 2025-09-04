local colors = require 'colors'
local settings = require 'settings'

local front_app = sbar.add('item', 'front_app', {
  icon = {
    background = {
      drawing = true,
    },
  },
  label = {
    font = {
      size = 14.0,
    },
  },
  padding_left = 10,
})

front_app:subscribe('front_app_switched', function(env)
  front_app:set {
    label = {
      string = env.INFO,
      color = colors.mauve,
    },
    icon = {
      background = { image = { string = 'app.' .. env.INFO, scale = 0.8 } },
    },
  }
end)
