return {
	{
		"williamboman/mason.nvim",
		lazy = false,
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		lazy = false,
		opts = { auto_install = true },
	},
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local lspconfig = require("lspconfig")

			-- Existing LSP configurations
			lspconfig.ts_ls.setup({
				capabilities = capabilities,
				init_options = {
					preferences = {
						importModuleSpecifierPreference = "relative",
					},
				},
			})
			lspconfig.html.setup({ capabilities = capabilities })
			lspconfig.lua_ls.setup({ capabilities = capabilities })
			lspconfig.jsonls.setup({ capabilities = capabilities })
			lspconfig.cssls.setup({ capabilities = capabilities })

			-- Updated Groovy LSP configuration
			local mason_path = vim.fn.glob(vim.fn.stdpath("data") .. "/mason/")
			local groovyls_jar = mason_path
				.. "packages/groovy-language-server/build/libs/groovy-language-server-all.jar"

			lspconfig.groovyls.setup({
				capabilities = capabilities,
				cmd = { "java", "-jar", groovyls_jar },
				filetypes = { "groovy" },
				root_dir = lspconfig.util.root_pattern("*.gradle", "*.groovy", ".git"),
				settings = {
					groovy = {
						classpath = {
							-- Add any additional classpath entries here
						},
						console = {
							-- Configure console settings if needed
						},
						trace = {
							server = "verbose",
						},
					},
				},
				on_attach = function(client, bufnr)
					print("groovyls attached to buffer " .. bufnr)

					-- Set up buffer-local keybindings here
					local opts = { noremap = true, silent = true, buffer = bufnr }
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
					vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
					vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
					vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, opts)
					vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
					vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action, opts)
					vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
				end,
				on_init = function(client)
					print("groovyls initialized")
				end,
			})

			-- Diagnostic configuration
			-- vim.diagnostic.config({
			-- 	virtual_text = true,
			-- 	signs = true,
			-- 	underline = true,
			-- 	update_in_insert = false,
			-- 	severity_sort = false,
			-- })

			-- Set up global keybindings
			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {})
			vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, {})
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})

			-- LSP logging configuration
			-- vim.lsp.set_log_level("debug")
			-- require("vim.lsp.log").set_format_func(vim.inspect)
			--
			-- Custom command to restart Groovy LSP
			vim.api.nvim_create_user_command("RestartGroovyLSP", function()
				vim.cmd("LspStop groovyls")
				vim.cmd("sleep 500m") -- Wait for 500ms
				vim.cmd("LspStart groovyls")
			end, {})
		end,
	},
}
