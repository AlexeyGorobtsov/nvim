return {
  {
    name = "cyrillic-highlight",
    dir = vim.fn.stdpath("config") .. "/lua/local-plugins/cyrillic-highlight",
    config = function()
      require("local-plugins.cyrillic-highlight").setup({
        auto_enable = true,
        keymap = true,
      })
    end,
  },
}
