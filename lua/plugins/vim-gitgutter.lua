return {
  "airblade/vim-gitgutter",
  config = function()
    -- Enable GitGutter
    vim.g.gitgutter_enabled = 1

    -- Show a sign column with added/modified/removed lines
    vim.api.nvim_command("set signcolumn=yes")

    -- Customize GitGutter signs
    vim.g.gitgutter_sign_added = "▊"
    vim.g.gitgutter_sign_modified = "▊"
    vim.g.gitgutter_sign_removed = "▊"
  end,
}
