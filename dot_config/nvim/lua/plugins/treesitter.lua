return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    main = "nvim-treesitter",
    config = function()
      require("nvim-treesitter").setup()
    end,
  },
}
