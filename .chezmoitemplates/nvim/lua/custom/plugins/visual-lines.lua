local M = {}

local color = require('catppuccin.palettes').get_palette('mocha').yellow

local function setup_highlights()
  vim.api.nvim_set_hl(0, 'VisualLineNr', { fg = color, bg = 'NONE' })
end

setup_highlights()
vim.api.nvim_create_autocmd('ColorScheme', {
  callback = setup_highlights
})

local ns_id = vim.api.nvim_create_namespace('visual_line_numbers')

local function update_highlights()
  vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)

  if not vim.fn.mode():match('[vV\x16]') then
    return
  end

  local start_line = vim.fn.line('v')
  local end_line = vim.fn.line('.')

  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  for line = start_line, end_line do
    vim.api.nvim_buf_set_extmark(0, ns_id, line - 1, 0, {
      number_hl_group = 'VisualLineNr',
      priority = 10
    })
  end
end

local debounce_timer = nil
local function debounced_update()
  if debounce_timer then
    vim.fn.timer_stop(debounce_timer)
  end
  debounce_timer = vim.fn.timer_start(10, function()
    vim.schedule(update_highlights)
  end)
end

local group = vim.api.nvim_create_augroup('VisualLineNumbers', { clear = true })

vim.api.nvim_create_autocmd({ 'ModeChanged', 'CursorMoved', 'TextChanged', 'TextChangedI' }, {
  group = group,
  callback = debounced_update
})

vim.api.nvim_create_autocmd({ 'BufLeave', 'ModeChanged' }, {
  group = group,
  pattern = { '*', '[vV\x16]*:*' },
  callback = function()
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
  end
})

return M
-- vim: ts=2 sts=2 sw=2 et
