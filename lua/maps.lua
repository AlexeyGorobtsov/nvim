local keymap = vim.keymap
local opts = { noremap = true, silent = true }
keymap.set("n", "x", '"_x')

--Increment/decrement
keymap.set("n", "+", "<C-a>")
keymap.set("n", "-", "C-x")

--Delete a word backwords
keymap.set("n", "dw", 'vb"_d')

--Select all
keymap.set("n", "<C-a>", "gg<S-v>G")

-- New tab
--keymap.set('n', '<leader>t', ':tabnew<CR>', opts)

keymap.set("n", "te", ":tabedit<Return>")
-- Split window
keymap.set("n", "ss", ":split<Return><C-w>w", opts)
keymap.set("n", "sv", ":vsplit<Return><C-w>w", opts)
-- Move window
keymap.set("n", "<Space>", "<C-w>w")
keymap.set("", "s<left>", "<C-w>h")
keymap.set("", "s<up>", "<C-w>k")
keymap.set("", "s<down>", "<C-w>j")
keymap.set("", "s<right>", "<C-w>l")
keymap.set("", "sh", "<C-w>h")
keymap.set("", "sk", "<C-w>k")
keymap.set("", "sj", "<C-w>j")
keymap.set("", "sl", "<C-w>l")
-- Resize window
keymap.set("n", "<C-w><left>", "<C-w><")
keymap.set("n", "<C-w><right>", "<C-w>>")
keymap.set("n", "<C-w><up>", "<C-w>+")
keymap.set("n", "<C-w><down>", "<C-w>-")

-- NeoTree
--keymap.set("n", "<leader>e", ":Neotree focus<CR>")
--keymap.set('n', '<space>n', ':Neotree<CR>', opts)
