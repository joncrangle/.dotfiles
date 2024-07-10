return {
  {
    '3rd/image.nvim',
    -- Disable for Windows until image.nvim support is added
    enabled = function()
      if vim.fn.has 'win32' == 1 then
        return false
      else
        return true
      end
    end,
    dependencies = {
      'leafo/magick',
    },
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
