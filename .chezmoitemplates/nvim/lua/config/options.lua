vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.g.loaded_matchit = 1
vim.o.showmode = false
vim.o.ruler = false
vim.o.cmdheight = 0
vim.o.report = 9999
vim.o.termguicolors = true
vim.o.laststatus = 3 -- Global statusline
vim.o.wrap = false -- Don't wrap lines
vim.o.virtualedit = 'block' -- Enable virtual edit in block mode
vim.o.autoread = true -- Auto reload files changed outside of Neovim
vim.o.winbar = ' '
vim.o.winborder = 'rounded'
vim.o.shada = "'100,<50,s10,:1000,/100,@100,h" -- Limit ShaDa file (for startup)

require 'custom.tabline'
require('custom.my_todo').setup()
require('custom.hover').setup()
require('custom.cmdline').setup()

-- TODO(compat): neotest-golang plenary.scandir shim (remove once neotest-golang migrates to vim.fs)
local function fallback_scandir()
  return {
    scan_dir = function(folderpath, opts)
      opts = opts or {}
      local root = vim.fs.normalize(vim.fn.fnamemodify(folderpath, ':p'))
      local pattern = opts.search_pattern
      local results = {}
      local ignored = {}
      local use_gitignore = opts.respect_gitignore and vim.fn.executable 'git' == 1

      local function is_ignored(path)
        if not use_gitignore then
          return false
        end
        if ignored[path] ~= nil then
          return ignored[path]
        end

        local relative = vim.fs.relpath(root, path)
        if not relative then
          return false
        end
        local result = vim.system({ 'git', '-C', root, 'check-ignore', '--quiet', '--no-index', '--', relative }):wait()
        ignored[path] = result.code == 0
        return ignored[path]
      end

      local function scan(dir)
        local handle = vim.uv.fs_scandir(dir)
        if not handle then
          return
        end
        while true do
          local name, type = vim.uv.fs_scandir_next(handle)
          if not name then
            break
          end
          if name ~= '.git' and name ~= 'node_modules' then
            local full_path = vim.fs.joinpath(dir, name)
            if not is_ignored(full_path) then
              if type == 'directory' then
                if opts.add_dirs and (not pattern or name:match(pattern)) then
                  table.insert(results, full_path)
                end
                scan(full_path)
              elseif type == 'file' and (not pattern or name:match(pattern)) then
                table.insert(results, full_path)
              end
            end
          end
        end
      end

      scan(root)
      return results
    end,
  }
end

local plenary_scandir_shim
plenary_scandir_shim = function()
  -- Let a real Plenary module win if a later-loaded plugin provides one.
  local shim = package.preload['plenary.scandir']
  package.preload['plenary.scandir'] = nil
  local ok, scandir = pcall(require, 'plenary.scandir')
  package.preload['plenary.scandir'] = shim
  return ok and scandir or fallback_scandir()
end
package.preload['plenary.scandir'] = plenary_scandir_shim

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

  local env = vim.uv.os_getenv
  local is_ssh = env 'SSH_CLIENT' ~= nil or env 'SSH_TTY' ~= nil
  local is_herdr = env 'HERDR_ENV' ~= nil

  check_wezterm_remote_clipboard(function(is_remote_wezterm)
    if is_ssh and not is_herdr then
      set_osc52_clipboard()
    elseif is_remote_wezterm and not is_herdr then
      set_osc52_clipboard()
    end
  end)
end)

vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.o.timeoutlen = 300

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.list = true
vim.opt.fillchars = {
  foldopen = '',
  foldclose = '',
  fold = ' ',
  foldsep = ' ',
  diff = '╱',
  eob = ' ',
}
vim.o.foldlevel = 99
vim.o.foldtext = ''
vim.o.foldmethod = 'expr'
-- Default to treesitter folding
vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
-- Prefer LSP folding if client supports it
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method 'textDocument/foldingRange' then
      vim.wo.foldexpr = 'v:lua.vim.lsp.foldexpr()'
    end
  end,
})

-- Preview substitutions live while typing
vim.o.inccommand = 'split'

vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.smoothscroll = true

-- Tab spacing
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.shiftround = true
vim.o.expandtab = true
vim.o.breakindent = true

-- Keep search matches visible while entering `/` or `?`. Normal-mode <Esc>
-- still clears the current highlighting through the keymap in keymaps.lua.
vim.o.incsearch = true
vim.o.hlsearch = true

vim.api.nvim_create_autocmd('CmdlineEnter', {
  pattern = { '/', '?' },
  callback = function()
    if vim.o.hlsearch and vim.v.hlsearch == 0 then
      -- `:nohlsearch` and the `shada` h flag can leave v:hlsearch at zero while
      -- &hlsearch remains enabled. Re-enable it on search entry.
      vim.v.hlsearch = 1
    end
  end,
})

-- Set diagnostic configuration
vim.diagnostic.config {
  severity_sort = true,
  float = {
    border = 'rounded',
  },
  signs = vim.g.have_nerd_font and {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚 ',
      [vim.diagnostic.severity.WARN] = '󰀪 ',
      [vim.diagnostic.severity.INFO] = '󰋽 ',
      [vim.diagnostic.severity.HINT] = '󰌶 ',
    },
  } or {},
  virtual_text = false,
}

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Close some filetypes with <q>
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('close-with-q', { clear = true }),
  pattern = {
    'checkhealth',
    'dbout',
    'grug-far',
    'help',
    'lspinfo',
    'neotest-output',
    'neotest-output-panel',
    'neotest-summary',
    'notify',
    'qf',
    'startuptime',
    'tsplayground',
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set('n', 'q', function()
        vim.cmd 'close'
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, {
        buffer = event.buf,
        silent = true,
        desc = 'Quit buffer',
      })
    end)
  end,
})

-- Show cursor line only in active window
-- credit @folke https://github.com/folke/dot/blob/master/nvim/lua/config/autocmds.lua
vim.api.nvim_create_autocmd({ 'InsertLeave', 'WinEnter' }, {
  callback = function()
    if vim.w.auto_cursorline then
      vim.wo.cursorline = true
      vim.w.auto_cursorline = nil
    end
    -- Reset line number highlights to normal
    vim.wo.winhighlight = nil
  end,
})

vim.api.nvim_create_autocmd({ 'WinLeave' }, {
  callback = function()
    if vim.wo.cursorline then
      vim.w.auto_cursorline = true
      vim.wo.cursorline = false
    end
    -- Dim line numbers in inactive windows
    vim.wo.winhighlight = 'LineNr:LineNrInactive,LineNrAbove:LineNrInactive,LineNrBelow:LineNrInactive'
  end,
})
-- vim: ts=2 sts=2 sw=2 et
