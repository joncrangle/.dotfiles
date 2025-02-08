return {
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    lazy = true,
    event = { 'BufReadPost', 'BufNewFile', 'CmdlineEnter' },
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup()

      require('mini.diff').setup {
        view = {
          style = 'sign',
          signs = {
            add = '▎',
            change = '▎',
            delete = '',
          },
        },
        vim.keymap.set('n', '<leader>go', '<cmd>lua MiniDiff.toggle_overlay(0)<cr>', { desc = 'Toggle [G]it mini.diff [O]verlay' }),
      }

      -- require('mini.files').setup({
      --   mappings = {
      --     go_in = 'L',
      --     go_in_plus = 'l',
      --     go_out = 'H',
      --     go_out_plus = 'h',
      --   },
      --   options = {
      --     use_as_default_explorer = true,
      --   },
      --   windows = {
      --     preview = true,
      --     width_focus = 30,
      --     width_preview = 30,
      --   },
      --   vim.keymap.set('n', '\\', '<cmd>lua MiniFiles.open()<cr>', { desc = 'Open mini.files' }),
      -- })

      -- Adapt LazyVim autopair config
      local pairs_opts = {
        modes = { insert = true, command = true, terminal = false },
        -- Skip autopair when next character is one of these
        skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
        -- Skip autopair when the cursor is inside these Treesitter nodes
        skip_ts = { 'string' },
        -- Skip autopair when the next character is a closing pair
        -- and there are more closing pairs than opening pairs
        skip_unbalanced = true,
        -- Better deal with markdown code blocks
        markdown = true,
      }

      local function custom_pairs(opts)
        local pairs = require('mini.pairs')
        pairs.setup(opts)

        -- Overriding the open function
        local open = pairs.open
        ---@diagnostic disable-next-line: duplicate-set-field
        pairs.open = function(pair, neigh_pattern)
          if vim.fn.getcmdline() ~= "" then
            return open(pair, neigh_pattern)
          end
          local o, c = pair:sub(1, 1), pair:sub(2, 2)
          local line = vim.api.nvim_get_current_line()
          local cursor = vim.api.nvim_win_get_cursor(0)
          local next = line:sub(cursor[2] + 1, cursor[2] + 1)
          local before = line:sub(1, cursor[2])

          -- Handle markdown code blocks
          if opts.markdown and o == '`' and vim.bo.filetype == 'markdown' and before:match("^%s*``") then
            return "`\n```" .. vim.api.nvim_replace_termcodes("<up>", true, true, true)
          end

          -- Skip autopair if the next character matches skip_next pattern
          if opts.skip_next and next ~= "" and next:match(opts.skip_next) then
            return o
          end

          -- Skip autopair if inside a Treesitter node listed in skip_ts
          if opts.skip_ts and #opts.skip_ts > 0 then
            local ok, captures = pcall(vim.treesitter.get_captures_at_pos, 0, cursor[1] - 1, math.max(cursor[2] - 1, 0))
            for _, capture in ipairs(ok and captures or {}) do
              if vim.tbl_contains(opts.skip_ts, capture.capture) then
                return o
              end
            end
          end

          -- Skip autopair if unbalanced and next character is a closing pair
          if opts.skip_unbalanced and next == c and c ~= o then
            local _, count_open = line:gsub(vim.pesc(pair:sub(1, 1)), "")
            local _, count_close = line:gsub(vim.pesc(pair:sub(2, 2)), "")
            if count_close > count_open then
              return o
            end
          end

          return open(pair, neigh_pattern)
        end
      end

      -- Load mini.pairs with the custom configuration
      require('mini.pairs').setup(pairs_opts)
      custom_pairs(pairs_opts)

      -- Icon provider
      require('mini.icons').setup {
        file = {
          ['.chezmoiignore'] = { glyph = '', hl = 'MiniIconsGrey' },
          ['.chezmoiremove'] = { glyph = '', hl = 'MiniIconsGrey' },
          ['.chezmoiroot'] = { glyph = '', hl = 'MiniIconsGrey' },
          ['.chezmoiversion'] = { glyph = '', hl = 'MiniIconsGrey' },
          ['.eslintrc.js'] = { glyph = '󰱺', hl = 'MiniIconsYellow' },
          ['.go-version'] = { glyph = '', hl = 'MiniIconsBlue' },
          ['.node-version'] = { glyph = '', hl = 'MiniIconsGreen' },
          ['.prettierrc'] = { glyph = '', hl = 'MiniIconsPurple' },
          ['.yarnrc.yml'] = { glyph = '', hl = 'MiniIconsBlue' },
          ['bash.tmpl'] = { glyph = '', hl = 'MiniIconsGrey' },
          ['docker-compose.yml'] = { glyph = '', hl = 'MiniIconsBlue' },
          ['docker-compose.yaml'] = { glyph = '', hl = 'MiniIconsBlue' },
          ['eslint.config.js'] = { glyph = '󰱺', hl = 'MiniIconsYellow' },
          ['json.tmpl'] = { glyph = '', hl = 'MiniIconsGrey' },
          ['package.json'] = { glyph = '', hl = 'MiniIconsGreen' },
          ['ps1.tmpl'] = { glyph = '󰨊', hl = 'MiniIconsGrey' },
          ['sh.tmpl'] = { glyph = '', hl = 'MiniIconsGrey' },
          ['toml.tmpl'] = { glyph = '', hl = 'MiniIconsGrey' },
          ['tsconfig.build.json'] = { glyph = '', hl = 'MiniIconsAzure' },
          ['tsconfig.json'] = { glyph = '', hl = 'MiniIconsAzure' },
          ['yaml.tmpl'] = { glyph = '', hl = 'MiniIconsGrey' },
          ['yarn.lock'] = { glyph = '', hl = 'MiniIconsBlue' },
          ['zsh.tmpl'] = { glyph = '', hl = 'MiniIconsGrey' },
        },
        filetype = {
          dockerfile = { glyph = '', hl = 'MiniIconsBlue' },
          gotmpl = { glyph = '󰟓', hl = 'MiniIconsGrey' },
        },
      }
      -- Until other plugins support mini.icons natively
      MiniIcons.mock_nvim_web_devicons()

      require('mini.indentscope').setup {
        symbol = '│',
        options = { try_as_border = true },
        draw = {
          delay = 30,
          -- animation = require('mini.indentscope').gen_animation.none(),
        },
      }
    end,
    init = function()
      vim.api.nvim_create_autocmd('FileType', {
        pattern = {
          'alpha',
          'dashboard',
          'fzf',
          'help',
          'lazy',
          'mason',
          'neo-tree',
          'notify',
          'snacks_notif',
          'snacks_terminal',
          'snacks_win',
          'toggleterm',
          'trouble',
          'Trouble',
        },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })

      local show_dotfiles = true

      local filter_show = function(_) return true end

      local filter_hide = function(fs_entry)
        return not vim.startswith(fs_entry.name, ".")
      end

      local toggle_dotfiles = function()
        show_dotfiles = not show_dotfiles
        local new_filter = show_dotfiles and filter_show or filter_hide
        require("mini.files").refresh { content = { filter = new_filter } }
      end

      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesBufferCreate",
        callback = function(args)
          local buf_id = args.data.buf_id
          vim.keymap.set("n", "g.", toggle_dotfiles, { buffer = buf_id, desc = 'Toggle dotfiles' })
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesActionRename",
        callback = function(event)
          Snacks.rename.on_rename_file(event.data.from, event.data.to)
        end,
      })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
