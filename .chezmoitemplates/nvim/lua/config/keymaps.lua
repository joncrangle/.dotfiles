-- Clear search on pressing <Esc> in normal mode
vim.keymap.set('n', '<Esc>', function()
  vim.schedule(function()
    vim.cmd.nohlsearch()
  end)
  local ok, hover = pcall(require, 'custom.hover')
  if ok and hover.dismiss then
    hover.dismiss()
  end
end, { silent = true })

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

vim.keymap.set('n', '<C-q>', '<cmd>tabclose<CR>', { desc = 'Close tab page' })

local function toggle_messages()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == 'messages' or vim.api.nvim_buf_get_name(buf):match '%[Messages%]$' then
      vim.api.nvim_win_close(win, true)
      return
    end
  end

  vim.cmd 'botright 12split'
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)
  pcall(vim.api.nvim_buf_set_name, buf, '[Messages]')
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'messages'

  local output = vim.api.nvim_exec2('messages', { output = true }).output
  local lines = vim.split(output, '\n', { trimempty = false })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  vim.keymap.set('n', 'q', '<cmd>close<CR>', { buffer = buf, silent = true })
  vim.keymap.set('n', '<Esc>', '<cmd>close<CR>', { buffer = buf, silent = true })
  vim.cmd 'normal! G'
end

vim.keymap.set('n', '<leader>m', toggle_messages, { desc = '[M]essages' })

-- Replace current word
vim.keymap.set('n', '<leader>rw', ':%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>', { desc = '[R]eplace current [w]ord' })

-- Keep cursor in place when joining lines, moving, or searching
vim.keymap.set('n', 'J', 'mzJ`z', { desc = 'Join lines' })
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Page down' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Page up' })
vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Next search result' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Previous search result' })

-- Paste and delete without yanking
vim.keymap.set('x', '<leader>p', '"_dP', { desc = 'Paste without yanking' })
vim.keymap.set('n', '<leader>d', '"_d', { desc = 'Delete without yanking' })
vim.keymap.set('v', '<leader>d', '"_d', { desc = 'Delete without yanking' })
vim.keymap.set('n', 'x', '"_x', { desc = 'Delete without yanking' })
vim.keymap.set('v', 'x', '"_x', { desc = 'Delete without yanking' })

-- In visual mode, move highlighted text up or down
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move highlighted text up' })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move highlighted text down' })

-- Toggle harper_ls spellcheck
local function toggle_harper_ls()
  local globally_enabled = vim.lsp.is_enabled 'harper_ls'
  if globally_enabled then
    vim.lsp.enable('harper_ls', false)
    vim.notify('harper_ls spellcheck disabled', vim.log.levels.INFO)
  else
    vim.lsp.enable('harper_ls', true)
    vim.notify('harper_ls spellcheck enabled', vim.log.levels.INFO)
  end
end

vim.keymap.set('n', '<leader>th', toggle_harper_ls, {
  desc = '[T]oggle [h]arper_ls spellcheck',
})

-- Toggle diagnostics
vim.keymap.set('n', '<leader>tD', function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = '[T]oggle [D]iagnostics' })

-- UI Toggles (<leader>u)
vim.keymap.set('n', '<leader>uw', function()
  vim.wo.wrap = not vim.wo.wrap
  vim.notify('Word wrap ' .. (vim.wo.wrap and 'enabled' or 'disabled'), vim.log.levels.INFO)
end, { desc = '[U]I Toggle [W]ord wrap' })

vim.keymap.set('n', '<leader>un', function()
  vim.wo.number = not vim.wo.number
  vim.notify('Line numbers ' .. (vim.wo.number and 'enabled' or 'disabled'), vim.log.levels.INFO)
end, { desc = '[U]I Toggle Line [N]umbers' })

vim.keymap.set('n', '<leader>ur', function()
  vim.wo.relativenumber = not vim.wo.relativenumber
  vim.notify('Relative numbers ' .. (vim.wo.relativenumber and 'enabled' or 'disabled'), vim.log.levels.INFO)
end, { desc = '[U]I Toggle [R]elative numbers' })

vim.keymap.set('n', '<leader>ud', function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
  vim.notify('Diagnostics ' .. (vim.diagnostic.is_enabled() and 'enabled' or 'disabled'), vim.log.levels.INFO)
end, { desc = '[U]I Toggle [D]iagnostics' })

vim.keymap.set('n', '<leader>uh', function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
  vim.notify('Inlay hints ' .. (vim.lsp.inlay_hint.is_enabled() and 'enabled' or 'disabled'), vim.log.levels.INFO)
end, { desc = '[U]I Toggle Inlay [H]ints' })

vim.keymap.set('n', '<leader>us', function()
  vim.wo.spell = not vim.wo.spell
  vim.notify('Spellcheck ' .. (vim.wo.spell and 'enabled' or 'disabled'), vim.log.levels.INFO)
end, { desc = '[U]I Toggle [S]pellcheck' })
-- vim: ts=2 sts=2 sw=2 et
