local parser = require("local-plugins.markdown-render.parser")
local hl = require("local-plugins.markdown-render.highlights")

local M = {}
local ns = vim.api.nvim_create_namespace("markdown_render")
local state = {} -- buf -> { saved = {...}, timer = uv_timer, tick = n, width = n }

local function buf_width(win)
  local width = vim.api.nvim_win_get_width(win)
  return vim.wo[win].wrap and math.max(40, math.floor(width * 0.95)) or width
end

local function render(buf, force)
  local s = state[buf]
  if not s or not vim.api.nvim_buf_is_valid(buf) then return end
  local win = vim.fn.bufwinid(buf)
  if win == -1 then return end

  local tick, width = vim.b[buf].changedtick, buf_width(win)
  if not force and tick == s.tick and width == s.width then return end
  s.tick, s.width = tick, width

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local marks = parser.parse(vim.api.nvim_buf_get_lines(buf, 0, -1, false), width)
  for _, m in ipairs(marks) do
    pcall(vim.api.nvim_buf_set_extmark, buf, ns, m[1], m[2], m[3])
  end
end

local function schedule_render(buf)
  local s = state[buf]
  if not s then return end
  s.timer:stop()
  s.timer:start(200, 0, vim.schedule_wrap(function() render(buf) end))
end

function M.enable(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if state[buf] then return end
  local win = vim.api.nvim_get_current_win()
  state[buf] = {
    timer = vim.uv.new_timer(),
    saved = {
      wrap          = vim.wo[win].wrap,
      conceallevel  = vim.wo[win].conceallevel,
      concealcursor = vim.wo[win].concealcursor,
    },
  }
  vim.wo[win].wrap = true
  vim.wo[win].conceallevel = 2
  vim.wo[win].concealcursor = "nvc"
  vim.b[buf].markdown_render = true
  render(buf, true)
end

local function cleanup(buf)
  local s = state[buf]
  if not s then return end
  s.timer:stop()
  s.timer:close()
  state[buf] = nil
end

function M.disable(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local s = state[buf]
  if not s then return end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local win = vim.fn.bufwinid(buf)
  if win ~= -1 then
    for k, v in pairs(s.saved) do vim.wo[win][k] = v end
  end
  vim.b[buf].markdown_render = false
  cleanup(buf)
end

function M.toggle()
  local buf = vim.api.nvim_get_current_buf()
  if state[buf] then M.disable(buf) else M.enable(buf) end
end

local function setup_autocmds()
  local group = vim.api.nvim_create_augroup("MarkdownRender", { clear = true })
  local au = vim.api.nvim_create_autocmd

  au({ "TextChanged", "InsertLeave", "BufWritePost" }, {
    group = group,
    callback = function(a)
      if state[a.buf] then schedule_render(a.buf) end
    end,
  })
  au("WinResized", {
    group = group,
    callback = function()
      for _, win in ipairs(vim.v.event.windows or {}) do
        local buf = vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win)
        if buf and state[buf] then schedule_render(buf) end
      end
    end,
  })
  au("FileType", {
    group = group,
    pattern = "markdown",
    callback = function(a)
      if vim.g.markdown_render_auto then M.enable(a.buf) end
    end,
  })
  au("BufWipeout", {
    group = group,
    callback = function(a) cleanup(a.buf) end,
  })
  au("ColorScheme", { group = group, callback = hl.apply })
end

function M.setup(opts)
  opts = opts or {}
  if opts.auto_enable ~= nil then vim.g.markdown_render_auto = opts.auto_enable end
  hl.apply()
  setup_autocmds()

  vim.api.nvim_create_user_command("MarkdownRender", function(c)
    if c.args == "on" then M.enable()
    elseif c.args == "off" then M.disable()
    else M.toggle() end
  end, {
    nargs = "?",
    complete = function(arglead)
      return vim.tbl_filter(function(v)
        return v:find(arglead, 1, true) == 1
      end, { "toggle", "on", "off" })
    end,
  })
  vim.api.nvim_create_user_command("MarkdownRenderRefresh", function()
    render(vim.api.nvim_get_current_buf(), true)
  end, {})
  vim.keymap.set({ "n", "v" }, "<leader>mr", M.toggle, { desc = "Markdown render toggle" })
end

return M

