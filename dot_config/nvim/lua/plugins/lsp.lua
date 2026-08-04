return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "clangd",   -- C/C++ (Arduino)
          "pyright",  -- Python
          "lua_ls",   -- Lua
          "bashls",   -- Bash
          "ts_ls",    -- TypeScript/JavaScript
          "html",     -- HTML
          "cssls",    -- CSS/SCSS
          "jsonls",   -- JSON
          "yamlls",   -- YAML
          "marksman", -- Markdown
          "dockerls", -- Dockerfile
        },
        automatic_enable = false,
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      require("lsp")
    end,
  },
}
