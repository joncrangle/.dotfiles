local check_external_reqs = function()
  for _, exe in ipairs { 'git', 'fzf', 'magick', 'make', 'unzip', 'rg', 'tree-sitter', 'zoxide' } do
    local is_executable = vim.fn.executable(exe) == 1
    if is_executable then
      vim.health.ok(string.format("Found executable: '%s'", exe))
    else
      vim.health.warn(string.format("Could not find executable: '%s'", exe))
    end
  end

  return true
end

return {
  check = function()
    vim.health.start 'nvim dependencies'

    local uv = vim.uv or vim.loop
    vim.health.info('System Information: ' .. vim.inspect(uv.os_uname()))

    check_external_reqs()
  end,
}
-- vim: ts=2 sts=2 sw=2 et
