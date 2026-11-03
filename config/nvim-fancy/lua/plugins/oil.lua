return {
  "stevearc/oil.nvim",
  lazy = false,
  opts = {},
  dependencies = { { "echasnovski/mini.icons", opts = {} } },
  keys = {
    {
      mode = "n",
      "<leader>o",
      "<cmd>Oil<CR>",
      desc = "Oil: Open file viewer",
    },
  },
}
