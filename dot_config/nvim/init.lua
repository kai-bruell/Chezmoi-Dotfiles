-- Plugin-Manager: lazy.nvim (Industriestandard)
vim.g.mapleader = " "
vim.g.maplocalleader = " "
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--single-branch",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins aus lua/plugins/*.lua laden
require("lazy").setup("plugins", {
  checker = { enabled = false },
  change_detection = { notify = false },
})

-- Eigene Module
require("options")
require("keymaps")
require("autocmds")
