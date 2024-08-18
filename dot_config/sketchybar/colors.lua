return {
	bg = 0x0011111b,       -- #11111b
	popup_bg = 0xff11111b, -- #11111b
	active_fg = 0xff11111b, -- #11111b
	active_bg = 0xffcba6f7, -- #cba6f7
	inactive_fg = 0xffcdd6f4, -- #cdd6f4
	inactive_bg = 0xcc313244, -- #313244
	hover_bg = 0xfff5c2e7, -- #f5c2e7
	white = 0xffcdd6f4,    -- #cdd6f4

	with_alpha = function(color, alpha)
		if alpha > 1.0 or alpha < 0.0 then
			return color
		end
		return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
	end,
}
