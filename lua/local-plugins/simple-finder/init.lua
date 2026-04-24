local M = {}

local EXCLUDE_DIRS = {
  ".git", ".husky", "node_modules", "dist", "build",
  ".next", ".nuxt", "target", "out", ".cache",
  ".vscode", ".idea", "__pycache__", ".pytest_cache",
  "vendor", "coverage", ".DS_Store", "tmp", "temp",
}

local function get_find_excludes()
  local excludes = {}
  for _, dir in ipairs(EXCLUDE_DIRS) do
    table.insert(excludes, "! -path '*/" .. dir .. "/*'")
  end
  return table.concat(excludes, " ")
end

local function get_grep_excludes()
  local parts = {}
  for _, dir in ipairs(EXCLUDE_DIRS) do
    table.insert(parts, "--exclude-dir=" .. dir)
  end
  return table.concat(parts, " ")
end

-- 🔍 Поиск файлов (интерактивный)
M.find_files = function()
  vim.ui.input({ prompt = "🔍 Найти файл (glob): ", default = "*" }, function(pattern)
    if not pattern or pattern == "" then return end

    local excludes = get_find_excludes()
    local cmd = string.format(
      "find . -type f -iname %s %s 2>/dev/null | head -n 500",
      vim.fn.shellescape("*" .. pattern .. "*"),
      excludes
    )

    vim.fn.jobstart(cmd, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        if data and #data > 1 then
          local files = vim.tbl_filter(function(line)
            return line ~= ""
          end, data)

          if #files == 0 then
            vim.notify("❌ Файлы не найдены", vim.log.levels.WARN)
            return
          end

          -- Формируем список для quickfix
          local qf_list = {}
          for _, file in ipairs(files) do
            table.insert(qf_list, {
              filename = file,
              lnum = 1,
              col = 1,
              text = file,
            })
          end

          vim.fn.setqflist(qf_list, 'r')
          vim.cmd('copen')
          vim.notify(string.format("✓ Найдено файлов: %d", #qf_list), vim.log.levels.INFO)
        else
          vim.notify("❌ Файлы не найдены", vim.log.levels.WARN)
        end
      end,
    })
  end)
end

-- 📁 Поиск директорий (интерактивный)
M.find_directories = function()
  vim.ui.input({ prompt = "📁 Найти папку: ", default = "" }, function(pattern)
    if not pattern or pattern == "" then return end

    local excludes = get_find_excludes()
    local cmd = string.format(
      "find . -type d -iname %s %s 2>/dev/null | head -n 200",
      vim.fn.shellescape("*" .. pattern .. "*"),
      excludes
    )

    vim.fn.jobstart(cmd, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        if data and #data > 1 then
          local dirs = vim.tbl_filter(function(line)
            return line ~= "" and line ~= "."
          end, data)

          if #dirs == 0 then
            vim.notify("❌ Папки не найдены", vim.log.levels.WARN)
            return
          end

          vim.ui.select(dirs, {
            prompt = "Выберите папку:",
          }, function(choice)
            if choice then
              vim.cmd('cd ' .. vim.fn.fnameescape(choice))
              vim.notify('📁 ' .. choice, vim.log.levels.INFO)
            end
          end)
        else
          vim.notify("❌ Папки не найдены", vim.log.levels.WARN)
        end
      end,
    })
  end)
end

-- 📄 Буферы (с фильтром)
M.find_buffers = function()
  local buffers = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" then
        table.insert(buffers, {
          filename = name,
          bufnr = buf,
        })
      end
    end
  end

  if #buffers == 0 then
    vim.notify("❌ Нет открытых буферов", vim.log.levels.WARN)
    return
  end

  vim.ui.input({ prompt = "🔍 Фильтр буферов: ", default = "" }, function(pattern)
    if not pattern then return end

    local filtered = buffers
    if pattern ~= "" then
      filtered = vim.tbl_filter(function(b)
        return b.filename:lower():find(pattern:lower(), 1, true)
      end, buffers)
    end

    if #filtered == 0 then
      vim.notify("❌ Буферы не найдены", vim.log.levels.WARN)
      return
    end

    local qf_list = {}
    for _, buf in ipairs(filtered) do
      table.insert(qf_list, {
        filename = buf.filename,
        bufnr = buf.bufnr,
        lnum = 1,
        text = buf.filename,
      })
    end

    vim.fn.setqflist(qf_list, 'r')
    vim.cmd('copen')
  end)
end

-- 🕐 Недавние файлы (с фильтром)
M.recent_files = function()
  local oldfiles = {}
  for _, file in ipairs(vim.v.oldfiles) do
    if vim.fn.filereadable(file) == 1 then
      table.insert(oldfiles, file)
      if #oldfiles >= 100 then break end
    end
  end

  if #oldfiles == 0 then
    vim.notify("❌ Нет недавних файлов", vim.log.levels.WARN)
    return
  end

  vim.ui.input({ prompt = "🕐 Фильтр недавних: ", default = "" }, function(pattern)
    if not pattern then return end

    local filtered = oldfiles
    if pattern ~= "" then
      filtered = vim.tbl_filter(function(f)
        return f:lower():find(pattern:lower(), 1, true)
      end, oldfiles)
    end

    if #filtered == 0 then
      vim.notify("❌ Файлы не найдены", vim.log.levels.WARN)
      return
    end

    local qf_list = {}
    for _, file in ipairs(filtered) do
      table.insert(qf_list, {
        filename = file,
        lnum = 1,
        text = file,
      })
    end

    vim.fn.setqflist(qf_list, 'r')
    vim.cmd('copen')
  end)
end

-- 🔀 Git файлы (с фильтром)
M.git_files = function()
  if vim.fn.isdirectory('.git') == 0 then
    vim.notify("❌ Not a git repository", vim.log.levels.ERROR)
    return
  end

  vim.ui.input({ prompt = "🔀 Фильтр git файлов: ", default = "" }, function(pattern)
    if not pattern then return end

    local cmd = "git ls-files"
    if pattern ~= "" then
      cmd = cmd .. " | grep -i " .. vim.fn.shellescape(pattern)
    end

    vim.fn.jobstart(cmd, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        if data and #data > 1 then
          local files = vim.tbl_filter(function(line)
            return line ~= ""
          end, data)

          if #files == 0 then
            vim.notify("❌ Файлы не найдены", vim.log.levels.WARN)
            return
          end

          local qf_list = {}
          for _, file in ipairs(files) do
            table.insert(qf_list, {
              filename = file,
              lnum = 1,
              text = file,
            })
          end

          vim.fn.setqflist(qf_list, 'r')
          vim.cmd('copen')
          vim.notify(string.format("✓ Найдено: %d", #files), vim.log.levels.INFO)
        else
          vim.notify("❌ Файлы не найдены", vim.log.levels.WARN)
        end
      end,
    })
  end)
end

-- 🔎 Grep
M.live_grep = function()
  local excludes = get_grep_excludes()

  vim.ui.input({ prompt = "🔎 Grep: " }, function(pattern)
    if not pattern or pattern == "" then return end

    local cmd = string.format(
      "grep -rn -I %s -e %s . 2>/dev/null",
      excludes,
      vim.fn.shellescape(pattern)
    )

    vim.cmd('cexpr system("' .. cmd:gsub('"', '\\"') .. '")')

    local qf_list = vim.fn.getqflist()
    if #qf_list > 0 then
      vim.cmd('copen')
      vim.notify(string.format("✓ Найдено: %d", #qf_list), vim.log.levels.INFO)
    else
      vim.notify("❌ Совпадений не найдено", vim.log.levels.WARN)
    end
  end)
end

-- 🔍 Поиск по пути (как telescope find_files, но в quickfix)
-- Ввод: src/pages/verif → найдёт все совпадения
M.find_path = function()
  vim.ui.input({ prompt = "📍 Путь: " }, function(pattern)
    if not pattern or pattern == "" then return end

    -- Извлекаем номер строки если есть (file.jsx:30 или file.jsx 30:0)
    local line_num = nil
    local clean_pattern = pattern

    -- Формат: file.jsx:30:5 или file.jsx:30
    local path_part, line_part = pattern:match("^(.+):(%d+)")
    if path_part then
      clean_pattern = path_part
      line_num = tonumber(line_part)
    else
      -- Формат webpack: file.jsx 30:0-20
      path_part, line_part = pattern:match("^(.+)%s+(%d+):")
      if path_part then
        clean_pattern = path_part
        line_num = tonumber(line_part)
      end
    end

    -- Убираем ./ в начале
    clean_pattern = clean_pattern:gsub("^%./", "")

    -- Экранируем для grep
    local grep_pattern = clean_pattern:gsub("([%.%[%]%(%)%+%-%*%?%^%$])", "\\%1")

    local excludes = get_find_excludes()
    local cmd = string.format(
      "find . -type f %s 2>/dev/null | grep -i %s | head -n 100",
      excludes,
      vim.fn.shellescape(grep_pattern)
    )

    vim.fn.jobstart(cmd, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        if data and #data > 1 then
          local files = vim.tbl_filter(function(line)
            return line ~= ""
          end, data)

          if #files == 0 then
            vim.notify("❌ Файлы не найдены: " .. clean_pattern, vim.log.levels.WARN)
            return
          end

          -- Если ровно 1 файл — сразу открываем
          if #files == 1 then
            vim.cmd('edit ' .. vim.fn.fnameescape(files[1]))
            if line_num then
              vim.api.nvim_win_set_cursor(0, { line_num, 0 })
              vim.cmd('normal! zz')
            end
            vim.notify("📍 " .. files[1] .. (line_num and ":" .. line_num or ""), vim.log.levels.INFO)
            return
          end

          -- Иначе → quickfix
          local qf_list = {}
          for _, file in ipairs(files) do
            table.insert(qf_list, {
              filename = file,
              lnum = line_num or 1,
              col = 1,
              text = file,
            })
          end

          vim.fn.setqflist(qf_list, 'r')
          vim.cmd('copen')
          vim.notify(string.format("✓ Найдено: %d", #files), vim.log.levels.INFO)
        else
          vim.notify("❌ Файлы не найдены", vim.log.levels.WARN)
        end
      end,
    })
  end)
end

-- ℹ️ Проверка
M.check = function()
  print("✓ Simple Finder")
  print("📁 Excluded: " .. table.concat(EXCLUDE_DIRS, ", "))
end

M.show_help = function()
  local help = {
    "╔══════════════════════════════════════════════════╗",
    "║      🔍 Simple Finder - Горячие клавиши          ║",
    "╚══════════════════════════════════════════════════╝",
    "",
    "📁 Поиск (через Quickfix):",
    "  <C-p>       найти файлы (вводишь имя → QF)",
    "  <leader>ff  найти файлы",
    "  <leader>fd  найти папки (cd)",
    "  <leader>fb  буферы (фильтр)",
    "  <leader>fG  git файлы (фильтр)",
    "  <leader>fr  недавние (фильтр)",
    "",
    "🔎 Поиск текста:",
    "  <leader>fg  grep → quickfix",
    "",
    "📂 Навигация по директориям:",
    "  <leader>fc  lcd в папку текущего файла",
    "",
    "💡 Работа с Quickfix:",
    "  Enter       открыть файл",
    "  :cnext / :cp  следующий/предыдущий",
    "  :copen      открыть список",
    "  :cclose     закрыть список",
    "  :cexp []     очистить список",
    "",
    "❓ Помощь: <leader>f?",
  }

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, help)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  local width = 54
  local height = #help
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
  })

  vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = buf })
  vim.keymap.set('n', '<Esc>', '<cmd>close<cr>', { buffer = buf })
end


return M
