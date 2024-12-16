return {
  {
    'ibhagwan/fzf-lua',
    cmd = 'FzfLua',
    ---@diagnostic disable-next-line: unused-local
    opts = function(_, opts)
      local config = require('fzf-lua.config')
      local actions = require('fzf-lua.actions')

      config.defaults.keymap.fzf['ctrl-q'] = 'select-all+accept'
      config.defaults.keymap.fzf['ctrl-x'] = 'jump'
      config.defaults.keymap.fzf['ctrl-u'] = 'half-page-up'
      config.defaults.keymap.fzf['ctrl-d'] = 'half-page-down'
      config.defaults.keymap.fzf['ctrl-f'] = 'preview-page-down'
      config.defaults.keymap.fzf['ctrl-b'] = 'preview-page-up'
      config.defaults.keymap.builtin['<c-f>'] = 'preview-page-down'
      config.defaults.keymap.builtin['<c-b>'] = 'preview-page-up'

      local img_previewer ---@type string[]?
      for _, v in ipairs({
        { cmd = "viu",      args = { "-b" } },
        { cmd = "chafa",    args = { "{file}", "--format=symbols" } },
        { cmd = "ueberzug", args = {} },
      }) do
        if vim.fn.executable(v.cmd) == 1 then
          img_previewer = vim.list_extend({ v.cmd }, v.args)
          break
        end
      end

      return {
        'default-title',
        fzf_colors = true,
        fzf_opts = {
          ['--no-scrollbar'] = true,
        },
        defaults = {
          formatter = "path.filename_first",
          -- formatter = 'path.dirname_first',
          git_icons = false,
        },
        previewers = {
          builtin = {
            extensions = {
              ["png"] = img_previewer,
              ["jpg"] = img_previewer,
              ["jpeg"] = img_previewer,
              ["gif"] = img_previewer,
              ["webp"] = img_previewer,
            },
            ueberzug_scaler = "fit_contain",
          },
        },
        ui_select = function(fzf_opts, items)
          return vim.tbl_deep_extend('force', fzf_opts, {
            prompt = ' ',
            winopts = {
              title = ' ' .. vim.trim((fzf_opts.prompt or 'Select'):gsub('%s*:%s*$', '')) .. ' ',
              title_pos = 'center',
            },
          }, fzf_opts.kind == 'codeaction' and {
            winopts = {
              layout = 'vertical',
              -- height is number of items minus 15 lines for the preview, with a max of 80% screen height
              height = math.floor(math.min(vim.o.lines * 0.8 - 16, #items + 2) + 0.5) + 16,
              width = 0.5,
              preview = {
                layout = 'vertical',
                vertical = 'down:15,border-top',
              },
            },
          } or {
            winopts = {
              width = 0.5,
              -- height is number of items, with a max of 80% screen height
              height = math.floor(math.min(vim.o.lines * 0.8, #items + 2) + 0.5),
            },
          })
        end,
        winopts = {
          width = 0.8,
          height = 0.8,
          row = 0.5,
          col = 0.5,
          preview = {
            scrollchars = { '┃', '' },
          },
        },
        files = {
          cwd_prompt = false,
          actions = {
            ['alt-i'] = { actions.toggle_ignore },
            ['alt-h'] = { actions.toggle_hidden },
            ['ctrl-g'] = false,
          },
        },
        grep = {
          actions = {
            ['alt-i'] = { actions.toggle_ignore },
            ['alt-h'] = { actions.toggle_hidden },
            ['ctrl-g'] = false,
          },
        },
        lsp = {
          symbols = {
            symbol_hl = function(s)
              return 'TroubleIcon' .. s
            end,
            symbol_fmt = function(s)
              return s:lower() .. '\t'
            end,
            child_prefix = false,
          },
          code_actions = {
            previewer = vim.fn.executable('delta') == 1 and 'codeaction_native' or nil,
          },
        },
      }
    end,
    config = function(_, opts)
      if opts[1] == 'default-title' then
        -- use the same prompt for all pickers for profile `default-title` and
        -- profiles that use `default-title` as base profile
        local function fix(t)
          t.prompt = t.prompt ~= nil and ' ' or nil
          for _, v in pairs(t) do
            if type(v) == 'table' then
              fix(v)
            end
          end
          return t
        end
        opts = vim.tbl_deep_extend('force', fix(require('fzf-lua.profiles.default-title')), opts)
        opts[1] = nil
      end
      require('fzf-lua').setup(opts)
    end,
    keys = {
      { '<c-j>',            '<c-j>',                                                                                     ft = 'fzf',                               mode = 't', nowait = true },
      { '<c-k>',            '<c-k>',                                                                                     ft = 'fzf',                               mode = 't', nowait = true },
      { '<leader><leader>', '<cmd>FzfLua buffers sort_mru=true sort_lastused=false<cr>',                                 desc = '[ ] Find existing buffers' },
      { '<leader>/',        '<cmd>FzfLua grep_curbuf<cr>',                                                               desc = '[/] Search in current Buffer' },
      { '<leader>\\',       '<cmd>FzfLua lines<cr>',                                                                     desc = '[\\] Search in open Buffers' },
      { '<leader>s.',       '<cmd>FzfLua oldfiles<cr>',                                                                  desc = '[S]earch Recent Files' },
      { '<leader>s"',       '<cmd>FzfLua registers<cr>',                                                                 desc = '[S]earch Registers' },
      { '<leader>sa',       '<cmd>FzfLua autocmds<cr>',                                                                  desc = '[S]earch Auto Commands' },
      { '<leader>D',        '<cmd>FzfLua lsp_typedefs jump_to_single_result=true ignore_current_line=true<cr>',          desc = 'Type [D]efinition' },
      { '<leader>ds',       '<cmd>FzfLua lsp_document_symbols<cr>',                                                      desc = '[D]ocument [S]ymbols' },
      { '<leader>sc',       '<cmd>FzfLua command_history<cr>',                                                           desc = '[S]earch [C]ommand History' },
      { '<leader>sC',       '<cmd>FzfLua commands<cr>',                                                                  desc = '[S]earch [C]ommands' },
      { '<leader>sd',       '<cmd>FzfLua diagnostics_document<cr>',                                                      desc = '[S]earch [D]iagnostics' },
      { '<leader>sD',       '<cmd>FzfLua diagnostics_workspace<cr>',                                                     desc = '[S]earch Workspace [D]iagnostics' },
      { '<leader>sf',       '<cmd>FzfLua files<cr>',                                                                     desc = '[S]earch [F]iles' },
      { '<leader>sg',       '<cmd>FzfLua live_grep<cr>',                                                                 desc = '[S]earch by [G]rep' },
      { '<leader>sh',       '<cmd>FzfLua help_tags<cr>',                                                                 desc = '[S]earch [H]elp' },
      { '<leader>sH',       '<cmd>FzfLua highlights<cr>',                                                                desc = '[S]earch [H]ighlight Groups' },
      { '<leader>sj',       '<cmd>FzfLua jumps<cr>',                                                                     desc = '[S]earch [J]umplist' },
      { '<leader>sk',       '<cmd>FzfLua keymaps<cr>',                                                                   desc = '[S]earch [K]eymaps' },
      { '<leader>sm',       '<cmd>FzfLua man_pages<cr>',                                                                 desc = '[S]earch [M]an Pages' },
      { '<leader>sn',       function() require('fzf-lua').files({ cwd = vim.fn.stdpath 'config' }) end,                  desc = '[S]earch [N]eovim files' },
      { '<leader>sR',       '<cmd>FzfLua resume<cr>',                                                                    desc = '[S]earch [R]esume' },
      { '<leader>st',       function() require('todo-comments.fzf').todo() end,                                          desc = '[S]earch [T]odo Comments' },
      { '<leader>sT',       function() require('todo-comments.fzf').todo({ keywords = { 'TODO', 'FIX', 'FIXME' } }) end, desc = 'Narrowly [S]earch [T]odos' },
      { '<leader>sw',       function() require('fzf-lua').files({ cwd = '$XDG_CONFIG_HOME/wezterm' }) end,               desc = '[S]earch [W]ezterm files' },
      { '<leader>sq',       '<cmd>FzfLua quickfix<cr>',                                                                  desc = '[S]earch [Q]uickfix List' },
      { '<leader>uC',       '<cmd>FzfLua colorschemes<cr>',                                                              desc = '[U]pdate [C]olorschemes' },
      { '<leader>ws',       '<cmd>FzfLua lsp_workspace_symbols<cr>',                                                     desc = '[W]orkspace [S]ymbols' },
      { 'gd',               '<cmd>FzfLua lsp_definitions jump_to_single_result=true ignore_current_line=true<cr>',       desc = '[G]oto [D]efinition' },
      { 'gD',               '<cmd>FzfLua lsp_declarations jump_to_single_result=true ignore_current_line=true<cr>',      desc = '[G]oto [D]eclaration' },
      { 'gr',               '<cmd>FzfLua lsp_references jump_to_single_result=true ignore_current_line=true<cr>',        desc = '[G]oto [R]eferences' },
      { 'gI',               '<cmd>FzfLua lsp_implementations jump_to_single_result=true ignore_current_line=true<cr>',   desc = '[G]oto [I]mplementation' },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
