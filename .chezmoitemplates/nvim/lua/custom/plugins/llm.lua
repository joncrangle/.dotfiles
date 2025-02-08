local function generate_vendor(model)
  return {
    __inherited_from = 'openai',
    api_key_name = '',
    endpoint = '{{- if eq .chezmoi.os "darwin" -}}127.0.0.1:5001/v1{{- else -}}{{- .MacAddress -}}:5001/v1{{- end -}}',
    temperature = 0,
    max_tokens = 8192,
    model = model,
  }
end

return {
  {
    'yetone/avante.nvim',
    event = 'VeryLazy',
    build = vim.fn.has 'win32' == 0 and 'make' or
        'pwsh.exe -NoProfile -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false',
    dependencies = { 'stevearc/dressing.nvim' },
    opts = {
      provider = 'qwen',
      vendors = {
        ['qwen'] = generate_vendor('qwen2.5-coder-14b-instruct-mlx'),
        ['supernova'] = generate_vendor('supernova-medius'),
        ['deepseek'] = generate_vendor('deepseek-r1-distill-qwen-14b'),
      },
      file_selector = { provider = 'snacks' },
    }
  },
}
-- vim: ts=2 sts=2 sw=2 et
