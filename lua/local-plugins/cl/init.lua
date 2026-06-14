local M = {}

local config = {
  api_key = nil,
  model = "claude-fable-5",
  -- model = "claude-opus-4-8",
  max_tokens = 40000,
  timeout = 120,
  store_dir = vim.fn.stdpath("data") .. "/claude_batches",
  history_file = vim.fn.stdpath("data") .. "/claude_batches/history.md",
  system_prompt = table.concat({
    "Answer directly: no preamble, no filler, no closing summaries.",
    "Simple question -> 1-2 sentences. Complex -> tight structure.",
    "Plain text by default; lists/headers only for 3+ parallel items.",
    "Code: no comments or docstrings unless logic is non-obvious; omit obvious imports.",
    "Caveats only when they prevent real errors.",
    "If the request is ambiguous, ask one short clarifying question instead of guessing.",
    "No examples unless asked. No apologies, no self-reference.",
    "Reply in the user's language.",
  }, " "),
}

local cached_key

local function resolve_api_key()
  if cached_key then return cached_key end
  local key = config.api_key or vim.env.ANTHROPIC_API_KEY
  if key and key ~= "" then
    cached_key = key
    return key
  end
  local shell = vim.env.SHELL or "/bin/sh"
  local h = io.popen(shell .. " -ic 'echo -n $ANTHROPIC_API_KEY' 2>/dev/null")
  if h then
    key = h:read("*a")
    h:close()
    if key then key = key:gsub("%s+$", "") end
  end
  if key and key ~= "" then
    cached_key = key
    return key
  end
  return nil
end

local function decode(raw)
  local ok, res = pcall(vim.json.decode, raw)
  return ok and res or nil
end

local function request(opts, cb)
  local key = resolve_api_key()
  if not key then
    vim.notify("ANTHROPIC_API_KEY не установлен", vim.log.levels.ERROR)
    return
  end
  local cmd = {
    "curl", "-sS", "--max-time", tostring(config.timeout),
    "-H", "x-api-key: " .. key,
    "-H", "anthropic-version: 2023-06-01",
    "-H", "content-type: application/json",
  }
  local tmp
  if opts.body then
    tmp = vim.fn.tempname()
    local f = io.open(tmp, "w")
    if not f then
      vim.notify("Не удалось создать временный файл", vim.log.levels.ERROR)
      return
    end
    f:write(opts.body)
    f:close()
    vim.list_extend(cmd, { "-d", "@" .. tmp })
  end
  table.insert(cmd, opts.url)
  local out, err = {}, {}
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, d) if d then vim.list_extend(out, d) end end,
    on_stderr = function(_, d) if d then vim.list_extend(err, d) end end,
    on_exit = function(_, code)
      if tmp then vim.fn.delete(tmp) end
      if code ~= 0 then
        vim.notify("curl error: " .. table.concat(err, " "), vim.log.levels.ERROR)
        return
      end
      cb(table.concat(out, "\n"))
    end,
  })
end

local function ensure_store()
  vim.fn.mkdir(config.store_dir, "p")
end

local function meta_path(id)
  return config.store_dir .. "/" .. id .. ".json"
end

local function save_batch(meta)
  ensure_store()
  local f = io.open(meta_path(meta.id), "w")
  if not f then return end
  f:write(vim.json.encode(meta))
  f:close()
end

local function append_history(meta, answer)
  ensure_store()
  local f = io.open(config.history_file, "a")
  if not f then return end
  f:write(table.concat({
    "----------",
    os.date("%d.%m.%Y %H:%M", meta.created or os.time()),
    "",
    "## Вопрос",
    meta.prompt or meta.label or "",
    "",
    "## Ответ",
    answer,
    "", "",
  }, "\n"))
  f:close()
end

local function delete_batch(id)
  vim.fn.delete(meta_path(id))
end

local function list_batches()
  ensure_store()
  local out = {}
  for name, t in vim.fs.dir(config.store_dir) do
    if t == "file" and name:match("%.json$") then
      local f = io.open(config.store_dir .. "/" .. name, "r")
      if f then
        local meta = decode(f:read("*a"))
        f:close()
        if meta and meta.id then table.insert(out, meta) end
      end
    end
  end
  table.sort(out, function(a, b) return (a.created or 0) > (b.created or 0) end)
  return out
end

local function open_float(buf, title)
  local width = math.min(math.floor(vim.o.columns * 0.75), 120)
  local height = math.floor(vim.o.lines * 0.6)
  return vim.api.nvim_open_win(buf, true, {
    relative = "editor", width = width, height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal", border = "rounded",
    title = title, title_pos = "center",
  })
end

local function open_result_win(lines, label)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].modifiable = false
  local title = (" %s "):format(label and label:sub(1, 50) or "Result")
  open_float(buf, title)
  local function close() pcall(vim.api.nvim_buf_delete, buf, { force = true }) end
  vim.keymap.set("n", "q", close, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, silent = true })
  vim.keymap.set("n", "<leader>y", function()
    vim.fn.setreg("+", table.concat(lines, "\n"))
    vim.notify("Ответ скопирован в буфер обмена")
  end, { buffer = buf, silent = true, desc = "Yank result" })
end

function M.submit(prompt, label)
  local body = vim.json.encode({
    requests = {
      {
        custom_id = "req-1",
        params = {
          model = config.model,
          max_tokens = config.max_tokens,
          system = config.system_prompt,
          messages = { { role = "user", content = prompt } },
        },
      },
    },
  })
  request({ url = "https://api.anthropic.com/v1/messages/batches", body = body },
    function(raw)
      local res = decode(raw)
      if not res or res.type == "error" or not res.id then
        vim.notify("Ошибка отправки батча: " .. raw:sub(1, 300), vim.log.levels.ERROR)
        return
      end
      save_batch({
        id = res.id,
        label = label or prompt:sub(1, 40),
        prompt = prompt,
        status = res.processing_status,
        created = os.time(),
      })
      vim.notify("Батч отправлен: " .. res.id, vim.log.levels.INFO)
    end)
end

local function fetch_results(meta, results_url)
  request({ url = results_url }, function(raw)
    local lines = {}
    for _, line in ipairs(vim.split(raw, "\n", { trimempty = true })) do
      local obj = decode(line)
      if obj and obj.result then
        if obj.result.type == "succeeded" and obj.result.message then
          for _, block in ipairs(obj.result.message.content or {}) do
            if block.type == "text" and block.text then
              vim.list_extend(lines, vim.split(block.text, "\n"))
            end
          end
        elseif obj.result.error then
          table.insert(lines, "Ошибка: " .. vim.inspect(obj.result.error))
        end
      end
    end
    if #lines == 0 then lines = { "Пустой результат" } end
    append_history(meta, table.concat(lines, "\n"))
    open_result_win(lines, meta.label)
    delete_batch(meta.id)
  end)
end

local function check_batch(meta, silent)
  request({ url = "https://api.anthropic.com/v1/messages/batches/" .. meta.id },
    function(raw)
      local res = decode(raw)
      if not res then return end
      if res.processing_status == "ended" and res.results_url then
        fetch_results(meta, res.results_url)
      elseif res.type == "error" then
        vim.notify("Батч " .. meta.id .. ": " .. raw:sub(1, 200), vim.log.levels.ERROR)
        delete_batch(meta.id)
      elseif not silent then
        vim.notify(("%s [%s]: %s"):format(
          meta.label or meta.id, meta.id:sub(-8), res.processing_status))
      end
    end)
end

function M.poll()
  local batches = list_batches()
  if #batches == 0 then
    vim.notify("Нет ожидающих батчей")
    return
  end
  for _, meta in ipairs(batches) do
    check_batch(meta)
  end
end

function M.list()
  local batches = list_batches()
  if #batches == 0 then
    vim.notify("Нет ожидающих батчей")
    return
  end
  vim.ui.select(batches, {
    prompt = "Батчи:",
    format_item = function(m)
      return ("%s  %s  %s"):format(
        os.date("%d.%m %H:%M", m.created or 0), m.id:sub(-8), m.label or "")
    end,
  }, function(meta)
    if not meta then return end
    vim.ui.select({ "Проверить / получить", "Удалить" }, { prompt = meta.label or meta.id },
      function(action)
        if action == "Удалить" then
          delete_batch(meta.id)
          vim.notify("Удалён: " .. meta.id)
        elseif action then
          check_batch(meta)
        end
      end)
  end)
end

function M.history()
  if vim.fn.filereadable(config.history_file) == 0 then
    vim.notify("История пуста")
    return
  end
  vim.cmd("edit " .. vim.fn.fnameescape(config.history_file))
  vim.cmd("normal! G")
end

local function get_visual_selection()
  local s = vim.fn.getpos("'<")
  local e = vim.fn.getpos("'>")
  local lines = vim.fn.getline(s[2], e[2])
  if type(lines) == "string" then lines = { lines } end
  if #lines == 0 then return "" end
  local last = lines[#lines]
  lines[#lines] = last:sub(1, math.min(e[3], #last))
  lines[1] = lines[1]:sub(s[3])
  return table.concat(lines, "\n")
end

function M.ask_with_editor(opts)
  opts = opts or {}
  local ft = vim.bo.filetype ~= "" and vim.bo.filetype or "text"
  local context = opts.visual and get_visual_selection() or ""

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].bufhidden = "wipe"

  local width = math.min(math.floor(vim.o.columns * 0.7), 100)
  local height = 8
  local ctx_info = context ~= ""
      and (" [+%d строк контекста]"):format(#vim.split(context, "\n")) or ""
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", width = width, height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal", border = "rounded",
    title = " Claude" .. ctx_info .. " ",
    title_pos = "center",
    footer = " <C-s>/<C-CR> отправить · <Esc><Esc>/q отмена ",
    footer_pos = "center",
  })

  vim.cmd("startinsert")

  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end

  local function submit()
    local input = vim.trim(table.concat(
      vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
    close()
    if input == "" then return end
    local prompt = input
    if context ~= "" then
      prompt = input .. "\n\n```" .. ft .. "\n" .. context .. "\n```"
    end
    M.submit(prompt, input:gsub("\n", " "):sub(1, 40))
  end

  for _, mode in ipairs({ "i", "n" }) do
    vim.keymap.set(mode, "<C-CR>", submit, { buffer = buf, silent = true })
    vim.keymap.set(mode, "<C-s>", submit, { buffer = buf, silent = true })
  end
  vim.keymap.set("n", "q", close, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, silent = true })
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})

  vim.api.nvim_create_user_command("ClaudeBatch", function(o)
    M.ask_with_editor({ visual = o.range > 0 })
  end, { range = true })

  vim.api.nvim_create_user_command("ClaudeBatchPoll", M.poll, {})
  vim.api.nvim_create_user_command("ClaudeBatchList", M.list, {})
  vim.api.nvim_create_user_command("ClaudeBatchHistory", M.history, {})

  vim.keymap.set("n", "<leader>bi", "<cmd>ClaudeBatch<cr>", { desc = "Claude batch ask" })
  vim.keymap.set("v", "<leader>bi", ":<C-u>ClaudeBatch<cr>", { desc = "Claude batch ask with selection" })
  vim.keymap.set("n", "<leader>bp", "<cmd>ClaudeBatchPoll<cr>", { desc = "Claude batch poll" })
  vim.keymap.set("n", "<leader>bl", "<cmd>ClaudeBatchList<cr>", { desc = "Claude batch list" })
  vim.keymap.set("n", "<leader>bh", "<cmd>ClaudeBatchHistory<cr>", { desc = "Claude batch history" })
end

return M
