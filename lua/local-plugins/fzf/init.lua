local M = {}

local FZF_BIN = "/Users/18282607/Documents/localhost/fzf/bin/fzf"

-- Список исключаемых папок
local EXCLUDE_DIRS = {
  ".git",
  ".husky",
  "node_modules",
  "dist",
  "build",
  ".next",
  ".nuxt",
  "target",
  "out",
  ".cache",
  ".vscode",
  ".idea",
  "__pycache__",
  ".pytest_cache",
  "vendor",
  "coverage",
  ".DS_Store",
  "tmp",
  "temp",
}

-- Генерируем строку исключений для find
local function get_find_excludes()
  local excludes = {}
  for _, dir in ipairs(EXCLUDE_DIRS) do
    table.insert(excludes, "! -path '*/" .. dir .. "/*'")
  end
  return table.concat(excludes, " ")
end

-- Генерируем строку исключений для grep
local function get_grep_excludes()
  return table.concat(EXCLUDE_DIRS, ",")
end

-- Универсальная функция для fzf
local function fzf_run(source_cmd, sink_fn, fzf_options)
  local options = fzf_options or "--height=40% --reverse --border"
  
  -- Создаем команду
  local cmd = string.format(
    '%s | %s %s',
    source_cmd,
    FZF_BIN,
    options
  )
  
  -- Используем :term для запуска
  vim.cmd('enew') -- новый буфер
  
  local buf = vim.api.nvim_get_current_buf()
  local job_id = vim.fn.termopen(cmd, {
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        vim.cmd('bdelete!') -- закрываем буфер если отменили
        return
      end
      
      -- Получаем выбранную строку (последняя строка в буфере)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local selected = nil
      
      -- Находим последнюю непустую строку (это результат fzf)
      for i = #lines, 1, -1 do
        local line = vim.trim(lines[i])
        if line ~= "" and not line:match("^>") and not line:match("^%s*$") then
          selected = line
          break
        end
      end
      
      vim.cmd('bdelete!') -- закрываем буфер fzf
      
      if selected and selected ~= "" then
        sink_fn(selected)
      end
    end,
  })
  
  -- Переходим в режим терминала
  vim.cmd('startinsert')
end

-- Поиск файлов
M.find_files = function()
  local excludes = get_find_excludes()
  fzf_run(
    "find . -type f " .. excludes .. " 2>/dev/null",
    function(file)
      vim.cmd('edit ' .. vim.fn.fnameescape(file))
    end,
    "--height=40% --reverse --border --prompt='Files> '"
  )
end

-- Поиск папок
M.find_directories = function()
  local excludes = get_find_excludes()
  fzf_run(
    "find . -type d " .. excludes .. " 2>/dev/null",
    function(dir)
      vim.cmd('cd ' .. vim.fn.fnameescape(dir))
      print('📁 ' .. dir)
    end,
    "--height=40% --reverse --border --prompt='Dirs> '"
  )
end

-- Буферы
M.find_buffers = function()
  local buffers = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" then
        table.insert(buffers, name)
      end
    end
  end
  
  if #buffers == 0 then
    print("No buffers")
    return
  end
  
  local tmp = vim.fn.tempname()
  vim.fn.writefile(buffers, tmp)
  
  fzf_run(
    "cat " .. tmp,
    function(file)
      vim.fn.delete(tmp)
      vim.cmd('edit ' .. vim.fn.fnameescape(file))
    end,
    "--height=40% --reverse --border --prompt='Buffers> '"
  )
end

-- Недавние файлы
M.recent_files = function()
  local oldfiles = {}
  for _, file in ipairs(vim.v.oldfiles) do
    if vim.fn.filereadable(file) == 1 then
      table.insert(oldfiles, file)
      if #oldfiles >= 50 then break end
    end
  end
  
  if #oldfiles == 0 then
    print("No recent files")
    return
  end
  
  local tmp = vim.fn.tempname()
  vim.fn.writefile(oldfiles, tmp)
  
  fzf_run(
    "cat " .. tmp,
    function(file)
      vim.fn.delete(tmp)
      vim.cmd('edit ' .. vim.fn.fnameescape(file))
    end,
    "--height=40% --reverse --border --prompt='Recent> '"
  )
end

-- Git файлы
M.git_files = function()
  if vim.fn.isdirectory('.git') == 0 then
    print("Not a git repository")
    return
  end
  
  fzf_run(
    "git ls-files",
    function(file)
      vim.cmd('edit ' .. vim.fn.fnameescape(file))
    end,
    "--height=40% --reverse --border --prompt='Git> '"
  )
end

-- Grep
M.live_grep = function()
  local excludes = get_grep_excludes()
  fzf_run(
    "grep -r -n -I --exclude-dir={" .. excludes .. "} '' . 2>/dev/null",
    function(line)
      local file, lnum = line:match("^([^:]+):(%d+)")
      if file and lnum then
        vim.cmd('edit +' .. lnum .. ' ' .. vim.fn.fnameescape(file))
      end
    end,
    "--height=40% --reverse --border --delimiter=: --prompt='Grep> '"
  )
end

-- Проверка
M.check_fzf = function()
  if vim.fn.executable(FZF_BIN) == 1 then
    print("✓ fzf found at: " .. FZF_BIN)
    local version = vim.fn.system(FZF_BIN .. " --version")
    print("Version: " .. vim.trim(version))
    print("📁 Excluded: " .. table.concat(EXCLUDE_DIRS, ", "))
  else
    print("✗ fzf not found")
  end
end

return M
