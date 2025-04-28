return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      {
        'williamboman/mason.nvim',
        cmd = 'Mason',
        opts = {
          registries = {
            'github:mason-org/mason-registry',
            'github:mistweaverco/zana-registry',
          },
        },
      },
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      'williamboman/mason-lspconfig.nvim',
      { 'b0o/schemastore.nvim', lazy = true, opts = nil },
      {
        'jmbuhr/otter.nvim',
        ft = 'markdown',
        opts = {},
        keys = function()
          vim.api.nvim_create_user_command('OtterToggle', function()
            local otter = require 'otter'
            if not vim.g.enable_otter then
              vim.g.enable_otter = true
              otter.activate()
              vim.notify('Otter enabled', vim.log.levels.INFO)
            else
              vim.g.enable_otter = false
              otter.deactivate()
              vim.notify('Otter disabled', vim.log.levels.INFO)
            end
          end, {
            desc = 'Toggle Otter',
          })
          return {
            { '<leader>to', '<cmd>OtterToggle<cr>', desc = '[T]oggle [O]tter' },
          }
        end,
      },
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
          map('ge', '<cmd>lua vim.diagnostic.open_float()<CR>', 'Open [E]rror in Float')
          map('<leader>ci', function()
            vim.lsp.buf.code_action {
              apply = true,
              context = {
                only = { 'source.organizeImports' },
                diagnostics = {},
              },
            }
          end, 'LSP Organize [I]mports')

          if vim.bo.filetype == 'typescriptreact' then
            map('<leader>cI', function()
              vim.lsp.buf.code_action {
                apply = true,
                context = {
                  ---@diagnostic disable-next-line: assign-type-mismatch
                  only = { 'source.addMissingImports.ts' },
                  diagnostics = {},
                },
              }
            end, 'LSP Add Missing [I]mport')
          end
          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map('<leader>ti', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle [I]nlay Hints')
          end
        end,
      })

      local servers = {
        astro = {},
        basedpyright = {
          enabled = true,
          settings = {
            disableOrganizeImports = true,
            basedpyright = {
              analysis = {
                typeCheckingMode = 'standard',
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                autoImportCompletions = true,
              },
            },
            python = { venvPath = '.' },
          },
        },
        bashls = {},
        biome = {},
        clangd = {},
        ['copilot-language-server'] = { mason = false },
        cssls = {},
        denols = {
          root_markers = { 'deno.json', 'deno.jsonc' },
          settings = {
            init_options = {
              enable = true,
              lint = true,
              unstable = true,
            },
          },
        },
        docker_compose_language_service = {},
        dockerls = {},
        eslint = {},
        gopls = {
          gofumpt = true,
          codelenses = {
            gc_details = true,
            generate = true,
            regenerate_cgo = true,
            run_govulncheck = true,
            test = true,
            tidy = true,
            upgrade_dependency = true,
            version = true,
          },
          hints = {
            assignVariableTypes = true,
            compositeLiteralFields = true,
            compositeLiteralTypes = true,
            constantValues = true,
            functionTypeParameters = true,
            parameterNames = true,
            rangeVariableTypes = true,
          },
          analyses = {
            fieldalignment = true,
            nilness = true,
            unusedparams = true,
            unusedwrite = true,
            useany = true,
          },
          usePlaceholders = true,
          completeUnimported = true,
          staticcheck = true,
          directoryFilters = { '-.git', '-.vscode', '-.idea', '-.vscode-test', '-node_modules' },
          semanticTokens = true,
        },
        harper_ls = {
          settings = {
            ['harper-ls'] = {
              dialect = 'Canadian',
            },
          },
        },
        html = {},
        jqls = {},
        jsonls = {
          -- Lazy-load schemastore when needed
          on_new_config = function(new_config)
            new_config.settings.json.schemas = new_config.settings.json.schemas or {}
            vim.list_extend(new_config.settings.json.schemas, require('schemastore').json.schemas())
          end,
          settings = {
            json = {
              format = {
                enable = true,
              },
              validate = { enable = true },
            },
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
              hint = {
                enable = true,
              },
              codeLens = {
                enable = true,
              },
              doc = {
                privateName = { '^_' },
              },
            },
          },
        },
        marksman = {},
        mdx_analyzer = {},
        ruff = {},
        svelte = {},
        tailwindcss = {
          filetypes_exclude = { 'markdown' },
          filetypes_include = {},
        },
        templ = {},
        tinymist = {
          formatterMode = 'typstyle',
          exportPdf = 'never',
        },
        vtsls = {
          settings = {
            complete_function_calls = true,
            vtsls = {
              enableMoveToFileCodeAction = true,
              autoUseWorkspaceTsdk = true,
              experimental = {
                completion = {
                  enableServerSideFuzzyMatch = true,
                },
              },
            },
            javascript = {
              updateImportsOnFileMove = { enabled = 'always' },
              suggest = {
                completeFunctionCalls = true,
              },
              inlayHints = {
                enumMemberValues = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                parameterNames = { enabled = 'literals' },
                parameterTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                variableTypes = { enabled = false },
              },
            },
            typescript = {
              updateImportsOnFileMove = { enabled = 'always' },
              suggest = {
                completeFunctionCalls = true,
              },
              inlayHints = {
                enumMemberValues = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                parameterNames = { enabled = 'literals' },
                parameterTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                variableTypes = { enabled = false },
              },
            },
          },
        },
        yamlls = {
          -- Have to add this for yamlls to understand that we support line folding
          capabilities = {
            textDocument = {
              foldingRange = {
                dynamicRegistration = false,
                lineFoldingOnly = true,
              },
            },
          },
          -- lazy-load schemastore when needed
          on_new_config = function(new_config)
            new_config.settings.yaml.schemas = vim.tbl_deep_extend('force', new_config.settings.yaml.schemas or {}, require('schemastore').yaml.schemas())
          end,
          settings = {
            redhat = { telemetry = { enabled = false } },
            yaml = {
              keyOrdering = false,
              format = {
                enable = true,
              },
              validate = true,
              schemaStore = {
                -- Must disable built-in schemaStore support to use
                -- schemas from SchemaStore.nvim plugin
                enable = false,
                -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
                url = '',
              },
            },
          },
        },
        zls = {},
      }

      local has_blink, blink = pcall(require, 'blink.cmp')
      local capabilities = vim.tbl_deep_extend('force', {}, vim.lsp.protocol.make_client_capabilities(), has_blink and blink.get_lsp_capabilities() or {})

      local function setup(server)
        local server_opts = vim.tbl_deep_extend('force', {
          capabilities = vim.deepcopy(capabilities),
        }, servers[server] or {})
        if server_opts.enabled == false then
          return
        end

        vim.lsp.config(server, server_opts)
        local is_enabled = true
        if server_opts.root_markers then
          is_enabled = false
          local cwd = vim.fn.getcwd()
          for _, marker in ipairs(server_opts.root_markers) do
            local marker_path = cwd .. '/' .. marker
            if vim.fn.filereadable(marker_path) == 1 then
              is_enabled = true
              break
            end
          end
        end
        vim.lsp.enable(server, is_enabled)
      end

      local ensure_installed = {} ---@type string[]
      for server, server_opts in pairs(servers) do
        if server_opts and server_opts.mason ~= false then
          ensure_installed[#ensure_installed + 1] = server
        end
        setup(server)
      end

      vim.list_extend(ensure_installed, {
        'codelldb',
        'delve',
        'goimports',
        'goimports-reviser',
        'gofumpt',
        'gomodifytags',
        'impl',
        'js-debug-adapter',
        'kulala-fmt',
        'markdownlint-cli2',
        'markdown-toc',
        'prettier',
        'prettierd',
        'shellharden',
        'shfmt',
        'sqlfluff',
        'stylua',
        'typstyle',
      })

      require('mason-tool-installer').setup { ensure_installed = ensure_installed }
    end,
  },
  ---@module 'rustaceanvim'
  {
    'mrcjkb/rustaceanvim',
    version = '^5',
    ft = { 'rust' },
    ---@type rustaceanvim.Config
    opts = {
      tools = { float_win_config = { border = 'rounded' } },
      server = {
        on_attach = function(_, bufnr)
          vim.keymap.set('n', '<leader>dr', function()
            vim.cmd.RustLsp 'debuggables'
          end, { desc = 'Rust Debuggables', buffer = bufnr })
        end,
        default_settings = {
          -- rust-analyzer language server configuration
          ['rust-analyzer'] = {
            cargo = {
              allFeatures = true,
              loadOutDirsFromCheck = true,
              buildScripts = {
                enable = true,
              },
            },
            -- Add clippy lints for Rust.
            checkOnSave = true,
            procMacro = {
              enable = true,
              ignored = {
                ['async-trait'] = { 'async_trait' },
                ['napi-derive'] = { 'napi' },
                ['async-recursion'] = { 'async_recursion' },
              },
            },
          },
        },
      },
    },
    config = function(_, opts)
      vim.g.rustaceanvim = vim.tbl_deep_extend('keep', vim.g.rustaceanvim or {}, opts or {})
      if vim.fn.executable 'rust-analyzer' == 0 then
        vim.notify('rust-analyzer not found in PATH, please install it.\nhttps://rust-analyzer.github.io/', vim.log.levels.ERROR, { title = 'rustaceanvim' })
      end
    end,
  },
  ---@module 'crates'
  {
    'Saecki/crates.nvim',
    event = { 'BufRead Cargo.toml' },
    ---@type crates.UserConfig
    opts = {
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
  },
  {
    'vuki656/package-info.nvim',
    event = { 'BufRead package.json' },
    opts = {
      colors = {
        up_to_date = '#a6e3a1',
        outdated = '#f9e2af',
        invalid = '#f38ba8',
      },
      package_manager = 'pnpm',
    },
    config = function(_, opts)
      require('package-info').setup(opts)
      vim.cmd([[highlight PackageInfoUpToDateVersion guifg=]] .. opts.colors.up_to_date)
      vim.cmd([[highlight PackageInfoOutdatedVersion guifg=]] .. opts.colors.outdated)
      vim.cmd([[highlight PackageInfoInErrorVersion guifg=]] .. opts.colors.invalid)
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
