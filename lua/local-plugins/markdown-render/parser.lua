local M = {}

local rep, find, sub, match, gsub = string.rep, string.find, string.sub, string.match, string.gsub
local strwidth = vim.fn.strdisplaywidth

local BULLETS = { "•", "◦", "▪", "‣" }
local HEAD_SIGN = { "▌", "▍", "▎", "▏", "│", "┆" }

local function push(out, row, col, endcol, opts)
  opts.end_row = row
  opts.end_col = endcol
  out[#out + 1] = { row, col, opts }
end

local function overlay(out, row, width_line, text, hl)
  local pad = width_line - strwidth(text)
  if pad > 0 then text = text .. rep(" ", pad) end
  out[#out + 1] = { row, 0, {
    virt_text = { { text, hl } },
    virt_text_pos = "overlay",
    hl_mode = "combine",
    priority = 120,
  } }
end

local function is_hr(line)
  local s = gsub(line, "%s", "")
  local n = #s
  if n < 3 then return false end
  local c = sub(s, 1, 1)
  if c ~= "-" and c ~= "*" and c ~= "_" then return false end
  return not find(s, "[^" .. (c == "-" and "%-" or "%" .. c) .. "]")
end

local function inline(out, row, line, from)
  local claimed, nclaimed = {}, 0

  local function free(s, e)
    for k = 1, nclaimed do
      local r = claimed[k]
      if s <= r[2] and e >= r[1] then return false end
    end
    return true
  end

  local function claim(s, e)
    nclaimed = nclaimed + 1
    claimed[nclaimed] = { s, e }
  end

  -- inline code
  local i = from + 1
  while true do
    local s, e = find(line, "`[^`]+`", i)
    if not s then break end
    claim(s, e)
    push(out, row, s - 1, s, { conceal = "" })
    push(out, row, s, e - 1, { hl_group = "MdCodeInline" })
    push(out, row, e - 1, e, { conceal = "" })
    i = e + 1
  end

  -- links
  i = from + 1
  while true do
    local s, e, text = find(line, "%[([^%]]*)%]%([^%)]*%)", i)
    if not s then break end
    if free(s, e) then
      local bang = (s > 1 and sub(line, s - 1, s - 1) == "!") and 1 or 0
      claim(s - bang, e)
      push(out, row, s - 1 - bang, s, { conceal = "" })
      push(out, row, s, s + #text, { hl_group = "MdLink" })
      push(out, row, s + #text, e, { conceal = "" })
    end
    i = e + 1
  end

  local function delim(pat, dlen, hl, boundary)
    local j = from + 1
    while true do
      local s, e = find(line, pat, j)
      if not s then break end
      local ok = free(s, e)
      if ok and boundary then
        local before = s > 1 and sub(line, s - 1, s - 1) or " "
        local after = sub(line, e + 1, e + 1)
        if match(before, "[%w_]") or match(after, "[%w_]") then ok = false end
      end
      if ok then
        claim(s, e)
        push(out, row, s - 1, s - 1 + dlen, { conceal = "" })
        push(out, row, s - 1 + dlen, e - dlen, { hl_group = hl })
        push(out, row, e - dlen, e, { conceal = "" })
        j = e + 1
      else
        j = s + 1
      end
    end
  end

  if find(line, "*", from + 1, true) then
    delim("%*%*[^%s][^*]*%*%*", 2, "MdBold")
    delim("%*[^%s*][^*]*%*", 1, "MdItalic")
  end
  if find(line, "_", from + 1, true) then
    delim("__[^%s][^_]*__", 2, "MdBold", true)
    delim("_[^%s_][^_]*_", 1, "MdItalic", true)
  end
  if find(line, "~~", from + 1, true) then
    delim("~~[^%s][^~]*~~", 2, "MdStrike")
  end
end

local function table_row(out, row, line, lw)
  local c = 0
  while true do
    c = find(line, "|", c + 1, true)
    if not c then break end
    push(out, row, c - 1, c, { hl_group = "MdTable" })
  end
  if match(line, "^%s*|?[%s%-:|]+|%s*$") then
    local t = gsub(gsub(line, "|", "┼"), "%-", "─")
    overlay(out, row, lw, t, "MdTable")
  end
end

function M.parse(lines, width)
  local out = {}
  local fence = nil
  local hr_line = rep("─", width)

  for idx = 1, #lines do
    local line = lines[idx]
    local row = idx - 1
    local lw = strwidth(line)
    local fmark = match(line, "^%s*(```+)") or match(line, "^%s*(~~~+)")

    if fence then
      if fmark and sub(fmark, 1, 1) == fence then
        fence = nil
        overlay(out, row, lw, "╰" .. hr_line, "MdCodeFence")
      else
        push(out, row, 0, #line, { hl_group = "MdCodeBlock", hl_eol = true, priority = 90 })
      end

    elseif fmark then
      fence = sub(fmark, 1, 1)
      local lang = match(line, "^%s*[`~]+%s*([%w_%-%+#%.]*)") or ""
      local label = lang ~= "" and ("╭─ " .. lang .. " ") or "╭─ "
      overlay(out, row, lw, label .. rep("─", math.max(0, width - strwidth(label))), "MdCodeFence")

    elseif is_hr(line) then
      overlay(out, row, lw, hr_line, "MdHr")

    else
      local hashes, text = match(line, "^(#+)%s+(.*)$")
      if hashes and #hashes <= 6 and text then
        local lvl = #hashes
        push(out, row, 0, lvl + 1, { conceal = HEAD_SIGN[lvl], hl_group = "MdH" .. lvl })
        push(out, row, lvl + 1, #line, { hl_group = "MdH" .. lvl, hl_eol = lvl <= 2, priority = 95 })
        inline(out, row, line, lvl + 1)
      else
        local from = 0
        local qindent, quote = match(line, "^(%s*)(>+)")
        if quote then
          local base = #qindent
          for k = 0, #quote - 1 do
            push(out, row, base + k, base + k + 1, { conceal = "▏", hl_group = "MdQuote" })
          end
          from = base + #quote
          push(out, row, from, #line, { hl_group = "MdQuoteText", priority = 90 })
        end

        local pre = from == 0 and line or sub(line, from + 1)
        local li, sp = match(pre, "^(%s*)[%-%*%+](%s+)")
        if li then
          local level = math.floor(#li / 2)
          push(out, row, from + #li, from + #li + 1, {
            conceal = BULLETS[level % 4 + 1],
            hl_group = "MdBullet",
          })
          local off = from + #li + 1 + #sp
          local box = match(pre, "^%[([ x])%]%s", #li + 2 + #sp)
          if box then
            local done = box == "x"
            push(out, row, off, off + 3, { conceal = done and "✓" or "○" })
            if done then push(out, row, off + 4, #line, { hl_group = "MdDone" }) end
          end
          inline(out, row, line, from)
        else
          local li2, num, dot = match(pre, "^(%s*)(%d+)(%.)%s")
          if li2 then
            push(out, row, from + #li2, from + #li2 + #num + #dot, { hl_group = "MdNumber" })
          end
          inline(out, row, line, from)
        end
      end

      if find(line, "|", 1, true) then
        table_row(out, row, line, lw)
      end
    end
  end

  return out
end

return M

