-- Gesetzt in init.lua vor lazy.setup(); hier nur Referenz
-- vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- LSP-Client prüfen, damit globale Tasten in Nicht-LSP-Dateien nichts tun
local function has_lsp_client(bufnr)
  return next(vim.lsp.get_clients({ bufnr = bufnr })) ~= nil
end

-- [[BLOCK: File Operations]]
-- cmd: <C-s>   | desc: Datei speichern
-- cmd: <C-q>   | desc: Puffer schließen
-- cmd: <C-S-q> | desc: Alle Puffer schließen
vim.keymap.set("n", "<C-s>", ":w<CR>", { noremap = true, desc = "Datei speichern" })
vim.keymap.set("n", "<C-q>", ":q<CR>", { noremap = true, desc = "Puffer schließen" })
vim.keymap.set("n", "<C-S-q>", ":qa<CR>", { noremap = true, desc = "Alle Puffer schließen" })
-- [[/BLOCK]]

-- [[BLOCK: Navigation (LSP)]]
-- cmd: gd     | desc: Gehe zur Definition
-- cmd: gD     | desc: Gehe zur Deklaration
-- cmd: gi     | desc: Gehe zur Implementierung
-- cmd: gr     | desc: Zeige Referenzen
-- cmd: K      | desc: Hover-Dokumentation anzeigen
-- cmd: <C-k>  | desc: Signatur-Hilfe (Insert-Mode)
vim.keymap.set("n", "gd", function()
  if has_lsp_client() then vim.lsp.buf.definition() end
end, { desc = "Gehe zur Definition" })
vim.keymap.set("n", "gD", function()
  if has_lsp_client() then vim.lsp.buf.declaration() end
end, { desc = "Gehe zur Deklaration" })
vim.keymap.set("n", "gi", function()
  if has_lsp_client() then vim.lsp.buf.implementation() end
end, { desc = "Gehe zur Implementierung" })
vim.keymap.set("n", "gr", function()
  if has_lsp_client() then vim.lsp.buf.references() end
end, { desc = "Zeige Referenzen" })
vim.keymap.set("n", "K", function()
  if has_lsp_client() then vim.lsp.buf.hover() end
end, { desc = "Hover-Dokumentation" })
vim.keymap.set("i", "<C-k>", function()
  if has_lsp_client() then vim.lsp.buf.signature_help() end
end, { desc = "Signatur-Hilfe" })
-- [[/BLOCK]]

-- [[BLOCK: Aktionen (LSP)]]
-- cmd: <leader>rn | desc: Symbol umbenennen
-- cmd: <leader>ca | desc: Code-Action (Quickfix, Refactoring)
-- cmd: <leader>f  | desc: Datei formatieren
vim.keymap.set("n", "<leader>rn", function()
  if has_lsp_client() then vim.lsp.buf.rename() end
end, { desc = "Symbol umbenennen" })
vim.keymap.set("n", "<leader>ca", function()
  if has_lsp_client() then vim.lsp.buf.code_action() end
end, { desc = "Code-Action" })
vim.keymap.set("n", "<leader>f", function()
  if has_lsp_client() then vim.lsp.buf.format({ async = true }) end
end, { desc = "Datei formatieren" })
-- [[/BLOCK]]

-- [[BLOCK: Diagnostik (LSP)]]
-- cmd: [d      | desc: Vorheriger Fehler
-- cmd: ]d      | desc: Nächster Fehler
-- cmd: <leader>e | desc: Fehlerdetails anzeigen
vim.keymap.set("n", "[d", function()
  pcall(vim.diagnostic.goto_prev)
end, { desc = "Vorheriger Fehler" })
vim.keymap.set("n", "]d", function()
  pcall(vim.diagnostic.goto_next)
end, { desc = "Nächster Fehler" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Fehlerdetails anzeigen" })
-- [[/BLOCK]]
