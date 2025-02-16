return {
  {
    'visual-lines',
    event = { 'BufReadPre', 'BufNewFile' },
    dev = true,
    ---@type VisualLineNumbersOptions
    opts = {},
  }
}
-- vim: ts=2 sts=2 sw=2 et
