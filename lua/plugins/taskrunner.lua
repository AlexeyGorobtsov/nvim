
return {
  {
    name = "taskrunner",
    dir = vim.fn.stdpath("config") .. "/lua/local-plugins/taskrunner",
    config = function()
      require("local-plugins.taskrunner").setup({
        prefix = "<leader>t",

        -- Твои задачи для фронтенда
        tasks = {
          server = { cmd = "npm run server", hide = true },
          webpack = { cmd = "npm run build -- --watch", hide = true },
          dev = { cmd = "npm run dev", hide = false },
          test = { cmd = "npm test", hide = false },
        },
      })
    end,
  },
}
