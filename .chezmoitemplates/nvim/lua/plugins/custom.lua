return {
  {
    'joncrangle/visual-lines.nvim',
    -- 'visual-lines.nvim',
    -- dev = true,
    ---@type VisualLineNumbersOptions
    -- opts = {},
  },
  {
    'joncrangle/itchy.nvim',
    -- 'itchy.nvim',
    -- dev = true,
    event = { 'BufReadPre', 'BufNewFile' },
    ---@type itchy.Opts
    opts = {
      -- debug_mode = true,
    },
    keys = {
      { '<leader>tD', mode = { 'n', 'v' }, '<cmd>Itchy run<cr>', desc = '[T]est [D]ebug' },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
