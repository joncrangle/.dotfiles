local pick_chezmoi = function()
  require('telescope').extensions.chezmoi.find_files()
end

return {
  {
    'xvzc/chezmoi.nvim',
    cmd = { 'ChezmoiEdit', 'ChezmoiList' },
    keys = {
      { '<leader>sc', pick_chezmoi, desc = '[S]earch [C]hezmoi' },
    },
    init = function()
      -- run chezmoi edit on file enter
      vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {

        pattern = {
          (vim.fn.has 'win32' == 1 and os.getenv 'USERPROFILE' .. '/AppData/Local/chezmoi/*' or os.getenv 'HOME' .. '/.local/share/chezmoi/*'),
        },
        callback = function()
          vim.schedule(require('chezmoi.commands.__edit').watch)
        end,
      })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
