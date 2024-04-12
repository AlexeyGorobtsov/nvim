return {
  "nvimtools/none-ls.nvim",
  dependencies = {
    "nvimtools/none-ls-extras.nvim",
  },
  config = function()
    local null_ls = require("null-ls")

    null_ls.setup({
      sources = {
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.formatting.prettier,
        require("none-ls.diagnostics.eslint_d"),
        require("none-ls.code_actions.eslint_d"),
        require("none-ls.formatting.eslint_d"),
      },
    })

    vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})

    -- Keybind for ESLint's sort-imports fix
    vim.keymap.set("n", "<leader>gs", function()
      local eslint_d = null_ls.builtins.code_actions.eslint_d.with({
        command = "eslint_d --fix-type=problem --stdin-filename ${INPUT}",
        args = { "--fix-type", "problem" },
      })
      null_ls.run(eslint_d, { method = "textDocument/codeAction" })
    end, { desc = "Sort imports with ESLint" })
  end,
}
