local colors = require 'colors'
local settings = require 'settings'

-- Disk
local disk = sbar.add('alias', 'Stats,Disk_mini', {
	position = 'right',
	icon = { drawing = false },
	label = {
		font = { family = settings.font.numbers, style = settings.font.style_map['Black'], size = 14.0 },
		width = 0,
	},
	padding_left = 0,
	padding_right = 0,
})

disk:subscribe('mouse.clicked', function()
	sbar.exec('open -a "/System/Applications/Utilities/Activity Monitor.app"')
end)

-- RAM
local ram = sbar.add('alias', 'Stats,RAM_mini', {
	position = 'right',
	icon = { drawing = false },
	label = {
		font = { family = settings.font.numbers, style = settings.font.style_map['Black'], size = 14.0 },
		width = 0,
	},
	padding_left = 0,
	padding_right = 0,
})

ram:subscribe('mouse.clicked', function()
	sbar.exec('open -a "/System/Applications/Utilities/Activity Monitor.app"')
end)

-- CPU
local cpu = sbar.add('alias', 'Stats,CPU_mini', {
	position = 'right',
	icon = { drawing = false },
	label = {
		font = { family = settings.font.numbers, style = settings.font.style_map['Black'], size = 14.0 },
		width = 0,
	},
	padding_left = 0,
	padding_right = 0,
})

cpu:subscribe('mouse.clicked', function()
	sbar.exec('open -a "/System/Applications/Utilities/Activity Monitor.app"')
end)

-- Container
sbar.add('bracket', 'stats', {
	cpu.name,
	ram.name,
	disk.name,
}, {
	background = { color = colors.inactive_bg, height = 24, corner_radius = 10 },
})
