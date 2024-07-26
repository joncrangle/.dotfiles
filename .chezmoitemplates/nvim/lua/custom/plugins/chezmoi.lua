local pick_chezmoi = function()
  require('telescope').extensions.chezmoi.find_files()
end

return {
  {
    'xvzc/chezmoi.nvim',
    cmd = { 'ChezmoiEdit', 'ChezmoiList' },
    -- event = { 'BufRead', 'BufNewFile' },
    keys = {
      { '<leader>sc', pick_chezmoi, desc = '[S]earch [C]hezmoi' },
    },
    -- init = function()
    --   -- run chezmoi edit on file enter
    --   vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
    --     pattern = { os.getenv 'XDG_DATA_HOME' .. '/chezmoi/*' },
    --     callback = function()
    --       vim.schedule(require('chezmoi.commands.__edit').watch)
    --     end,
    --   })
    -- end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
