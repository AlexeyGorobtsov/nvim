vim.cmd('autocmd!')

-- Setting Character Encodings
vim.scriptencoding = 'utf-8' -- This sets the encoding for Vim scripts
vim.opt.encoding = 'utf-8' -- This sets the encoding for the Vim editor itself.
vim.opt.fileencoding = 'utf-8' -- This sets the encoding for the currently open file

-- Display Options
vim.wo.number = true -- This enables line numbers in the Vim window
vim.opt.title = true --  This displays the file name and other information in the Vim window title

-- Editing Behavior Options
vim.opt.autoindent = true -- This enables automatic indentation when typing new lines in code
vim.opt.hlsearch = true -- This highlights search results in the Vim window
vim.opt.backup = false -- This disables automatic backup files
vim.opt.showcmd = true -- This displays the current command being typed at the bottom of the Vim window
vim.opt.cmdheight = 1 -- This sets the height of the command bar to one line
vim.opt.laststatus = 2 -- This sets the last status line to two lines

-- Tab and Indentation Options
vim.opt.expandtab = true -- This enables the expansion of tabs to spaces when editing text
vim.opt.scrolloff = 10 -- This sets the number of lines to keep visible above and below the cursor when scrolling.


vim.opt.shell = 'fish'
vim.opt.backupskip = '/tmp/*,/private/tmp/*'
vim.opt.inccommand = 'split'
vim.opt.ignorecase = true
vim.opt.smarttab = true
vim.opt.breakindent = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2

-- Whitespace and Wrap Options
vim.opt.ai = true -- Auto indent
vim.opt.si = true -- Smart indent
vim.opt.wrap = false -- No wrap lines
vim.opt.backspace = 'start,eol,indent'
vim.opt.path:append { '**' } -- Finding files - Search down into subfolders
vim.opt.wildignore:append { '*/node_modules/*' }

-- Undercurl
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])
vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*",
  command = "set nopaste"
})

-- Add asterisks in block comments
vim.opt.formatoptions:append { "r" }
