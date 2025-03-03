local wezterm_dir = vim.fn.expand '$XDG_CONFIG_HOME' .. '/wezterm'
return {
  ---@module 'snacks'
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      bigfile = {},
      ---@type snacks.dashboard.Config|{}
      dashboard = {
        enabled = true,
        preset = {
          -- stylua: ignore
          keys = {
            { action = ':lua Snacks.dashboard.pick("smart")',                                   desc = ' Find File',       icon = ' ', key = 'f' },
            { action = ':ene | startinsert',                                                    desc = ' New File',        icon = ' ', key = 'n' },
            { action = ':lua Snacks.dashboard.pick("oldfiles")',                                desc = ' Recent Files',    icon = ' ', key = 'r' },
            { action = ':lua Snacks.dashboard.pick("live_grep")',                               desc = ' Find Text',       icon = ' ', key = 'g' },
            { action = ':lua Snacks.dashboard.pick("files", {cwd = vim.fn.stdpath("config")})', desc = ' Neovim Config',   icon = ' ', key = 'v' },
            { action = ':lua Snacks.dashboard.pick("files", {cwd = "' .. wezterm_dir .. '"})',  desc = ' Wezterm Config',  icon = ' ', key = 'w' },
            { action = ':lua require("persistence").load()',                                    desc = ' Restore Session', icon = ' ', key = 's' },
            { action = ':Lazy',                                                                 desc = ' Lazy',            icon = '󰒲 ', key = 'l' },
            { action = ':Mason',                                                                desc = ' Mason',           icon = '󱊈 ', key = 'm' },
            { action = ':qa',                                                                   desc = ' Quit',            icon = ' ', key = 'q' },
          },
        },
      },
      ---@type snacks.explorer.Config
      explorer = { replace_netrw = true },
      ---@type snacks.image.Config|{}
      image = { doc = { inline = false } },
      ---@type snacks.indent.Config
      indent = { indent = { only_scope = true } },
      input = {},
      ---@type snacks.lazygit.Config
      lazygit = { configure = false },
      notifier = {},
      ---@type snacks.picker.Config
      picker = {
        sources = {
          explorer = { auto_close = true },
        },
      },
      quickfile = {},
      statuscolumn = {},
      words = {},
      ---@type table<string, snacks.win.Config>
      styles = {
        notification = {
          relative = 'editor',
          wo = { wrap = true, winblend = 0 },
        },
      },
    },
    -- stylua: ignore
    keys = {
      { '<leader>nd',       function() Snacks.notifier.hide() end,                                                         desc = 'Dismiss All Notifications' },
      { '<leader>bd',       function() Snacks.bufdelete() end,                                                             desc = 'Delete Buffer' },
      { '<leader>gg',       function() Snacks.lazygit() end,                                                               desc = 'Lazygit' },
      { '<leader>gb',       function() Snacks.git.blame_line() end,                                                        desc = 'Git Blame Line' },
      { '<leader>gB',       function() Snacks.gitbrowse() end,                                                             desc = 'Git Browse' },
      { '<leader>gf',       function() Snacks.lazygit.log_file() end,                                                      desc = 'Lazygit Current File History' },
      { '<leader>gl',       function() Snacks.lazygit.log() end,                                                           desc = 'Lazygit Log (cwd)' },
      { ']]',               function() Snacks.words.jump(vim.v.count1) end,                                                desc = 'Next Reference' },
      { '[[',               function() Snacks.words.jump(-vim.v.count1) end,                                               desc = 'Prev Reference' },
      { '<leader>.',        function() Snacks.scratch() end,                                                               desc = 'Toggle Scratch Buffer' },
      { '<leader>y',        function() Snacks.terminal('yazi', { win = { style = 'lazygit' } }) end,                       desc = 'Open [Y]azi' },
      -- Pickers
      { '-',                function() Snacks.explorer({ hidden = true }) end,                                             desc = 'File Explorer' },
      { '<leader><leader>', function() Snacks.picker.buffers() end,                                                        desc = '[ ] Find existing buffers' },
      { '<leader>/',        function() Snacks.picker.lines() end,                                                          desc = '[/] Search in current Buffer' },
      { '<leader>sf',       function() Snacks.picker.smart() end,                                                          desc = '[S]earch [F]iles' },
      { '<leader>sF',       function() Snacks.picker.files({ hidden = true }) end,                                         desc = '[S]earch All [F]iles' },
      { '<leader>sg',       function() Snacks.picker.grep() end,                                                           desc = '[S]earch by [G]rep' },
      { '<leader>\\',       function() Snacks.picker.grep_buffers() end,                                                   desc = '[\\] Search in open Buffers' },
      { '<leader>s.',       function() Snacks.picker.recent() end,                                                         desc = '[S]earch Recent Files' },
      { '<leader>s"',       function() Snacks.picker.registers() end,                                                      desc = '[S]earch Registers' },
      { '<leader>sa',       function() Snacks.picker.autocmds() end,                                                       desc = '[S]earch Auto Commands' },
      { '<leader>sc',       function() Snacks.picker.command_history() end,                                                desc = '[S]earch [C]ommand History' },
      { '<leader>sC',       function() Snacks.picker.commands() end,                                                       desc = '[S]earch [C]ommands' },
      { '<leader>sd',       function() Snacks.picker.diagnostics() end,                                                    desc = '[S]earch [D]iagnostics' },
      { '<leader>sh',       function() Snacks.picker.help() end,                                                           desc = '[S]earch [H]elp' },
      { '<leader>sH',       function() Snacks.picker.highlights() end,                                                     desc = '[S]earch [H]ighlight Groups' },
      { '<leader>si',       function() Snacks.picker.icons() end,                                                          desc = '[S]earch [I]cons' },
      { '<leader>sj',       function() Snacks.picker.jumps() end,                                                          desc = '[S]earch [J]umplist' },
      { '<leader>sk',       function() Snacks.picker.keymaps() end,                                                        desc = '[S]earch [K]eymaps' },
      { '<leader>sl',       function() Snacks.picker.loclist() end,                                                        desc = '[S]earch [L]ocation List' },
      { '<leader>sm',       function() Snacks.picker.man() end,                                                            desc = '[S]earch [M]an Pages' },
      ---@diagnostic disable-next-line: assign-type-mismatch
      { '<leader>sn',       function() Snacks.picker.files({ cwd = wezterm_dir }) end,                                     desc = '[S]earch [N]eovim files' },
      { '<leader>sR',       function() Snacks.picker.resume() end,                                                         desc = '[S]earch [R]esume' },
      { "<leader>ss",       function() Snacks.scratch.select() end,                                                        desc = "[S]earch [S]cratch Buffer" },
      ---@diagnostic disable-next-line: undefined-field
      { '<leader>st',       function() Snacks.picker.todo_comments() end,                                                  desc = '[S]earch [T]odo Comments' },
      ---@diagnostic disable-next-line: undefined-field
      { '<leader>sT',       function() Snacks.picker.todo_comments({ keywords = { 'TODO', 'FIX', 'FIXME' } }) end,         desc = 'Narrowly [S]earch [T]odos' },
      { '<leader>su',       function() Snacks.picker.undo() end,                                                           desc = '[S]earch [U]ndo history' },
      { '<leader>sw',       function() Snacks.picker.files({ cwd = vim.fn.expand('$XDG_CONFIG_HOME') .. '/wezterm' }) end, desc = '[S]earch [W]ezterm files' },
      { '<leader>sq',       function() Snacks.picker.qflist() end,                                                         desc = '[S]earch [Q]uickfix List' },
      { '<leader>sz',       function() Snacks.picker.zoxide() end,                                                         desc = '[S]earch [Z]oxide List' },
      { '<leader>uC',       function() Snacks.picker.colorschemes() end,                                                   desc = '[U]pdate [C]olorschemes' },
      { 'gd',               function() Snacks.picker.lsp_definitions() end,                                                desc = '[G]oto [D]efinition' },
      { 'gD',               function() Snacks.picker.lsp_declarations() end,                                               desc = '[G]oto [D]eclaration' },
      { 'gr',               function() Snacks.picker.lsp_references() end,                                                 nowait = true,                        desc = '[G]oto [R]eferences' },
      { 'gI',               function() Snacks.picker.lsp_implementations() end,                                            desc = '[G]oto [I]mplementation' },
      { '<leader>D',        function() Snacks.picker.lsp_type_definitions() end,                                           desc = 'Type [D]efinition' },
      { '<leader>ds',       function() Snacks.picker.lsp_symbols() end,                                                    desc = '[D]ocument [S]ymbols' },
      { '<leader>np',       function() Snacks.picker.notifications() end,                                                  desc = '[N]otifications picker' },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
