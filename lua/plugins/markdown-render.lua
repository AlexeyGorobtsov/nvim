return {
  {
    name = "markdown-render",
    dir = vim.fn.stdpath("config") .. "/lua/local-plugins/markdown-render",
    event = "VeryLazy",
    config = function()
      require("local-plugins.markdown-render").setup({
        auto_enable = false,
      })
    end,
  },
}
