return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("tokyonight").setup({
      style = "storm", -- best for you
      transparent = true,
    })

    vim.cmd.colorscheme("tokyonight")
  end,
}
