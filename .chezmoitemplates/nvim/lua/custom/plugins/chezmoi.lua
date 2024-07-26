local pick_chezmoi = function()
  require('telescope').extensions.chezmoi.find_files()
end

return {
  {
    -- highlighting for chezmoi files template files
    'alker0/chezmoi.vim',
    event = { 'BufRead', 'BufNewFile' },
    init = function()
      vim.g['chezmoi#use_tmp_buffer'] = 1
      vim.g['chezmoi#source_dir_path'] = (
        vim.fn.has 'win32' == 1 and os.getenv 'USERPROFILE' .. '/AppData/Local/chezmoi' or os.getenv 'HOME' .. '/.local/share/chezmoi'
      )
    end,
  },
  {
    'xvzc/chezmoi.nvim',
    cmd = { 'ChezmoiEdit', 'ChezmoiList' },
    event = { 'BufRead', 'BufNewFile' },
    keys = {
      { '<leader>sc', pick_chezmoi, desc = '[S]earch [C]hezmoi' },
    },
    init = function()
      -- run chezmoi edit on file enter
      vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
        pattern = {
          vim.fn.has 'win32' == 1 and (os.getenv 'USERPROFILE' .. '/AppData/Local/chezmoi/*') or (os.getenv 'HOME' .. '/.local/share/chezmoi/*'),
        },
        callback = function()
          vim.schedule(require('chezmoi.commands.__edit').watch)
        end,
      })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
