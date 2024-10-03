local settings = require 'settings'
local colors = require 'colors'

-- Equivalent to the --default domain
sbar.default {
  updates = 'when_shown',
  icon = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map['Regular'],
      size = 14.0,
    },
    padding_left = settings.paddings,
    padding_right = settings.paddings,
  },
  label = {
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map['Semibold'],
      size = 14.0
    },
    padding_left = settings.paddings,
    padding_right = settings.paddings,
  },
  popup = {
    background = {
      border_width = 2,
      corner_radius = 9,
      border_color = colors.mauve,
      color = colors.crust,
      shadow = { drawing = true },
    },
    blur_radius = 20,
  },
  padding_left = 10,
  padding_right = 10,
}
