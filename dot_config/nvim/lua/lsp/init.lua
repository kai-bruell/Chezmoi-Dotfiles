local servers = {
  "clangd",
  "pyright",
  "lua_ls",
  "bashls",
  "ts_ls",
  "html",
  "cssls",
  "jsonls",
  "yamlls",
  "marksman",
  "dockerls",
}

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      telemetry = { enable = false },
      workspace = { checkThirdParty = false },
    },
  },
})

vim.lsp.enable(servers)

vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  float = { border = "rounded" },
})
