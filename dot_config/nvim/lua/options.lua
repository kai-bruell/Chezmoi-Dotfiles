-- Vanilla-Einstellungen: alles nativ, kein Plugin-Overhead

-- Zeilennummern
vim.opt.number = true
vim.opt.relativenumber = true

-- Einrückung (Standard: 4 Spaces)
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Suche
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Darstellung
vim.opt.background = "dark"
vim.opt.termguicolors = true
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"

-- Dateien & Zwischenablage
vim.opt.clipboard = "unnamedplus"
vim.opt.undofile = true
vim.opt.swapfile = false

-- Maus & Split
vim.opt.mouse = "a"
vim.opt.splitright = true
vim.opt.splitbelow = true

-- LSP / Completion
vim.opt.updatetime = 300
vim.opt.completeopt = "menu,menuone,noselect"

-- Farben: schwarzer Hintergrund + Statusleiste
vim.cmd("colorscheme habamax")
vim.cmd("highlight Normal guibg=#000000 ctermbg=0")
vim.cmd("highlight NonText guibg=#000000 ctermbg=0")
vim.cmd("highlight NormalNC guibg=#000000 ctermbg=0")
vim.cmd("highlight StatusLine guibg=#3a3a3a guifg=#ffffff ctermbg=NONE ctermfg=15")
vim.cmd("highlight StatusLineNC guibg=#2a2a2a guifg=#808080 ctermbg=NONE ctermfg=244")
