local colors = require 'colors'
local settings = require 'settings'

sbar.exec '$CONFIG_DIR/menus/menus -d &'

local apple_logo = sbar.add('item', 'apple_logo', {
  icon = {
    string = '􀣺',
    font = { size = 16.0 },
    color = colors.blue,
  },
  label = {
    font = { family = settings.font.text, style = settings.font.style_map['Bold'], size = 14.0 },
    color = colors.peach,
  },
  click_script = '$CONFIG_DIR/menus/menus -s 0',
})

apple_logo:subscribe('svim_update', function(env)
  local mode_color
  local cmdline = ''
  if env['MODE'] == 'I' then
    mode_color = colors.green
  elseif env['MODE'] == 'V' then
    mode_color = colors.mauve
  elseif env['MODE'] == 'C' then
    mode_color = colors.peach
    cmdline = env['CMDLINE']
  elseif env['MODE'] == 'R' then
    mode_color = colors.red
  else
    mode_color = colors.blue
  end
  apple_logo:set { icon = { color = mode_color }, label = cmdline }
end)
