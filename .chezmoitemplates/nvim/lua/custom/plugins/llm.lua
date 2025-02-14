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
  ---@module 'avante'
  {
    'yetone/avante.nvim',
    event = { 'BufReadPost', 'BufWritePost', 'BufNewFile' },
    build = vim.fn.has 'win32' == 0 and 'make' or
        'pwsh.exe -NoProfile -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false',
    opts = {
      provider = 'gemini',
      gemini = {
        model = 'gemini-2.0-pro-exp-02-05',
        -- model = 'gemini-2.0-flash-thinking-exp-01-21',
      },
      vendors = {
        ['qwen'] = generate_vendor('qwen2.5-coder-14b-instruct-mlx'),
        ['supernova'] = generate_vendor('supernova-medius'),
        ['deepseek'] = generate_vendor('deepseek-r1-distill-qwen-14b'),
      },
      file_selector = { provider = 'snacks' },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
