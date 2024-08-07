return {
  -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    init = function()
      -- Load the colorscheme here.
      -- Like many other themes, this one has different styles, and you could load
      -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
      vim.cmd.colorscheme 'catppuccin-mocha'
    end,
    opts = {
      flavour = 'mocha',
      transparent_background = true,
      integrations = {
        aerial = true,
        alpha = true,
        cmp = true,
        dashboard = true,
        flash = true,
        grug_far = true,
        gitsigns = true,
        headlines = true,
        illuminate = true,
        indent_blankline = { enabled = true },
        leap = true,
        lsp_trouble = true,
        mason = true,
        markdown = true,
        mini = {
          enabled = true,
          indentscope_color = 'lavender',
        },
      },
      native_lsp = {
        enabled = true,
        underlines = {
          errors = { "undercurl" },
          hints = { "undercurl" },
          warnings = { "undercurl" },
          information = { "undercurl" },
        },
      },
      navic = { enabled = true, custom_bg = "lualine" },
      neotest = true,
      neotree = true,
      noice = true,
      telescope = true,
      treesitter = true,
      treesitter_context = true,
      which_key = true,
      highlight_overrides = {
        mocha = function(mocha)
          return {
            LineNrAbove = { fg = mocha.overlay1 },
            LineNrBelow = { fg = mocha.overlay1 },
            CursorLineNr = { fg = mocha.rosewater },
          }
        end,
      },
    },
  },
  {
    'brenoprata10/nvim-highlight-colors',
    lazy = true,
    event = 'BufReadPost',
    opts = {
      enable_tailwind = true,
    },
  },
  {
    "scottmckendry/cyberdream.nvim",
    priority = 1000,
    -- init = function()
    --   vim.cmd.colorscheme 'cyberdream'
    -- end,
    opts = {
      transparent = true,
    },
  },
  {
    'rebelot/kanagawa.nvim',
    priority = 1000,
    -- init = function()
    --   vim.cmd.colorscheme 'kanagawa-wave'
    -- end,
    opts = {
      transparent = true,
    },
  },
  {
    'folke/tokyonight.nvim',
    priority = 1000,
    -- init = function()
    --   vim.cmd.colorscheme 'tokyonight-night'
    -- end,
    opts = {
      transparent = true,
      styles = {
        sidebars = 'transparent',
        floats = 'transparent',
      },
    },
  },
  {
    'EdenEast/nightfox.nvim',
    priority = 1000,
    -- init = function()
    --   vim.cmd.colorscheme 'nightfox'
    -- end,
    opts = {
      transparent = false,
    },
  },
  {
    'rose-pine/neovim',
    name = "rose-pine",
    priority = 1000,
    -- init = function()
    --   vim.cmd.colorscheme 'rose-pine'
    -- end,
    opts = {
      transparent = true,
    },
  },
  {
    "Mofiqul/dracula.nvim",
    priority = 1000,
    -- init = function()
    --   vim.cmd.colorscheme 'dracula'
    -- end,
    opts = {
      transparent = true,
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
