local M = {}

local function hl(name)
  local ok, h = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  return ok and h or {}
end

local function fg(name, fallback)
  local v = hl(name).fg
  return v and string.format("#%06x", v) or fallback
end

local function bg(name, fallback)
  local v = hl(name).bg
  return v and string.format("#%06x", v) or fallback
end

function M.apply()
  local blue    = fg("Function", "#7aa2f7")
  local green   = fg("String", "#9ece6a")
  local yellow  = fg("Type", "#e0af68")
  local purple  = fg("Statement", "#bb9af7")
  local cyan    = fg("Special", "#7dcfff")
  local comment = fg("Comment", "#565f89")
  local soft    = bg("CursorLine", "#2a2f41")

  local groups = {
    MdH1         = { fg = blue, bold = true, bg = soft },
    MdH2         = { fg = green, bold = true, bg = soft },
    MdH3         = { fg = yellow, bold = true },
    MdH4         = { fg = purple, bold = true },
    MdH5         = { fg = cyan, bold = true },
    MdH6         = { fg = comment, bold = true },
    MdBold       = { bold = true },
    MdItalic     = { italic = true },
    MdStrike     = { strikethrough = true, fg = comment },
    MdCodeInline = { fg = yellow, bg = soft },
    MdCodeBlock  = { bg = soft },
    MdCodeFence  = { fg = comment, italic = true },
    MdLink       = { fg = cyan, underline = true },
    MdQuote      = { fg = purple },
    MdQuoteText  = { fg = comment, italic = true },
    MdBullet     = { fg = blue },
    MdNumber     = { fg = blue, bold = true },
    MdHr         = { fg = comment },
    MdTable      = { fg = comment },
    MdCheck      = { fg = yellow },
    MdCheckDone  = { fg = green },
    MdDone       = { fg = comment, strikethrough = true },
  }

  local set_hl = vim.api.nvim_set_hl
  for name, val in pairs(groups) do
    set_hl(0, name, val)
  end
end

return M

