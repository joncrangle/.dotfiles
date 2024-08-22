local colors = require 'colors'
local app_icons = require 'app_icons'

local whitelist = {
	['Spotify'] = true,
	['Music'] = true,
	['Podcasts'] = true,
	['VLC'] = true,
	['IINA'] = true,
	['Arc'] = true
};

local media = sbar.add('item', 'media', {
	icon = {
		font = 'sketchybar-app-font:Regular:12.0',
		color = colors.media,
	},
	label = {
		font = 'IosevkaTerm Nerd Font:Regular:14.0',
		width = 20,
		padding_right = 12,
		color = colors.media,
		background = {
			color = colors.inactive_bg,
			corner_radius = 10,
			height = 24,
		}
	},
	position = 'center',
	updates = true,
	background = {
		color = colors.inactive_bg,
		corner_radius = 10,
		height = 24,
	},
	width = 24,
})

local function animate_media_width(width)
	sbar.animate('tanh', 30.0, function()
		media:set({ label = { width = width } })
	end)
end

media:subscribe('mouse.entered', function()
	local text = media:query().label.value
	animate_media_width(#text * 7)
end)
media:subscribe('mouse.exited', function()
	animate_media_width(20)
end)
media:subscribe('mouse.clicked', function(env)
	sbar.exec('shortcuts run "playpause"')
end)

media:subscribe('media_change', function(env)
	if whitelist[env.INFO.app] then
		local lookup = app_icons[env.INFO.app]
		local icon = ((lookup == nil) and app_icons['default'] or lookup)

		local playback_icon = ((env.INFO.state == 'playing') and '' or '')

		local artist = (env.INFO.artist ~= "" and env.INFO.artist) or "Unknown Artist"
		local title = (env.INFO.title ~= "" and env.INFO.title) or "Unknown Title"
		local label = playback_icon .. ' ' .. artist .. ': ' .. title

		sbar.animate('tanh', 10, function()
			media:set({
				icon = { string = icon },
				label = label
			})
		end)
	end
end)
