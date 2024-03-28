local settings = require 'settings'
local colors = require 'colors'

-- Equivalent to the --default domain
sbar.default {
  updates = 'when_shown',
  icon = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map['Regular'],
      size = 12.0,
    },
    color = colors.white,
    padding_left = settings.paddings,
    padding_right = settings.paddings,
  },
  scroll_texts = true,
}
