local colors = require 'colors'
local settings = require 'settings'

-- Execute the event provider binary which provides the event "system_stats" for
-- the cpu, ram, and disk data, which is fired every 5 seconds.
sbar.exec(
	'killall stats_provider >/dev/null; $CONFIG_DIR/sketchybar-system-stats/target/release/stats_provider --cpu usage --disk usage --memory usage')

-- Disk
local disk = sbar.add('item', 'disk', {
	position = 'right',
	icon = {
		string = '',
		font = { family = settings.font.numbers, style = settings.font.style_map['Bold'], size = 14.0 },
		color = colors.stats,
		padding_right = 0
	},
	label = {
		font = { family = settings.font.text, style = settings.font.style_map['Bold'], size = 14.0 },
		color = colors.stats,
	},
	padding_left = 3,
	padding_right = 10,
})

disk:subscribe('system_stats', function(env)
	disk:set { label = env.DISK_USAGE }
end)
disk:subscribe('mouse.clicked', function()
	sbar.exec('open -a "/System/Applications/Utilities/Activity Monitor.app"')
end)

-- Memory
local memory = sbar.add('item', 'memory', {
	position = 'right',
	icon = {
		string = '',
		font = { family = settings.font.numbers, style = settings.font.style_map['Bold'], size = 14.0 },
		color = colors.stats,
		padding_right = 0
	},
	label = {
		font = { family = settings.font.text, style = settings.font.style_map['Bold'], size = 14.0 },
		color = colors.stats,
	},
	padding_left = 3,
	padding_right = 3,
})

memory:subscribe('system_stats', function(env)
	memory:set { label = env.MEMORY_USAGE }
end)
memory:subscribe('mouse.clicked', function()
	sbar.exec('open -a "/System/Applications/Utilities/Activity Monitor.app"')
end)

-- CPU
local cpu = sbar.add('item', 'cpu', {
	position = 'right',
	icon = {
		string = '󰍛',
		font = { family = settings.font.numbers, style = settings.font.style_map['Bold'], size = 14.0 },
		color = colors.stats,
		padding_right = 0
	},
	label = {
		font = { family = settings.font.text, style = settings.font.style_map['Bold'], size = 14.0 },
		color = colors.stats,
	},
	padding_left = 10,
	padding_right = 3,
})

cpu:subscribe('system_stats', function(env)
	cpu:set { label = env.CPU_USAGE }
end)
cpu:subscribe('mouse.clicked', function()
	sbar.exec('open -a "/System/Applications/Utilities/Activity Monitor.app"')
end)

-- Container
local stats = sbar.add('bracket', 'stats', {
	cpu.name,
	memory.name,
	disk.name,
}, {
	background = { color = colors.inactive_bg, border_color = colors.stats, height = 24, corner_radius = 10 },
})

local function on_mouse_entered()
	stats:set({ background = { border_width = 1 } })
end
local function on_mouse_exited()
	stats:set({ background = { border_width = 0 } })
end

stats:subscribe('mouse.entered', on_mouse_entered)
stats:subscribe('mouse.exited', on_mouse_exited)
