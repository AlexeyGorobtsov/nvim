return {
  name = "cl",
  dir = vim.fn.stdpath("config") .. "/lua/local-plugins/cl",
  config = function()
    require("local-plugins.cl").setup({
      provider = "proxy",
      proxy_key = vim.env.CLAUDE_PROXY_KEY,
      model = "claude-haiku-4-5-20251001",
      -- model = "claude-opus-4-8",
    })
  end,
}
