local M = {}

local EXCLUDE_DIRS = {
  ".git", ".husky", "node_modules", "dist", "build",
  ".next", ".nuxt", "target", "out", ".cache",
  ".vscode", ".idea", "__pycache__", ".pytest_cache",
  "vendor", "coverage", ".DS_Store", "tmp", "temp",
}

local function get_rg_excludes()
  local parts = {}
  for _, dir in ipairs(EXCLUDE_DIRS) do
    table.insert(parts, "--glob '!" .. dir .. "/**'")
    table.insert(parts, "--glob '!" .. dir .. "'")
  end
  return table.concat(parts, " ")
end

-- Базовые флаги rg: уважаем .gitignore, скрытые включены, но .git исключён, smart-case
local function rg_base()
  return "rg --hidden --smart-case " .. get_rg_excludes()
end

-- 🔍 Поиск файлов (интерактивный)
M.find_files = function()
  vim.ui.input({ prompt = "🔍 Найти файл (glob): ", default = "*" }, function(pattern)
    if not pattern or pattern == "" then return end

    local cmd = string.format(
      "%s --files --iglob %s 2>/dev/null | head -n 500",
      rg_base(),
      vim.fn.shellescape("*" .. pattern .. "*")
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
-- rg не ищет директории напрямую — получаем список файлов и извлекаем уникальные директории
M.find_directories = function()
  vim.ui.input({ prompt = "📁 Найти папку: ", default = "" }, function(pattern)
    if not pattern or pattern == "" then return end

    local cmd = string.format(
      "%s --files --null 2>/dev/null | xargs -0 -n1 dirname | sort -u | grep -i %s | head -n 200",
      rg_base(),
      vim.fn.shellescape(pattern)
    )

    vim.fn.jobstart({ "sh", "-c", cmd }, {
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

-- 🔀 Git файлы (с фильтром через rg)
M.git_files = function()
  if vim.fn.isdirectory('.git') == 0 then
    vim.notify("❌ Not a git repository", vim.log.levels.ERROR)
    return
  end

  vim.ui.input({ prompt = "🔀 Фильтр git файлов: ", default = "" }, function(pattern)
    if not pattern then return end

    local cmd
    if pattern == "" then
      cmd = "git ls-files"
    else
      cmd = "git ls-files | rg --smart-case " .. vim.fn.shellescape(pattern)
    end

    vim.fn.jobstart({ "sh", "-c", cmd }, {
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

-- 🔎 Grep через rg (не-live, по Enter)
M.live_grep = function()
  vim.ui.input({ prompt = "🔎 Grep: " }, function(pattern)
    if not pattern or pattern == "" then return end

    local cmd = string.format(
      "%s --vimgrep --no-heading -- %s 2>/dev/null",
      rg_base(),
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

-- 🔍 Поиск по пути
M.find_path = function()
  vim.ui.input({ prompt = "📍 Путь: " }, function(pattern)
    if not pattern or pattern == "" then return end

    local line_num = nil
    local clean_pattern = pattern

    local path_part, line_part = pattern:match("^(.+):(%d+)")
    if path_part then
      clean_pattern = path_part
      line_num = tonumber(line_part)
    else
      path_part, line_part = pattern:match("^(.+)%s+(%d+):")
      if path_part then
        clean_pattern = path_part
        line_num = tonumber(line_part)
      end
    end

    clean_pattern = clean_pattern:gsub("^%./", "")

    -- rg --files + фильтрация через rg по подстроке пути
    local cmd = string.format(
      "%s --files 2>/dev/null | rg --smart-case %s | head -n 100",
      rg_base(),
      vim.fn.shellescape(clean_pattern)
    )

    vim.fn.jobstart({ "sh", "-c", cmd }, {
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

          if #files == 1 then
            vim.cmd('edit ' .. vim.fn.fnameescape(files[1]))
            if line_num then
              vim.api.nvim_win_set_cursor(0, { line_num, 0 })
              vim.cmd('normal! zz')
            end
            vim.notify("📍 " .. files[1] .. (line_num and ":" .. line_num or ""), vim.log.levels.INFO)
            return
          end

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
  print("✓ Simple Finder (rg)")
  print("📁 Excluded: " .. table.concat(EXCLUDE_DIRS, ", "))
  if vim.fn.executable('rg') == 0 then
    print("⚠️  ripgrep (rg) не установлен!")
  else
    print("✓ ripgrep найден: " .. vim.fn.exepath('rg'))
  end
end

M.show_help = function()
  local help = {
    "╔══════════════════════════════════════════════════╗",
    "║      🔍 Simple Finder (rg) - Горячие клавиши     ║",
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
    "",
    "⚙️  rg: --hidden --smart-case + .gitignore + EXCLUDE_DIRS",
    "",
    "❓ Помощь: <leader>f?",
  }

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, help)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  local width = 54
  local height = #help
  vim.api.nvim_open_win(buf, true, {
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
