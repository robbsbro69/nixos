return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },

  config = function()
    require("lualine").setup({
      options = {
        theme = "tokyonight", -- matches your setup
        section_separators = "",
        component_separators = "",
      },

      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff" }, -- 👈 THIS is what you want
        lualine_c = { "filename" },

        lualine_x = { "encoding", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    })
  end,
}
