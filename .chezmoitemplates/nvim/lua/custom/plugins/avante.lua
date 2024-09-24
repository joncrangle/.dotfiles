local function generate_vendor(model)
  return {
    ['local'] = true,
    endpoint = '{{- if eq .chezmoi.os "darwin" -}}127.0.0.1:11434/v1{{- else -}}{{- .MacAddress -}}:11434/v1{{- end -}}',
    model = model,
    parse_curl_args = function(opts, code_opts)
      return {
        url = opts.endpoint .. '/chat/completions',
        headers = {
          ['Accept'] = 'application/json',
          ['Content-Type'] = 'application/json',
        },
        body = {
          model = opts.model,
          messages = require('avante.providers').copilot.parse_message(code_opts),
          max_tokens = 4096,
          stream = true,
        },
      }
    end,
    parse_response_data = function(data_stream, event_state, opts)
      require('avante.providers').openai.parse_response(data_stream, event_state, opts)
    end,
  }
end

return {
  {
    'yetone/avante.nvim',
    event = 'VeryLazy',
    build = vim.fn.has 'win32' == 0 and 'make' or
        'pwsh.exe -NoProfile -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false',
    opts = {
      provider = 'qwen',
      vendors = {
        qwen = generate_vendor('qwen-coder:latest'),
        deepseek = generate_vendor('deepseek-coder:latest'),
      },
    }
  },
}
-- vim: ts=2 sts=2 sw=2 et
