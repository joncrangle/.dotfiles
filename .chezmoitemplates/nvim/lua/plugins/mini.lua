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
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
