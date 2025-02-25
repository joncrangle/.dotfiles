return {
  ---@module 'grapple'
  {
    'cbochs/grapple.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = { 'echasnovski/mini.nvim' },
    ---@type grapple.options
    opts = {
      scope = 'cwd',
      icons = true,
      tag_title = function()
        return 'Grapple Tags'
      end,
      win_opts = {
        width = 60,
        height = 12,
        border = 'rounded',
      },
    },
    config = function(_, opts)
      local wk = require 'which-key'
      local grapple = require 'grapple'

      local keys = {}
      for i = 1, 9 do
        table.insert(keys, {
          '<leader>' .. i,
          '<cmd>Grapple select index=' .. i .. '<cr>',
          desc = 'Grapple tag ' .. i,
          hidden = true,
        })
      end
      -- stylua: ignore
      wk.add({
        { '<leader>#', desc = 'Grapple tag item [1-9]' },
        { '<leader>h', function() grapple.toggle() end,      desc = 'Grapple a file' },
        { '<leader>H', function() grapple.toggle_tags() end, desc = 'Toggle Grapple menu' },
        keys,
      })
      grapple.setup(opts)
    end,
  },
  {
    'mrjones2014/smart-splits.nvim',
    lazy = false,
    keys = function()
      local smart_splits = require 'smart-splits'
      -- stylua: ignore
      local keys = {
        { '<A-h>', smart_splits.resize_left,       { desc = 'Resize split left' } },
        { '<A-j>', smart_splits.resize_down,       { desc = 'Resize split down' } },
        { '<A-k>', smart_splits.resize_up,         { desc = 'Resize split up' } },
        { '<A-l>', smart_splits.resize_right,      { desc = 'Resize split right' } },
        { '<C-h>', smart_splits.move_cursor_left,  { desc = 'Move to left split' } },
        { '<C-j>', smart_splits.move_cursor_down,  { desc = 'Move to below split' } },
        { '<C-k>', smart_splits.move_cursor_up,    { desc = 'Move to above split' } },
        { '<C-l>', smart_splits.move_cursor_right, { desc = 'Move to right split' } },
      }
      return keys
    end,
  },
  {
    'folke/persistence.nvim',
    event = 'BufReadPre',
    opts = { options = vim.opt.sessionoptions:get() },
    keys = function()
      local wk = require 'which-key'
      -- stylua: ignore
      wk.add({
        { '<leader>p', group = '[P]ersistent Sessions', icon = { icon = '', color = 'yellow' } },
        { '<leader>ps', function() require('persistence').load() end, desc = 'Restore Session' },
        { '<leader>pl', function() require('persistence').load { last = true } end, desc = 'Restore Last Session' },
        { '<leader>pd', function() require('persistence').stop() end, desc = "Don't Save Current Session" },
      })
    end,
  },
  ---@module 'snacks'
  ---@module 'oil'
  {
    'stevearc/oil.nvim',
    cmd = 'Oil',
    init = function()
      vim.api.nvim_create_autocmd('User', {
        pattern = 'OilActionsPost',
        callback = function(event)
          if event.data.actions.type == 'move' then
            Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
          end
        end,
      })
    end,
    ---@type oil.Config|{}
    opts = {
      default_file_explorer = false,
      keymaps = {
        ['<C-f>'] = 'actions.preview_scroll_down',
        ['<C-b>'] = 'actions.preview_scroll_up',
        ['q'] = { 'actions.close', mode = 'n' },
      },
      ---@type oil.FloatWindowConfig|{}
      float = { max_width = 0.85, max_height = 0.85 },
      skip_confirm_for_simple_edits = true,
      ---@type oil.ViewOptions|{}
      view_options = {
        show_hidden = true,
        natural_order = true,
        is_always_hidden = function(name, _)
          return name == '.git' or name == '.jj'
        end,
      },
      win_options = {
        wrap = true,
      },
    },
    keys = {
      {
        '<leader>-',
        '<cmd>Oil --float<cr>',
        desc = 'Open parent directory in oil.nvim',
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
