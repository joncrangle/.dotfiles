local colors = require 'colors'

local popup_toggle = 'sketchybar --set $NAME popup.drawing=toggle'

local apple_logo = sbar.add('item', 'apple_logo', {
	click_script = popup_toggle,
	icon = {
		string = '􀣺',
		font = {
			size = 16.0,
		},
		color = colors.active_bg,
	},
	label = { drawing = false },
	popup = { height = 35 }
})

local apple_prefs = sbar.add('item', 'apple_prefs', {
	position = 'popup.' .. apple_logo.name,
	icon = '􀺽',
	label = 'System Settings',
})

apple_prefs:subscribe('mouse.clicked', function(_)
	sbar.exec("open -a 'System Preferences'")
	apple_logo:set({ popup = { drawing = false } })
end)
