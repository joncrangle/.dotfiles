return {
  { -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help ibl`
    main = 'ibl',
    opts = {
      exclude = {
        filetypes = {
          'help',
          'dashboard',
          'Lazy',
          'Mason',
          'neogitstatus',
          'NvimTree',
          'neo-tree',
          'oil',
          'Trouble',
        },
        buftypes = {
          'nofile',
          'terminal',
        },
      },
    },
    show_trailing_blankline_indent = false,
    use_treesitter = true,
    show_current_context = true,
  },
}
-- vim: ts=2 sts=2 sw=2 et
