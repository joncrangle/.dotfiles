local colors = require 'colors'
local app_icons = require 'app_icons'

local whitelist = {
	['Spotify'] = true,
	['Music'] = true,
	['Podcasts'] = true
};

local media = sbar.add('item', {
	icon = {
		font = 'sketchybar-app-font:Regular:12.0',
		padding_left = 12,
		color = colors.media,
	},
	label = {
		padding_left = 2,
		padding_right = 12,
		color = colors.media,
	},
	position = 'center',
	updates = true,
	background = {
		color = colors.inactive_bg,
		corner_radius = 10,
		height = 24,
	},
})

media:subscribe('media_change', function(env)
	if whitelist[env.INFO.app] then
		local lookup = app_icons[env.INFO.app]
		local icon = ((lookup == nil) and app_icons['default'] or lookup)
		sbar.animate('tanh', 10, function()
			media:set({
				drawing = (env.INFO.state == 'playing') and true or false,
				icon = { string = icon },
				label = env.INFO.artist .. ': ' .. env.INFO.title
			})
		end)
	end
end)
