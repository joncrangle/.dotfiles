---@diagnostic disable: undefined-global
return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true },
      dashboard = {
        enabled = true,
        preset = {
          keys = {
            { action = ':lua Snacks.dashboard.pick("files")', desc = ' Find File', icon = ' ', key = 'f' },
            { action = ':ene | startinsert', desc = ' New File', icon = ' ', key = 'n' },
            { action = ':lua Snacks.dashboard.pick("oldfiles")', desc = ' Recent Files', icon = ' ', key = 'r' },
            { action = ':lua Snacks.dashboard.pick("live_grep")', desc = ' Find Text', icon = ' ', key = 'g' },
            {
              action = ':lua Snacks.dashboard.pick("files", {cwd = vim.fn.stdpath("config")})',
              desc = ' Neovim Config',
              icon = ' ',
              key = 'v',
            },
            {
              action = ':lua Snacks.dashboard.pick("files", {cwd = "$XDG_CONFIG_HOME/wezterm" })',
              desc = ' Wezterm Config',
              icon = ' ',
              key = 'w',
            },
            {
              action = ':lua require("telescope").extensions.chezmoi.find_files()',
              desc = ' Chezmoi',
              icon = '',
              key = 'c',
            },
            { action = ':lua require("persistence").load()', desc = ' Restore Session', icon = ' ', key = 's' },
            { action = ':Lazy', desc = ' Lazy', icon = '󰒲 ', key = 'l' },
            { action = ':Mason', desc = ' Mason', icon = '󱊈 ', key = 'm' },
            {
              action = ':qa',
              desc = ' Quit',
              icon = ' ',
              key = 'q',
            },
          }
        },
      },
      lazygit = {
        configure = false
      },
      input = { enabled = true },
      notifier = { enabled = true },
      quickfile = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
      styles = {
        notification = {
          wo = { wrap = true, winblend = 0 }
        },
      },
    },
    keys = {
      { '<leader>un', function() Snacks.notifier.hide() end,           desc = 'Dismiss All Notifications' },
      { '<leader>bd', function() Snacks.bufdelete() end,               desc = 'Delete Buffer' },
      { '<leader>gg', function() Snacks.lazygit() end,                 desc = 'Lazygit' },
      { '<leader>gb', function() Snacks.git.blame_line() end,          desc = 'Git Blame Line' },
      { '<leader>gB', function() Snacks.gitbrowse() end,               desc = 'Git Browse' },
      { '<leader>gf', function() Snacks.lazygit.log_file() end,        desc = 'Lazygit Current File History' },
      { '<leader>gl', function() Snacks.lazygit.log() end,             desc = 'Lazygit Log (cwd)' },
      -- { '<leader>cR', function() Snacks.rename() end,                  desc = 'Rename File' }, -- NOTE: disabled until oil.nvim integration
      { ']]',         function() Snacks.words.jump(vim.v.count1) end,  desc = 'Next Reference' },
      { '[[',         function() Snacks.words.jump(-vim.v.count1) end, desc = 'Prev Reference' },
    },
    init = function()
      vim.api.nvim_create_autocmd('User', {
        pattern = 'SnacksDashboardOpened',
        callback = function(data)
          vim.b[data.buf].miniindentscope_disable = true
        end,
      })
      vim.api.nvim_create_autocmd('User', {
        pattern = 'VeryLazy',
        callback = function()
          -- Setup some globals for debugging (lazy-loaded)
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end
          vim.print = _G.dd -- Override print to use snacks for `:=` command
        end
      })
    end
  }
}
-- vim: ts=2 sts=2 sw=2 et
