return {
	"nvim-neo-tree/neo-tree.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	opts = {
		filesystem = {
			hijack_netrw_behavior = "disabled",
		},
	},
	keys = {
		{
			"<C-f>",
			"<cmd>Neotree toggle<cr>",
			desc = "[F]ile explorer",
		},
	},
}
-- vim: ts=2 sts=2 sw=2 et
