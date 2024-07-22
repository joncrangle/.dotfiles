local enabled = function()
  return vim.fn.has 'win32' ~= 1
end

return {
  {
    '3rd/image.nvim',
    -- Disable for Windows until image.nvim support is added
    enabled = enabled,
    dependencies = {
      { 'leafo/magick', lazy = true, enabled = enabled, ft = { 'markdown' } },
    },
    ft = { 'markdown' },
    opts = {
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = true,
          only_render_image_at_cursor = true,
        },
        neorg = {
          enabled = false,
        },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
