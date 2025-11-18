-- plugins/local-finder.lua
return {
  {
    name = "simple-finder",
    dir = vim.fn.stdpath("config") .. "/lua/local-plugins/simple-finder",
    lazy = false,
    config = function()
      local finder = require("local-plugins.simple-finder")

      -- Команды
      vim.api.nvim_create_user_command("FindFiles", finder.find_files, {})
      vim.api.nvim_create_user_command("FindDirs", finder.find_directories, {})
      vim.api.nvim_create_user_command("FindBuffers", finder.find_buffers, {})
      vim.api.nvim_create_user_command("FindRecent", finder.recent_files, {})
      vim.api.nvim_create_user_command("FindGit", finder.git_files, {})
      vim.api.nvim_create_user_command("FindGrep", finder.live_grep, {})
      vim.api.nvim_create_user_command("FindCheck", finder.check, {})
      vim.api.nvim_create_user_command("FindHelp", finder.show_help, {})
    end,

    keys = {
      { "<C-p>",      function() require("local-plugins.simple-finder").find_files() end,       desc = "Find Files" },
      { "<leader>ff", function() require("local-plugins.simple-finder").find_files() end,       desc = "Find Files" },
      { "<leader>fd", function() require("local-plugins.simple-finder").find_directories() end, desc = "Find Dirs" },
      { "<leader>fb", function() require("local-plugins.simple-finder").find_buffers() end,     desc = "Buffers" },
      { "<leader>fg", function() require("local-plugins.simple-finder").live_grep() end,        desc = "Grep (QF)" },
      { "<leader>fG", function() require("local-plugins.simple-finder").git_files() end,        desc = "Git Files" },
      { "<leader>fr", function() require("local-plugins.simple-finder").recent_files() end,     desc = "Recent" },
      { "<leader>f?", function() require("local-plugins.simple-finder").show_help() end,        desc = "Finder Help" },
    },
  },
}
