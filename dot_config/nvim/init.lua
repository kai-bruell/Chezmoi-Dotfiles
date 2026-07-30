-- [[BLOCK: General]]
-- [[/BLOCK]]

-- Zeilennummern
vim.opt.relativenumber = true
vim.opt.number = true

-- Schwarzer Hintergrund
vim.opt.background = 'dark'
vim.cmd('highlight Normal guibg=#000000 ctermbg=0')
vim.cmd('highlight NonText guibg=#000000 ctermbg=0')
vim.cmd('highlight NormalNC guibg=#000000 ctermbg=0')

-- Transparente Statusleiste
vim.cmd('highlight StatusLine guibg=#3a3a3a guifg=#ffffff ctermbg=NONE ctermfg=15')
vim.cmd('highlight StatusLineNC guibg=#2a2a2a guifg=#808080 ctermbg=NONE ctermfg=244')

vim.cmd('colorscheme habamax')

-- Clipboard Support
vim.opt.clipboard = "unnamedplus"

-- Indentation JSON
vim.api.nvim_create_autocmd("FileType", {
  pattern = "json",
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})
