local augroup = vim.api.nvim_create_augroup("UserAutocmds", { clear = true })

-- Indentation JSON (2 Spaces)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "json",
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
  group = augroup,
})

-- Text-Dateien umbrechen
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
  end,
  group = augroup,
})
