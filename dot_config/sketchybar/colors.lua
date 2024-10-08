return {
	rosewater = 0xfff5e0dc, -- #f5e0dc
	flamingo = 0xfff2cdcd, -- #f2cdcd
	pink = 0xfff5c2e7,     -- #f5c2e7
	mauve = 0xffcba6f7,    -- #cba6f7
	red = 0xfff38ba8,      -- #f38ba8
	maroon = 0xffeba0ac,   -- #eba0ac
	peach = 0xfffab387,    -- #fab387
	yellow = 0xfff9e2af,   -- #f9e2af
	green = 0xffa6e3a1,    -- #a6e3a1
	teal = 0xff94e2d5,     -- #94e2d5
	sky = 0xff89dceb,      -- #89dceb
	sapphire = 0xff74c7ec, -- #74c7ec
	blue = 0xff89b4fa,     -- #89b4fa
	lavender = 0xffb4befe, -- #b4befe
	text = 0xffcdd6f4,     -- #cdd6f4
	subtext1 = 0xffbac2c7, -- #bac2c7
	subtext0 = 0xffa6adc8, -- #a6adc8
	overlay2 = 0xff9399b2, -- #9399b2
	overlay1 = 0xff7f849c, -- #7f849c
	overlay0 = 0xff6c7086, -- #6c7086
	surface2 = 0xff585b70, -- #585b70
	surface1 = 0xff45475a, -- #45475a
	surface0 = 0xcc313244, -- #313244
	base = 0xff1e1e2e,     -- #1e1e2e
	mantle = 0xff181825,   -- #181825
	crust = 0xff11111b,    -- #11111b
	crust_alpha = 0x0011111b, -- #11111b

	with_alpha = function(color, alpha)
		if alpha > 1.0 or alpha < 0.0 then
			return color
		end
		return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
	end,
}
