local M = {}

-- Хранилище терминалов
M.terminals = {}
M.last_terminal = nil

-- ══════════════════════════════════════════════════════════
-- Основные функции
-- ══════════════════════════════════════════════════════════

M.height = 15
M.width = 0.4             -- доля ширины экрана для терминала справа
M.position = "bottom"     -- "bottom" | "right"

-- Найти окно с терминалом в текущей вкладке
M._find_win = function()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == "terminal" then
      return win
    end
  end
end

M._width_cols = function()
  return math.floor(vim.o.columns * M.width)
end

-- Перейти в окно терминала или открыть сплит (снизу на всю ширину / справа на всю высоту)
M._open_win = function()
  local win = M._find_win()
  if win then
    vim.api.nvim_set_current_win(win)
  elseif M.position == "right" then
    vim.cmd("botright " .. M._width_cols() .. "vsplit")
  else
    vim.cmd("botright " .. M.height .. "split")
  end
end

-- Переключить расположение терминала: снизу <-> справа
M.toggle_position = function()
  M.position = M.position == "right" and "bottom" or "right"

  local win = M._find_win()
  if win then
    local cur = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(win)
    if M.position == "right" then
      vim.cmd("wincmd L")
      vim.cmd("vertical resize " .. M._width_cols())
    else
      vim.cmd("wincmd J")
      vim.cmd("resize " .. M.height)
    end
    if vim.api.nvim_win_is_valid(cur) then
      vim.api.nvim_set_current_win(cur)
    end
  end

  vim.notify("Terminal position: " .. M.position, vim.log.levels.INFO)
end

-- Создать новый терминал
M.create = function(opts)
  opts = opts or {}

  local name = opts.name or ("term-" .. (#M.terminals + 1))
  local cmd = opts.cmd or nil

  local prev_win = vim.api.nvim_get_current_win()
  local had_win = M._find_win() ~= nil

  -- Открыть терминал в нижнем сплите (новый буфер, старый терминал остаётся в фоне)
  M._open_win()
  vim.cmd("enew")
  if cmd then
    vim.cmd.terminal(cmd)
  else
    vim.cmd.terminal()
  end

  local term_buf = vim.api.nvim_get_current_buf()
  local term_chan = vim.bo.channel

  -- Сохранить терминал
  local terminal = {
    buf = term_buf,
    chan = term_chan,
    name = name,
    cmd = cmd,
    created = os.time(),
  }

  table.insert(M.terminals, terminal)
  M.last_terminal = #M.terminals

  -- Установить имя буфера
  vim.api.nvim_buf_set_name(term_buf, "[" .. #M.terminals .. "] " .. name)

  -- Удалить из списка при закрытии буфера
  vim.api.nvim_create_autocmd("BufDelete", {
    buffer = term_buf,
    callback = function()
      M._remove_by_buf(term_buf)
    end,
  })

  -- Скрыть если нужно
  if opts.hide then
    if had_win then
      vim.cmd("buffer #")
    else
      vim.api.nvim_win_close(0, false)
    end
    if vim.api.nvim_win_is_valid(prev_win) then
      vim.api.nvim_set_current_win(prev_win)
    end
  else
    -- Войти в insert mode
    vim.cmd("startinsert")
  end

  vim.notify("✓ Created: " .. name, vim.log.levels.INFO)

  return terminal
end

-- Добавить текущий терминал в список (если открыт вручную)
M.add = function()
  local buf = vim.api.nvim_get_current_buf()

  if vim.bo[buf].buftype ~= "terminal" then
    vim.notify("Not a terminal buffer", vim.log.levels.WARN)
    return
  end

  -- Проверить, не добавлен ли уже
  for _, term in ipairs(M.terminals) do
    if term.buf == buf then
      vim.notify("Terminal already in list", vim.log.levels.WARN)
      return
    end
  end

  local name = "term-" .. (#M.terminals + 1)

  local terminal = {
    buf = buf,
    chan = vim.bo[buf].channel,
    name = name,
    cmd = nil,
    created = os.time(),
  }

  table.insert(M.terminals, terminal)
  M.last_terminal = #M.terminals

  vim.api.nvim_buf_set_name(buf, "[" .. #M.terminals .. "] " .. name)

  vim.api.nvim_create_autocmd("BufDelete", {
    buffer = buf,
    callback = function()
      M._remove_by_buf(buf)
    end,
  })

  vim.notify("✓ Added: " .. name, vim.log.levels.INFO)
end

-- Удалить терминал из списка по буферу
M._remove_by_buf = function(buf)
  for i, term in ipairs(M.terminals) do
    if term.buf == buf then
      table.remove(M.terminals, i)
      return
    end
  end
end

-- Переименовать терминал
M.rename = function(index)
  local term = M.terminals[index]
  if not term then return end

  vim.ui.input({ prompt = "New name: ", default = term.name }, function(name)
    if name and name ~= "" then
      term.name = name
      if vim.api.nvim_buf_is_valid(term.buf) then
        vim.api.nvim_buf_set_name(term.buf, "[" .. index .. "] " .. name)
      end
      vim.notify("✓ Renamed to: " .. name, vim.log.levels.INFO)
    end
  end)
end

-- Перейти к терминалу по индексу
M.select = function(index)
  -- Очистить невалидные терминалы
  M._cleanup()

  local term = M.terminals[index]
  if not term then
    vim.notify("Terminal " .. index .. " not found", vim.log.levels.WARN)
    return
  end

  if not vim.api.nvim_buf_is_valid(term.buf) then
    vim.notify("Terminal buffer is invalid", vim.log.levels.WARN)
    table.remove(M.terminals, index)
    return
  end

  M.last_terminal = index
  M._open_win()
  vim.api.nvim_set_current_buf(term.buf)
  vim.cmd("startinsert")
end

-- Показать/скрыть нижнее окно терминала
M.toggle = function()
  M._cleanup()
  local win = M._find_win()

  -- Терминал виден — скрыть окно (процесс продолжает работать)
  if win then
    if #vim.api.nvim_tabpage_list_wins(0) > 1 then
      vim.api.nvim_win_close(win, false)
    else
      vim.cmd("buffer #")
    end
    return
  end

  -- Если есть последний терминал — открыть его
  if M.last_terminal and M.terminals[M.last_terminal] then
    M.select(M.last_terminal)
    return
  end

  -- Если терминалов нет — создать новый
  if #M.terminals == 0 then
    M.create()
    return
  end

  -- Перейти к первому терминалу
  M.select(1)
end

-- Отправить команду в терминал
M.send = function(index, command)
  local term = M.terminals[index]
  if not term then return end

  vim.api.nvim_chan_send(term.chan, command .. "\n")
end

-- Остановить терминал (Ctrl+C)
M.stop = function(index)
  local term = M.terminals[index]
  if not term then return end

  vim.api.nvim_chan_send(term.chan, "\x03")
  vim.notify("✓ Sent Ctrl+C to: " .. term.name, vim.log.levels.INFO)
end

-- Закрыть терминал
M.close = function(index)
  local term = M.terminals[index]
  if not term then return end

  if vim.api.nvim_buf_is_valid(term.buf) then
    vim.api.nvim_buf_delete(term.buf, { force = true })
  end

  vim.notify("✓ Closed: " .. term.name, vim.log.levels.INFO)
end

-- Закрыть все терминалы
M.close_all = function()
  for i = #M.terminals, 1, -1 do
    M.close(i)
  end
  vim.notify("✓ All terminals closed", vim.log.levels.INFO)
end

-- Очистить невалидные терминалы
M._cleanup = function()
  for i = #M.terminals, 1, -1 do
    if not vim.api.nvim_buf_is_valid(M.terminals[i].buf) then
      table.remove(M.terminals, i)
    end
  end
end

-- Следующий терминал
M.next = function()
  M._cleanup()
  if #M.terminals == 0 then return end

  local next_idx = (M.last_terminal or 0) % #M.terminals + 1
  M.select(next_idx)
end

-- Предыдущий терминал
M.prev = function()
  M._cleanup()
  if #M.terminals == 0 then return end

  local prev_idx = ((M.last_terminal or 2) - 2) % #M.terminals + 1
  M.select(prev_idx)
end

-- ══════════════════════════════════════════════════════════
-- Задачи (пресеты)
-- ══════════════════════════════════════════════════════════

M.tasks = {}

-- Запустить задачу
M.run_task = function(name)
  local task = M.tasks[name]
  if not task then
    vim.notify("Task not found: " .. name, vim.log.levels.ERROR)
    return
  end

  M.create({
    name = name,
    cmd = task.cmd,
    hide = task.hide,
  })
end

-- ══════════════════════════════════════════════════════════
-- UI: показать список терминалов
-- ══════════════════════════════════════════════════════════

M.menu = function()
  M._cleanup()

  if #M.terminals == 0 then
    vim.notify("No terminals. Press 'c' to create one.", vim.log.levels.INFO)
    -- Создать пустое меню для возможности создания
  end

  local current_buf = vim.api.nvim_get_current_buf()

  local lines = {}
  local max_width = 30

  if #M.terminals == 0 then
    table.insert(lines, "  No terminals")
    table.insert(lines, "")
    table.insert(lines, "  Press 'c' to create")
  else
    for i, term in ipairs(M.terminals) do
      local marker = (term.buf == current_buf) and " ●" or "  "
      local status = vim.api.nvim_buf_is_valid(term.buf) and "running" or "closed"

      -- Время работы
      local uptime = os.time() - term.created
      local mins = math.floor(uptime / 60)
      local time_str = mins > 0 and string.format("(%dm)", mins) or "(new)"

      local line = string.format(" %d%s %s %s %s", i, marker, term.name, time_str, term.cmd or "")
      table.insert(lines, line)
      max_width = math.max(max_width, #line)
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width = math.min(max_width + 4, 80)
  local height = math.max(#lines, 3)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
    style = "minimal",
    border = "rounded",
    title = " Terminals ",
    title_pos = "center",
    footer = " [c]reate [x]close [r]ename [?]help ",
    footer_pos = "center",
  })

  vim.api.nvim_set_option_value("winhl",
    "Normal:Normal,FloatBorder:FloatBorder,FloatTitle:Title,FloatFooter:Comment",
    { win = win }
  )

  local close = function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local opts = { buffer = buf, silent = true }

  -- Закрыть меню
  vim.keymap.set("n", "q", close, opts)
  vim.keymap.set("n", "<Esc>", close, opts)

  -- Выбрать терминал
  vim.keymap.set("n", "<CR>", function()
    local line = vim.fn.line(".")
    if M.terminals[line] then
      close()
      M.select(line)
    end
  end, opts)

  -- Быстрый выбор по номеру
  for i = 1, 9 do
    vim.keymap.set("n", tostring(i), function()
      if M.terminals[i] then
        close()
        M.select(i)
      end
    end, opts)
  end

  -- Создать новый терминал
  vim.keymap.set("n", "c", function()
    close()
    vim.ui.input({ prompt = "Terminal name (optional): " }, function(name)
      M.create({ name = name ~= "" and name or nil })
    end)
  end, opts)

  -- Создать с командой
  vim.keymap.set("n", "C", function()
    close()
    vim.ui.input({ prompt = "Command: " }, function(cmd)
      if cmd and cmd ~= "" then
        vim.ui.input({ prompt = "Name (optional): " }, function(name)
          M.create({
            name = name ~= "" and name or nil,
            cmd = cmd,
          })
        end)
      end
    end)
  end, opts)

  -- Закрыть терминал
  vim.keymap.set("n", "x", function()
    local line = vim.fn.line(".")
    if M.terminals[line] then
      M.close(line)
      close()
      if #M.terminals > 0 then
        M.menu()
      end
    end
  end, opts)

  -- Остановить (Ctrl+C)
  vim.keymap.set("n", "s", function()
    local line = vim.fn.line(".")
    if M.terminals[line] then
      M.stop(line)
    end
  end, opts)

  -- Переименовать
  vim.keymap.set("n", "r", function()
    local line = vim.fn.line(".")
    if M.terminals[line] then
      close()
      M.rename(line)
    end
  end, opts)

  -- Показать help
  vim.keymap.set("n", "?", function()
    close()
    M.help()
  end, opts)
end

-- ══════════════════════════════════════════════════════════
-- UI: показать помощь
-- ══════════════════════════════════════════════════════════

M.help = function()
  local help_lines = {
    "",
    "  ╭──────────────────────────────────────╮",
    "  │        TERMINAL MANAGER HELP         │",
    "  ╰──────────────────────────────────────╯",
    "",
    "  GLOBAL KEYMAPS",
    "  ──────────────────────────────────────",
    "  <C-\\>         Toggle terminal (bottom split)",
    "  <leader>tt    Toggle terminal",
    "  <C-q>         Hide terminal (in terminal)",
    "  <C-h/j/k/l>   Move between windows",
    "  <S-arrows>    Resize window",
    "  <leader>tv    Terminal: bottom <-> right",
    "  <leader>ta    Add current terminal",
    "  <leader>tl    Open terminal menu",
    "  <leader>tc    Create new terminal",
    "  <leader>tx    Close all terminals",
    "",
    "  QUICK SELECT",
    "  ──────────────────────────────────────",
    "  <leader>t1    Go to terminal 1",
    "  <leader>t2    Go to terminal 2",
    "  <leader>t3    Go to terminal 3",
    "  <leader>t4    Go to terminal 4",
    "",
    "  MENU KEYMAPS",
    "  ──────────────────────────────────────",
    "  1-9           Jump to terminal",
    "  <CR>          Open selected terminal",
    "  c             Create new terminal",
    "  C             Create with command",
    "  x             Close terminal",
    "  s             Stop (Ctrl+C)",
    "  r             Rename terminal",
    "  ?             Show this help",
    "  q / <Esc>     Close menu",
    "",
    "  IN TERMINAL",
    "  ──────────────────────────────────────",
    "  <C-\\><C-n>    Exit terminal mode",
    "",
  }

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_lines)

  local ns = vim.api.nvim_create_namespace("terminal_help")

  local highlights = {
    { line = 2,  hl = "Title" },
    { line = 5,  hl = "Function" },
    { line = 18, hl = "Function" },
    { line = 25, hl = "Function" },
    { line = 37, hl = "Function" },
  }

  for _, h in ipairs(highlights) do
    vim.api.nvim_buf_set_extmark(buf, ns, h.line, 0, {
      end_row = h.line,
      end_col = #help_lines[h.line + 1],
      hl_group = h.hl,
    })
  end

  local width = 46
  local height = #help_lines

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
    style = "minimal",
    border = "rounded",
  })

  local close = function()
    vim.api.nvim_win_close(win, true)
  end

  local opts = { buffer = buf, silent = true }

  vim.keymap.set("n", "q", close, opts)
  vim.keymap.set("n", "<Esc>", close, opts)
  vim.keymap.set("n", "?", close, opts)

  vim.keymap.set("n", "<CR>", function()
    close()
    M.menu()
  end, opts)
end

-- ════════════════════════════════════════════
-- Настройка
-- ════════════════════════════════════════════
M.setup = function(opts)
  opts = opts or {}
  local prefix = opts.prefix or "<leader>t"

  -- Сохранить задачи
  if opts.tasks then
    M.tasks = opts.tasks
  end

  M.position = opts.position or M.position
  M.height = opts.height or M.height
  M.width = opts.width or M.width

  -- Основные кеймапы
  vim.keymap.set("n", prefix .. "l", M.menu, { desc = "Terminal menu" })
  vim.keymap.set("n", prefix .. "a", M.add, { desc = "Add terminal to list" })
  vim.keymap.set("n", prefix .. "c", function()
    M.create()
  end, { desc = "Create terminal" })
  vim.keymap.set("n", prefix .. "x", M.close_all, { desc = "Close all terminals" })
  vim.keymap.set("n", prefix .. "?", M.help, { desc = "Terminal help" })
  vim.keymap.set("n", prefix .. "v", M.toggle_position, { desc = "Terminal: bottom <-> right" })

  -- vim.keymap.set("n", "<C-\\>", M.toggle, { desc = "Toggle terminal" })
  -- vim.keymap.set("t", "<C-\\>", "<C-\\><C-n><cmd>lua require('local-plugins.taskrunner').toggle()<CR>", { desc = "Toggle terminal" })
  -- Toggle terminal
  vim.keymap.set("n", "<C-\\>", M.toggle, { desc = "Toggle terminal" })
  vim.keymap.set("t", "<C-\\>", function()
    vim.cmd("stopinsert")
    M.toggle()
  end, { desc = "Toggle terminal" })
  vim.keymap.set("n", prefix .. "t", M.toggle, { desc = "Toggle terminal" })
  vim.keymap.set("t", "<C-q>", function()
    vim.cmd("stopinsert")
    M.toggle()
  end, { desc = "Hide terminal" })
 -- Выход в normal mode (для копирования)
  vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
  -- Быстрый доступ к терминалам 1-4
  for i = 1, 4 do
    vim.keymap.set("n", prefix .. tostring(i), function()
      M.select(i)
    end, { desc = "Terminal " .. i })
  end

  -- Навигация
  vim.keymap.set("n", "[t", M.prev, { desc = "Prev terminal" })
  vim.keymap.set("n", "]t", M.next, { desc = "Next terminal" })

  -- Команды для задач
  if opts.tasks then
    vim.api.nvim_create_user_command("Task", function(args)
      M.run_task(args.args)
    end, {
      nargs = 1,
      complete = function()
        return vim.tbl_keys(M.tasks)
      end,
    })
  end

  -- Закрыть терминалы при выходе
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = M.close_all,
  })
end

return M
