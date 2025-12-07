return {
  {
    name = "harpoon-lite",
    dir = vim.fn.stdpath("config") .. "/lua/local-plugins/harpoon",
    config = function()
      require("local-plugins.harpoon").setup()
    end,
  },
}
