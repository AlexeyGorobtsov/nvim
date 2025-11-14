return {
  {
    name = "local-fzf",
    dir = vim.fn.stdpath("config") .. "/lua/local-plugins/fzf",
    lazy = false,
    config = function()
      local fzf = require("local-plugins.fzf")
      
      -- Команды (обернуты в функции)
      vim.api.nvim_create_user_command("FzfFiles", function()
        fzf.find_files()
      end, {})
      
      vim.api.nvim_create_user_command("FzfDirs", function()
        fzf.find_directories()
      end, {})
      
      vim.api.nvim_create_user_command("FzfBuffers", function()
        fzf.find_buffers()
      end, {})
      
      vim.api.nvim_create_user_command("FzfGrep", function()
        fzf.live_grep()
      end, {})
      
      vim.api.nvim_create_user_command("FzfRecent", function()
        fzf.recent_files()
      end, {})
      
      vim.api.nvim_create_user_command("FzfGit", function()
        fzf.git_files()
      end, {})
      
      vim.api.nvim_create_user_command("FzfCheck", function()
        fzf.check_fzf()
      end, {})
    end,
    keys = {
      { 
        "<C-p>", 
        function() 
          require("local-plugins.fzf").find_files() 
        end, 
        desc = "Find Files" 
      },
      { 
        "<leader>ff", 
        function() 
          require("local-plugins.fzf").find_files() 
        end, 
        desc = "Find Files" 
      },
      { 
        "<leader>fd", 
        function() 
          require("local-plugins.fzf").find_directories() 
        end, 
        desc = "Find Dirs" 
      },
      { 
        "<leader>fb", 
        function() 
          require("local-plugins.fzf").find_buffers() 
        end, 
        desc = "Buffers" 
      },
      { 
        "<leader>fg", 
        function() 
          require("local-plugins.fzf").live_grep() 
        end, 
        desc = "Grep" 
      },
      { 
        "<leader>fr", 
        function() 
          require("local-plugins.fzf").recent_files() 
        end, 
        desc = "Recent" 
      },
      { 
        "<leader>fG", 
        function() 
          require("local-plugins.fzf").git_files() 
        end, 
        desc = "Git Files" 
      },
    },
  },
}
