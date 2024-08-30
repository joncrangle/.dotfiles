local colors = require 'colors'

local front_app = sbar.add('item', 'front_app', {
  icon = {
    drawing = false
  },
  label = {
    font = {
      size = 14.0,
    }
  }
})

front_app:subscribe('front_app_switched', function(env)
  front_app:set({
    label = {
      string = env.INFO,
      color = colors.mauve
    }
  })
end)
