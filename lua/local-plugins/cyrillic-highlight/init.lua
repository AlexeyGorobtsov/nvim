-- lua/local-plugins/cyrillic-highlight/init.lua

local M = {}

local ns = vim.api.nvim_create_namespace("cyrillic_highlight")

local function highlight_buffer(buf)
  buf = buf or vim.api.nvim_get_current_buf()

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  for lnum, line in ipairs(lines) do
    -- Ищем слова (идентификаторы): буквы, цифры, подчёркивания
    local pos = 1

    while pos <= #line do
      -- Найти начало слова
      local word_start, word_end = line:find("[%w_\128-\255]+", pos)

      if not word_start then break end

      local word = line:sub(word_start, word_end)

      -- Проверить: есть ли латиница И кириллица в одном слове?
      local has_latin = word:match("[a-zA-Z]")
      local has_cyrillic = word:match("[\208-\209][\128-\191]") -- UTF-8 кириллица

      if has_latin and has_cyrillic then
        -- Подсветить только кириллические символы в этом слове
        local col = word_start - 1

        for char in word:gmatch(".[\128-\191]*") do
          local byte = string.byte(char, 1)

          -- UTF-8 кириллица
          if byte == 0xD0 or byte == 0xD1 then
            vim.api.nvim_buf_set_extmark(buf, ns, lnum - 1, col, {
              end_col = col + #char,
              hl_group = "CyrillicInLatin",
            })
          end

          col = col + #char
        end
      end

      pos = word_end + 1
    end
  end
end

local timer = nil

local function highlight_buffer_debounced()
  if timer then
    vim.fn.timer_stop(timer)
  end
  timer = vim.fn.timer_start(100, function()
    highlight_buffer()
  end)
end

M.enable = function()
  vim.api.nvim_set_hl(0, "CyrillicInLatin", {
    bg = "#ff6b6b",
    fg = "#ffffff",
    bold = true,
  })

  local group = vim.api.nvim_create_augroup("CyrillicHighlight", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
    group = group,
    callback = function()
      highlight_buffer()
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
    group = group,
    callback = highlight_buffer_debounced,
  })

  highlight_buffer()

  vim.notify("Cyrillic highlight enabled", vim.log.levels.INFO)
end

M.disable = function()
  vim.api.nvim_create_augroup("CyrillicHighlight", { clear = true })

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    end
  end

  vim.notify("Cyrillic highlight disabled", vim.log.levels.INFO)
end

M.toggle = function()
  local ok, autocmds = pcall(vim.api.nvim_get_autocmds, { group = "CyrillicHighlight" })

  if ok and #autocmds > 0 then
    M.disable()
  else
    M.enable()
  end
end

M.setup = function(opts)
  opts = opts or {}

  vim.api.nvim_create_user_command("CyrillicHighlightEnable", M.enable, {})
  vim.api.nvim_create_user_command("CyrillicHighlightDisable", M.disable, {})
  vim.api.nvim_create_user_command("CyrillicHighlightToggle", M.toggle, {})

  if opts.keymap ~= false then
    vim.keymap.set("n", "<leader>uc", M.toggle, { desc = "Toggle cyrillic highlight" })
  end

  if opts.auto_enable ~= false then
    M.enable()
  end
end

return M
