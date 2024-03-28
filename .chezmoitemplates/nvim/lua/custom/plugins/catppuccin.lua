return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		init = function()
			---@diagnostic disable-next-line: undefined-global
			vim.cmd.colorscheme("catppuccin-mocha")
		end,
		opts = {
			flavour = "mocha",
			transparent_background = true,
		},
	},
}
-- vim: ts=2 sts=2 sw=2 et
