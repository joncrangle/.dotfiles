return {
  {
    'nvim-mini/mini.nvim',
    event = { 'BufReadPost', 'BufNewFile', 'CmdlineEnter' },
    config = function()
      require('mini.ai').setup { n_lines = 500 }
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote

      require('mini.surround').setup()
      -- Examples:
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']

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

      require('mini.git').setup()

      -- Customize git summary to show only branch name (no status)
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniGitUpdated',
        callback = function(data)
          local summary = vim.b[data.buf].minigit_summary
          vim.b[data.buf].minigit_summary_string = summary and summary.head_name or ''
        end,
      })

      -- Customize diff summary with colored +/~/- signs
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniDiffUpdated',
        callback = function(data)
          local summary = vim.b[data.buf].minidiff_summary
          local t = {}
          if summary.add > 0 then
            table.insert(t, '%#StatuslineDiffAdd#+' .. summary.add .. '%#PmenuSbar#')
          end
          if summary.change > 0 then
            table.insert(t, '%#StatuslineDiffChange#~' .. summary.change .. '%#PmenuSbar#')
          end
          if summary.delete > 0 then
            table.insert(t, '%#StatuslineDiffDelete#-' .. summary.delete .. '%#PmenuSbar#')
          end
          vim.b[data.buf].minidiff_summary_string = table.concat(t, ' ')
        end,
      })

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
      MiniIcons.mock_nvim_web_devicons() --NOTE: Until other plugins support mini.icons natively

      local statusline = require 'mini.statusline'
      local disabled_filetypes = { 'snacks_dashboard', 'lazygit' }

      local function get_special_statusline()
        local ft = vim.bo.filetype
        local truncated = statusline.is_truncated(80)
        if ft == 'grapple' then
          return 'Grapple', package.loaded['grapple'] and (require('grapple').statusline() or '') or ''
        elseif ft == 'snacks_terminal' then
          return ' Terminal', vim.fn.expand('%:t'):match '.*:(%S+)$' or vim.fn.expand '%:t'
        elseif ft == 'snacks_picker_list' then
          local picker = Snacks.picker.get()[1]
          local dir = picker and picker:dir() or vim.fn.getcwd()
          if truncated then
            return '🍿', vim.fn.fnamemodify(dir, ':t')
          end
          return '🍿 Explorer', vim.fn.fnamemodify(dir, ':~')
        elseif ft == 'snacks_picker_input' then
          local picker = Snacks.picker.get()[1]
          if picker then
            local input = picker.input and picker.input:get() or ''
            local count = #picker:items()
            if truncated then
              return '🍿', count .. ''
            end
            return '🍿 Picker', input ~= '' and (' ' .. input .. ': ' .. count .. ' results') or (count .. ' results')
          end
          return '🍿 Picker', ''
        elseif ft == 'sidekick_terminal' then
          return '  Sidekick', vim.fn.expand('%:t'):match '.*:(%S+)$' or vim.fn.expand '%:t'
        end
        return nil, nil
      end

      local function section_git()
        local branch = vim.b.minigit_summary_string or vim.b.gitsigns_head or ''
        if branch == '' then
          return ''
        end
        local icon = ' '
        if not statusline.is_truncated(80) then
          return icon .. branch
        end
        if branch == 'master' or branch == 'main' then
          return icon .. branch:sub(1, 1)
        elseif branch == 'HEAD' then
          return icon .. 'h'
        elseif branch:find '/' then
          local prefix, rest = branch:match '^([^/]+)/(.+)'
          return icon .. prefix:sub(1, 1) .. '/' .. rest:sub(1, 2) .. '…'
        else
          return icon .. branch:sub(1, 4) .. (#branch > 4 and '…' or '')
        end
      end

      local function section_macro()
        local reg = vim.fn.reg_recording()
        return reg ~= '' and '%#WarningMsg#Recording @' .. reg .. '%*' or ''
      end

      local function section_filepath()
        local filepath = vim.fn.expand '%:.' --[[@as string]]
        if filepath == '' then
          filepath = vim.bo.filetype
        end
        local filename = vim.fn.expand '%:t'
        local mod_hl = vim.bo.modified and '%#StatuslineMatchParen#' or '%#StatuslineTitle#'

        local grapple = ''
        if package.loaded['grapple'] and require('grapple').exists() then
          grapple = ' %#StatuslineGrapple#󰛢 ' .. require('grapple').name_or_index()
        end

        local readonly = vim.bo.readonly and '%#StatuslineReadonly# 󰌾 ' or ''

        -- Only show directory when not truncated
        if statusline.is_truncated(80) then
          return mod_hl .. filename .. grapple .. readonly .. '%*'
        end

        local dir = filepath:sub(1, -(#filename + 1))
        return '%#StatuslineDir#' .. dir .. mod_hl .. filename .. grapple .. readonly .. '%*'
      end

      local function section_dap()
        if package.loaded['dap'] and require('dap').status() ~= '' then
          return '%#Debug#   ' .. require('dap').status() .. '%*'
        end
        return ''
      end

      local function section_lsp()
        local clients = vim.lsp.get_clients { bufnr = 0 }
        local names = {}
        for _, client in ipairs(clients) do
          table.insert(names, client.name)
        end
        if #names == 0 then
          return ''
        end
        if statusline.is_truncated(100) then
          return '󰅩 ' .. #names
        end
        return '󰅩 ' .. table.concat(names, ' ')
      end

      local function active_content()
        local ft = vim.bo.filetype
        if vim.tbl_contains(disabled_filetypes, ft) then
          return ''
        end

        local title, meta = get_special_statusline()
        if title then
          local mode, mode_hl = statusline.section_mode { trunc_width = 9999 }
          return statusline.combine_groups {
            { hl = mode_hl, strings = { mode } },
            { hl = 'MiniStatuslineFilename', strings = { title } },
            { hl = 'Normal', strings = { meta } },
          }
        end

        local mode, mode_hl = statusline.section_mode { trunc_width = 9999 }
        local git = section_git()
        local diff = vim.b.minidiff_summary_string or ''
        local diagnostics = statusline.section_diagnostics {
          trunc_width = 40,
          icon = '',
          signs = {
            ERROR = '%#StatuslineDiagError#󰅚 ',
            WARN = '%#StatuslineDiagWarn#󰀪 ',
            INFO = '%#StatuslineDiagInfo#󰋽 ',
            HINT = '%#StatuslineDiagHint#󰌶 ',
          },
        }

        return statusline.combine_groups {
          { hl = mode_hl, strings = { mode } },
          { hl = 'MiniStatuslineInactive', strings = { section_macro(), git } },
          { hl = 'MiniStatuslineFilename', strings = { diagnostics } },
          '%<', -- Mark general truncate point
          { hl = 'MiniStatuslineFilename', strings = { section_filepath() } },
          '%=', -- End left alignment
          { hl = 'PmenuSbar', strings = { diff } },
          { hl = 'MiniStatuslineFilename', strings = { section_dap(), section_lsp() } },
          { hl = 'MiniStatuslineInactive', strings = { '%3p%%' } },
          { hl = mode_hl, strings = { '%l:%c' } },
        }
      end

      local function inactive_content()
        return statusline.combine_groups {
          { hl = 'MiniStatuslineInactive', strings = { section_filepath() } },
        }
      end

      statusline.setup {
        content = {
          active = active_content,
          inactive = inactive_content,
        },
        use_icons = true,
      }

      local function create_compound_hl(name, fg_name, bg_name)
        local fg_hl = vim.api.nvim_get_hl(0, { name = fg_name, link = false })
        local bg_hl = vim.api.nvim_get_hl(0, { name = bg_name, link = false })

        local new_hl = {
          bg = bg_hl.bg,
          fg = fg_hl.fg or bg_hl.fg,
          sp = fg_hl.sp or bg_hl.sp,
          bold = fg_hl.bold,
          italic = fg_hl.italic,
          underline = fg_hl.underline,
          undercurl = fg_hl.undercurl,
          strikethrough = fg_hl.strikethrough,
          reverse = fg_hl.reverse,
        }
        vim.api.nvim_set_hl(0, name, new_hl)
      end

      local function setup_statusline_hl()
        local compound_hl = {
          -- Diagnostics (Normal BG)
          StatuslineDiagError = { fg = 'DiagnosticError', bg = 'MiniStatuslineFilename' },
          StatuslineDiagWarn = { fg = 'DiagnosticWarn', bg = 'MiniStatuslineFilename' },
          StatuslineDiagInfo = { fg = 'DiagnosticInfo', bg = 'MiniStatuslineFilename' },
          StatuslineDiagHint = { fg = 'DiagnosticHint', bg = 'MiniStatuslineFilename' },
          -- Diff (PmenuSbar BG)
          StatuslineDiffAdd = { fg = 'MiniDiffSignAdd', bg = 'PmenuSbar' },
          StatuslineDiffChange = { fg = 'MiniDiffSignChange', bg = 'PmenuSbar' },
          StatuslineDiffDelete = { fg = 'MiniDiffSignDelete', bg = 'PmenuSbar' },
          -- Filepath (PmenuSbar BG)
          StatuslineDir = { fg = 'Italic', bg = 'PmenuSbar' },
          StatuslineTitle = { fg = 'Title', bg = 'PmenuSbar' },
          StatuslineMatchParen = { fg = 'MatchParen', bg = 'PmenuSbar' },
          StatuslineGrapple = { fg = 'GrappleName', bg = 'PmenuSbar' },
          StatuslineReadonly = { fg = 'DiagnosticWarn', bg = 'PmenuSbar' },
        }

        for name, config in pairs(compound_hl) do
          create_compound_hl(name, config.fg, config.bg)
        end
      end

      setup_statusline_hl()
      vim.api.nvim_create_autocmd('ColorScheme', { callback = setup_statusline_hl })

      vim.o.laststatus = 3
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
