return {
  name = "cl",
  dir = vim.fn.stdpath("config") .. "/lua/local-plugins/cl",
  history_file = vim.fn.stdpath("data") .. "/claude_batches/history.md",
  config = function()
    require("local-plugins.cl").setup()
  end,
}
