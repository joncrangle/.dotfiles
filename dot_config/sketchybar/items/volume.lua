local colors = require 'colors'
local settings = require 'settings'

local volume_slider = sbar.add('slider', 100, {
	position = 'right',
	updates = true,
	label = { drawing = false },
	icon = { drawing = false },
	slider = {
		highlight_color = colors.volume,
		width = 0,
		background = {
			height = 6,
			corner_radius = 3,
			color = colors.inactive_bg,
		},
		knob = {
			string = '􀀁',
			drawing = false,
		},
	},
	background = { padding_left = 0 },
})

local volume_percent = sbar.add('item', {
	position = 'right',
	icon = { drawing = false },
	label = {
		string = '??%',
		font = { family = settings.font.numbers, style = settings.font.style_map['Black'], size = 14.0 },
		color = colors.volume,
	},
	background = { padding_left = 0, padding_right = 0 },
})

local volume_icon = sbar.add('item', {
	position = 'right',
	icon = {
		string = '􀊩',
		width = 0,
		align = 'left',
		color = colors.inactive_fg,
		font = {
			style = 'Regular',
			size = 14.0,
		},
	},
	label = {
		width = 25,
		align = 'left',
		color = colors.volume,
		font = {
			style = 'Regular',
			size = 14.0,
		},
	},
	background = { padding_left = 0, padding_right = 0 },
})

sbar.add('bracket', {
	volume_icon.name,
	volume_percent.name,
	volume_slider.name,
}, {
	background = { color = colors.inactive_bg, height = 24, corner_radius = 10 },
})

volume_slider:subscribe('mouse.clicked', function(env)
	sbar.exec("osascript -e 'set volume output volume " .. env['PERCENTAGE'] .. "'")
end)

volume_slider:subscribe('volume_change', function(env)
	local volume = tonumber(env.INFO)
	local icon = '􀊣'
	if volume > 60 then
		icon = '􀊩'
	elseif volume > 30 then
		icon = '􀊧'
	elseif volume > 10 then
		icon = '􀊥'
	elseif volume > 0 then
		icon = '􀊡'
	end

	local lead = ""
	if volume < 10 then
		lead = "0"
	end

	volume_icon:set({ label = icon })
	volume_percent:set({ label = lead .. volume .. '%' })
	volume_slider:set({ slider = { percentage = volume } })
end)

local function animate_slider_width(width)
	sbar.animate('tanh', 30.0, function()
		volume_slider:set({ slider = { width = width } })
	end)
end

local function on_mouse_clicked()
	if tonumber(volume_slider:query().slider.width) > 0 then
		animate_slider_width(0)
	else
		animate_slider_width(100)
	end
end

volume_icon:subscribe('mouse.clicked', on_mouse_clicked)
volume_percent:subscribe('mouse.clicked', on_mouse_clicked)
