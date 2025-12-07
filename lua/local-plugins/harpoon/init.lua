-- Простая замена Harpoon с использованием встроенного arglist

local M = {}

-- ══════════════════════════════════════════════════════════
-- Основные функции
-- ══════════════════════════════════════════════════════════

-- Добавить текущий файл в список
M.add = function()
  vim.cmd("$argadd %")
  vim.cmd("argdedup")
  local filename = vim.fn.expand("%:t")
  vim.notify("Added: " .. filename, vim.log.levels.INFO)
end

-- Удалить текущий файл из списка
M.remove = function()
  local filename = vim.fn.expand("%:t")
  vim.cmd("silent! argd %")
  vim.notify("Removed: " .. filename, vim.log.levels.INFO)
end

-- Очистить весь список
M.clear = function()
  vim.cmd("silent! %argd")
  vim.notify("Arglist cleared", vim.log.levels.INFO)
end

-- Показать список файлов
M.list = function()
  vim.cmd("args")
end

-- Перейти к файлу по номеру
M.select = function(index)
  vim.cmd("silent! " .. index .. "argument")
end

-- Следующий файл
M.next = function()
  vim.cmd("silent! next")
end

-- Предыдущий файл
M.prev = function()
  vim.cmd("silent! prev")
end

-- ══════════════════════════════════════════════════════════
-- UI: показать список в float окне
-- ══════════════════════════════════════════════════════════

M.menu = function()
  local args = vim.fn.argv() --[[@as string[] ]]

  if #args == 0 then
    vim.notify("Arglist is empty. Press <leader>a to add files.", vim.log.levels.WARN)
    return
  end

  local current = vim.fn.expand("%:p")

  local lines = {}
  local max_width = 0

  for i, file in ipairs(args) do
    local marker = (vim.fn.fnamemodify(file, ":p") == current) and " ●" or "  "
    local display_path = vim.fn.fnamemodify(file, ":.")
    local line = string.format(" %d%s %s", i, marker, display_path)
    table.insert(lines, line)
    max_width = math.max(max_width, #line)
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width = math.min(max_width + 4, 100)
  local height = math.min(#lines, 10)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
    style = "minimal",
    border = "rounded",
    title = " Arglist ",
    title_pos = "center",
  })

  local close = function()
    vim.api.nvim_win_close(win, true)
  end

  local opts = { buffer = buf, silent = true }

  vim.keymap.set("n", "q", close, opts)
  vim.keymap.set("n", "<Esc>", close, opts)

  vim.keymap.set("n", "<CR>", function()
    local line = vim.fn.line(".")
    close()
    M.select(line)
  end, opts)

  vim.keymap.set("n", "d", function()
    local line = vim.fn.line(".")
    vim.cmd("silent! " .. line .. "argd")
    close()
    M.menu()
  end, opts)

  for i = 1, 9 do
    vim.keymap.set("n", tostring(i), function()
      close()
      M.select(i)
    end, opts)
  end

  -- ✅ Показать help
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
    "  │         HARPOON-LITE HELP            │", -- 3 (index 2)
    "  ╰──────────────────────────────────────╯",
    "",
    "  GLOBAL KEYMAPS", -- 6 (index 5)
    "  ──────────────────────────────────────",
    "  <leader>a     Add current file",
    "  <leader>A     Remove current file",
    "  <leader>l     Open menu",
    "  <leader>c     Clear all files",
    "",
    "  MENU KEYMAPS", -- 13 (index 12)
    "  ──────────────────────────────────────",
    "  1-9           Jump to file by number",
    "  <CR>          Open selected file",
    "  d             Delete file from list",
    "  j/k           Navigate up/down",
    "  ?             Show this help",
    "  q / <Esc>     Close menu",
    "",
    "  VIM ARGLIST COMMANDS", -- 22 (index 21)
    "  ──────────────────────────────────────",
    "  :args         Show arglist",
    "  :argadd %     Add current file",
    "  :argd %       Remove current file",
    "  :argd *       Clear arglist",
    "  :next         Next file",
    "  :prev         Previous file",
    "",
  }

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_lines)

  -- ✅ Подсветка через extmarks
  local ns = vim.api.nvim_create_namespace("harpoon_help")

  local highlights = {
    { line = 2,  hl = "Title" },    -- HARPOON-LITE HELP
    { line = 5,  hl = "Function" }, -- GLOBAL KEYMAPS
    { line = 12, hl = "Function" }, -- MENU KEYMAPS
    { line = 21, hl = "Function" }, -- VIM ARGLIST COMMANDS
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

-- ══════════════════════════════════════════════════════════
-- Настройка кеймапов
-- ══════════════════════════════════════════════════════════

M.setup = function(opts)
  opts = opts or {}
  local prefix = opts.prefix or "<leader>"

  vim.keymap.set("n", prefix .. "a", M.add, { desc = "Add file to arglist" })
  vim.keymap.set("n", prefix .. "A", M.remove, { desc = "Remove file from arglist" })
  vim.keymap.set("n", prefix .. "l", M.menu, { desc = "Open arglist menu" })
  vim.keymap.set("n", prefix .. "c", M.clear, { desc = "Clear arglist" })
  vim.keymap.set("n", prefix .. "?", M.help, { desc = "Show harpoon help" })
end

return M
