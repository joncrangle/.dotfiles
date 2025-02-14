return {
  ---@module 'quicker'
  {
    'stevearc/quicker.nvim',
    lazy = true,
    opts = {
      keys = {
        {
          ">",
          function()
            require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
          end,
          desc = "Expand quickfix context",
        },
        {
          "<",
          function()
            require("quicker").collapse()
          end,
          desc = "Collapse quickfix context",
        },
      },
    },
    keys = {
      {
        '<leader>q',
        function()
          require('quicker').toggle()
        end,
        desc = 'Toggle [Q]uicker',
        mode = 'n',
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
