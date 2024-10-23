local function generate_vendor(port, model)
  return {
    ['local'] = true,
    endpoint = '{{- if eq .chezmoi.os "darwin" -}}127.0.0.1{{- else -}}{{- .MacAddress -}}{{- end -}}',
    model = model,
    parse_curl_args = function(opts, code_opts)
      return {
        url = opts.endpoint .. ':' .. port .. '/v1/chat/completions',
        headers = {
          ['Accept'] = 'application/json',
          ['Content-Type'] = 'application/json',
        },
        body = {
          model = opts.model,
          messages = require('avante.providers').copilot.parse_message(code_opts),
          temperature = 0,
          max_tokens = 8192,
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
        ['qwen'] = generate_vendor('5001', 'qwen2.5-coder-7b-instruct-8bit-q8'),
        ['qwen14'] = generate_vendor('5001', 'qwen2.5-14b-instruct-4bit-q4'),
        ['llama'] = generate_vendor('5001', 'meta-llama-3.1-8b-instruct-8bit-q8'),
        ['replete'] = generate_vendor('11434', 'Replete-LLM-V2.5-Qwen:14b-q4_K_M'),
      },
    }
  },
}
-- vim: ts=2 sts=2 sw=2 et
