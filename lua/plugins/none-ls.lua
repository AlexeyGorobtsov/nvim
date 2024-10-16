return {
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				css = { "prettier" },
				html = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
				groovy = { "npm-groovy-lint" },
			},
			format_on_save = {
				timeout_ms = 3000,
				lsp_fallback = true,
			},
		},
		config = function(_, opts)
			require("conform").setup(opts)
			vim.keymap.set({ "n", "v" }, "<leader>gf", function()
				require("conform").format({
					lsp_fallback = true,
					async = true,
					timeout_ms = 3000,
				})
			end, { desc = "Format file or range (in visual mode)" })
		end,
	},
	{
		"mfussenegger/nvim-lint",
		event = "BufWritePost",
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = {
				javascript = { "eslint" },
				typescript = { "eslint" },
				javascriptreact = { "eslint" },
				typescriptreact = { "eslint" },
				groovy = { "npm-groovy-lint" },
			}

			vim.api.nvim_create_autocmd("BufWritePost", {
				callback = function()
					lint.try_lint()
				end,
			})

			vim.keymap.set("n", "<leader>gl", lint.try_lint, { desc = "Trigger linting for current file" })
			vim.keymap.set("n", "<leader>gs", function()
				vim.cmd("!eslint --fix %")
			end, { noremap = true, silent = true })
		end,
	},
}
