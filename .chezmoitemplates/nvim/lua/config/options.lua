vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.g.loaded_matchit = 1
vim.opt.showmode = false
-- Global statusline
vim.opt.laststatus = 3
-- Don't wrap lines
vim.opt.wrap = false
-- Enable virtual edit in block mode
vim.opt.virtualedit = 'block'

-- Sync clipboard between OS and Neovim.
-- Function to set OSC 52 clipboard
local function set_osc52_clipboard()
  local function my_paste(_)
    return function()
      local content = vim.fn.getreg '"'
      return vim.split(content, '\n')
    end
  end

  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy '+',
      ['*'] = require('vim.ui.clipboard.osc52').copy '*',
    },
    paste = {
      ['+'] = my_paste('+'),
      ['*'] = my_paste('*'),
    },
  }
end

-- Function to check for "via proxy pid" asynchronously
local function check_wezterm_remote_clipboard(callback)
  if vim.fn.executable('wezterm') == 0 then
    callback(false) -- wezterm CLI not in PATH
    return
  end

  -- Run wezterm CLI asynchronously
  vim.fn.jobstart({ 'wezterm', 'cli', 'list-clients', '--format', 'json' }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      local success, clients = pcall(vim.json.decode, table.concat(data, '\n'))
      if success and type(clients) == 'table' then
        for _, client in ipairs(clients) do
          if client.hostname and client.hostname:find("via proxy pid") then
            callback(true)
            return
          end
        end
      end
      callback(false)
    end,
    on_stderr = function()
      callback(false) -- Error occurred
    end,
  })
end

-- Schedule the setting after `UiEnter` because it can increase startup-time.
vim.schedule(function()
  vim.opt.clipboard:append 'unnamedplus'

  -- Standard SSH session handling
  if os.getenv('SSH_CLIENT') ~= nil or os.getenv('SSH_TTY') ~= nil then
    set_osc52_clipboard()
  else
    -- Check for WezTerm remote session asynchronously
    check_wezterm_remote_clipboard(function(is_remote_wezterm)
      if is_remote_wezterm then
        set_osc52_clipboard()
      end
    end)
  end
end)

vim.opt.breakindent = true
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

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = false
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live while typing
vim.opt.inccommand = 'split'

vim.opt.cursorline = true
vim.opt.scrolloff = 10

-- Tab spacing
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Don't highlight search results, but highlight incremental search
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.opt.incsearch = true
-- vim: ts=2 sts=2 sw=2 et
