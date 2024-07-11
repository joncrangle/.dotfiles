return {
  {
    '3rd/image.nvim',
    -- Disable for Windows until image.nvim support is added
    enabled = function()
      return vim.fn.has 'win32' ~= 1
    end,
    dependencies = {
      'leafo/magick',
    },
    ft = { 'markdown' },
    opts = {
      integrations = {
        markdown = {
          enabled = false,
          clear_in_insert_mode = true,
          only_render_image_at_cursor = false,
        },
        neorg = {
          enabled = false,
        },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
