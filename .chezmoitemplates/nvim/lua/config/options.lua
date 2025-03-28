vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.g.loaded_matchit = 1
vim.opt.showmode = false
vim.opt.termguicolors = true
vim.opt.laststatus = 3 -- Global statusline
vim.opt.wrap = false -- Don't wrap lines
vim.opt.virtualedit = 'block' -- Enable virtual edit in block mode

-- Sync clipboard between OS and Neovim.
-- Function to set OSC 52 clipboard
local function set_osc52_clipboard()
  local function my_paste()
    local content = vim.fn.getreg '"'
    return vim.split(content, '\n')
  end

  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy '+',
      ['*'] = require('vim.ui.clipboard.osc52').copy '*',
    },
    paste = {
      ['+'] = my_paste,
      ['*'] = my_paste,
    },
  }
end

-- Check if the current session is a remote WezTerm session based on the WezTerm executable
local function check_wezterm_remote_clipboard(callback)
  local wezterm_executable = vim.uv.os_getenv 'WEZTERM_EXECUTABLE'

  if wezterm_executable and wezterm_executable:find('wezterm-mux-server', 1, true) then
    callback(true) -- Remote WezTerm session found
  else
    callback(false) -- No remote WezTerm session
  end
end

-- Schedule the setting after `UiEnter` because it can increase startup-time.
vim.schedule(function()
  vim.opt.clipboard:append 'unnamedplus'

  -- Standard SSH session handling
  if vim.uv.os_getenv 'SSH_CLIENT' ~= nil or vim.uv.os_getenv 'SSH_TTY' ~= nil then
    set_osc52_clipboard()
  else
    check_wezterm_remote_clipboard(function(is_remote_wezterm)
      if is_remote_wezterm then
        set_osc52_clipboard()
      end
    end)
  end
end)

vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.list = true
vim.opt.fillchars = {
  foldopen = '',
  foldclose = '',
  fold = ' ',
  foldsep = ' ',
  diff = '╱',
  eob = ' ',
}
vim.opt.foldlevel = 99
vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
vim.opt.foldmethod = 'expr'
vim.opt.foldtext = ''

-- Preview substitutions live while typing
vim.opt.inccommand = 'split'

vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.smoothscroll = true

-- Tab spacing
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.shiftround = true
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Don't highlight search results, but highlight incremental search
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.opt.incsearch = true

-- Set diagnostic configuration
vim.diagnostic.config {
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = vim.diagnostic.severity.ERROR },
  signs = vim.g.have_nerd_font and {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚 ',
      [vim.diagnostic.severity.WARN] = '󰀪 ',
      [vim.diagnostic.severity.INFO] = '󰋽 ',
      [vim.diagnostic.severity.HINT] = '󰌶 ',
    },
  } or {},
  virtual_text = { current_line = true },
}
-- vim: ts=2 sts=2 sw=2 et
