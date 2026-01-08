return {
  {
    'esmuellert/codediff.nvim',
    dependencies = { 'MunifTanjim/nui.nvim' },
    cmd = 'CodeDiff',
    keys = {
      { '<leader>gd', '<cmd>CodeDiff<cr>', desc = '[G]it [D]iff with CodeDiff' },
      {
        '<leader>gm',
        function()
          local file = vim.fn.expand '%:p'
          if file == '' then
            vim.notify('No file open', vim.log.levels.WARN)
            return
          end
          vim.cmd('CodeDiff merge ' .. vim.fn.fnameescape(file))
        end,
        desc = '[G]it [M]erge Conflict (current file)',
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
