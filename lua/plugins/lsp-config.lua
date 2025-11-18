return {
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      -- Включаем встроенное автодополнение
      vim.opt.completeopt = { "menu", "menuone", "noselect" }
      -- ✅ НАСТРОЙКА ПУТЕЙ ДЛЯ АВТОДОПОЛНЕНИЯ
      vim.opt.path = {
        ".",                    -- текущая папка
        "src/**",               -- рекурсивно в src
        "**",                   -- рекурсивно везде
      }

      vim.opt.wildignore = {
        "*/node_modules/*",
        "*/.git/*",
        "*/dist/*",
        "*/build/*",
        "*.pyc",
        "*.o",
        "*.obj",
      }
  
      vim.opt.suffixesadd = { ".js", ".jsx", ".ts", ".tsx", ".json" }
      -- ==========================================
-- АВТОДОПОЛНЕНИЕ ДЛЯ macOS
-- ==========================================

-- Omnifunc для LSP
vim.opt.omnifunc = "v:lua.vim.lsp.omnifunc"

-- Автодополнение по Tab (как раньше)
vim.keymap.set("i", "<Tab>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-n>"
  else
    return "<Tab>"
  end
end, { expr = true })

vim.keymap.set("i", "<S-Tab>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-p>"
  else
    return "<S-Tab>"
  end
end, { expr = true })

-- Подтверждение через Enter (как раньше)
vim.keymap.set("i", "<CR>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-y>"
  else
    return "<CR>"
  end
end, { expr = true })

-- ✅ НОВЫЕ МАППИНГИ ДЛЯ LSP (без Ctrl+Space)

-- Ctrl+l - LSP автодополнение (ОСНОВНОЙ)
vim.keymap.set("i", "<C-l>", "<C-x><C-o>", { desc = "LSP completion" })

-- Ctrl+k - Параметры функции (как в вашей конфигурации)
-- Это НЕ будет конфликтовать

-- Alt/Option+Space - альтернатива
vim.keymap.set("i", "<M-Space>", "<C-x><C-o>", { desc = "LSP completion" })

-- Ctrl+f - автодополнение путей файлов
vim.keymap.set("i", "<C-f>", "<C-x><C-f>", { desc = "File path completion" })

-- Ctrl+n - умное автодополнение
vim.keymap.set("i", "<C-n>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-n>"
  else
    local line = vim.api.nvim_get_current_line()
    local before_cursor = line:sub(1, vim.api.nvim_win_get_cursor(0)[2])
    
    if before_cursor:match("from%s+['\"]") or before_cursor:match("import.*['\"]") then
      return "<C-x><C-o>"  -- LSP для импортов
    else
      return "<C-n>"  -- обычное
    end
  end
end, { expr = true, desc = "Smart completion" })
      -- Автодополнение по <Tab>
      vim.keymap.set("i", "<Tab>", function()
        if vim.fn.pumvisible() == 1 then
          return "<C-n>"
        else
          return "<Tab>"
        end
      end, { expr = true })
      
      vim.keymap.set("i", "<S-Tab>", function()
        if vim.fn.pumvisible() == 1 then
          return "<C-p>"
        else
          return "<S-Tab>"
        end
      end, { expr = true })

      -- Подтверждение через Enter
      vim.keymap.set("i", "<CR>", function()
        if vim.fn.pumvisible() == 1 then
          return "<C-y>"
        else
          return "<CR>"
        end
      end, { expr = true })

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.textDocument.completion.completionItem.snippetSupport = true

      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      -- TypeScript/JavaScript
      vim.lsp.config.ts_ls = {
        cmd = { "typescript-language-server", "--stdio" },
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
        root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
        settings = {
          typescript = {
            inlayHints = {
              includeInlayParameterNameHints = 'all',
            },
            suggest = {
              autoImports = true,
              paths = true,
            },
            preferences = {
              includePackageJsonAutoImports = "on",
              importModuleSpecifierPreference = "relative",
              importModuleSpecifierEnding = "minimal",  -- без .js
            },
          },
          javascript = {
            inlayHints = {
              includeInlayParameterNameHints = 'all',
            },
            suggest = {
              autoImports = true,
              paths = true,
            },
            preferences = {
              includePackageJsonAutoImports = "on",
              importModuleSpecifierPreference = "relative",  -- ← ВАЖНО!
              importModuleSpecifierEnding = "minimal",
              quotePreference = "single",  -- использовать одинарные кавычки
            },
          },
        },
        init_options = {
          preferences = {
            includeCompletionsForModuleExports = true,
            includeCompletionsWithInsertText = true,
            includeCompletionsForImportStatements = true,
          },
        },
      }
      -- ESLint LSP
      vim.lsp.config.eslint = {
        cmd = { "vscode-eslint-language-server", "--stdio" },
        filetypes = { 
          "javascript", 
          "javascriptreact", 
          "typescript", 
          "typescriptreact", 
          "vue", 
          "svelte" 
        },
        root_markers = { 
          "eslint.config.js",
          "eslint.config.mjs",
          "eslint.config.cjs",
          ".eslintrc.js", 
          ".eslintrc.json", 
          "package.json", 
          ".git" 
        },
        settings = {
          validate = "on",
          rulesCustomizations = {},
          run = "onType",
          nodePath = "",
          workingDirectory = { mode = "auto" },
        },
      }

      -- HTML
      vim.lsp.config.html = {
        cmd = { "vscode-html-language-server", "--stdio" },
        filetypes = { "html" },
        root_markers = { "package.json", ".git" },
      }

      -- CSS
      vim.lsp.config.cssls = {
        cmd = { "vscode-css-language-server", "--stdio" },
        filetypes = { "css", "scss", "less" },
        root_markers = { "package.json", ".git" },
      }

      -- JSON
      vim.lsp.config.jsonls = {
        cmd = { "vscode-json-language-server", "--stdio" },
        filetypes = { "json", "jsonc" },
        root_markers = { "package.json", ".git" },
      }

      -- Lua
      vim.lsp.config.lua_ls = {
        cmd = { "lua-language-server" },
        filetypes = { "lua" },
        root_markers = { ".luarc.json", ".luacheckrc", ".stylua.toml", ".git" },
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = {
              library = { vim.env.VIMRUNTIME },
              checkThirdParty = false,
            },
            telemetry = { enable = false },
          },
        },
      }

      -- Включить серверы
      vim.lsp.enable({
        "ts_ls",
        "eslint",
        "html",
        "cssls",
        "jsonls",
        "lua_ls",
      })

      -- Горячие клавиши при подключении LSP
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)

          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
          end

                    -- Организовать импорты (добавить недостающие)
          map("n", "<leader>oi", function()
            vim.lsp.buf.code_action({
              apply = true,
              context = {
                only = { "source.addMissingImports.ts" },
                diagnostics = {},
              },
            })
          end, "Organize Imports: Add Missing")

          -- Удалить неиспользуемые импорты
          map("n", "<leader>ou", function()
            vim.lsp.buf.code_action({
              apply = true,
              context = {
                only = { "source.removeUnused.ts" },
                diagnostics = {},
              },
            })
          end, "Organize Imports: Remove Unused")

          -- Все импорты сразу (добавить + удалить лишние)
          map("n", "<leader>oa", function()
            vim.lsp.buf.code_action({
              apply = true,
              context = {
                only = { "source.organizeImports.ts" },
                diagnostics = {},
              },
            })
          end, "Organize All Imports")


          -- Навигация
          map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
          map("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
          map("n", "gr", vim.lsp.buf.references, "References")
          map("n", "gi", vim.lsp.buf.implementation, "Implementation")
          map("n", "K", vim.lsp.buf.hover, "Hover")
          map("n", "<C-k>", vim.lsp.buf.signature_help, "Signature Help")

          -- Действия
          map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
          map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")
          map("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end, "Format")

          -- Справка по LSP
          map("n", "<leader>?", function()
            vim.notify([[
      ═══════════════════════════════════════
               LSP Горячие клавиши
      ═══════════════════════════════════════
      ⚡ АВТОДОПОЛНЕНИЕ (в режиме вставки):
        
        Ctrl+l      - LSP автодополнение ⭐⭐⭐
        Ctrl+f      - файлы и папки
        Ctrl+n      - умное (LSP или обычное)
        Option+Space - LSP (альтернатива)
        
        Tab         - следующий вариант
        Shift+Tab   - предыдущий
        Enter       - выбрать
      📍 НАВИГАЦИЯ:
        gd       - перейти к определению
        gD       - перейти к декларации
        gr       - показать все использования
        gi       - перейти к реализации
        K        - показать документацию
        Ctrl+k   - подсказка параметров

      ⚡ ДЕЙСТВИЯ:
        <leader>rn  - переименовать
        <leader>ca  - быстрые исправления
        <leader>f   - форматировать код

      🔍 ДИАГНОСТИКА:
        [d       - предыдущая ошибка
        ]d       - следующая ошибка
        <leader>e - показать ошибку
        <leader>q - список всех ошибок

      💡 ДОПОЛНИТЕЛЬНО:
        <leader>th - показать/скрыть типы (inlay hints)
        <leader>?  - эта справка

      ═══════════════════════════════════════
      ]], vim.log.levels.INFO)
          end, "LSP Help")

          -- Inlay hints
          if client and client:supports_method("textDocument/inlayHint") then
            map("n", "<leader>th", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }))
            end, "Toggle Inlay Hints")
          end
        end,
      })
      -- Настройка диагностики с иконками
      vim.diagnostic.config({
        virtual_text = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = "󰠠 ",
            [vim.diagnostic.severity.INFO] = " ",
          },
        },
        update_in_insert = false,
        underline = true,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "always",
        },
      })

      -- Навигация по диагностике
      vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous Diagnostic" })
      vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next Diagnostic" })
      vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show Diagnostic" })
      vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostic List" })
    end,
  },
}
