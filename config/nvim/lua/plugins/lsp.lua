return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.lsp.config("rust_analyzer", {
        settings = {
          ["rust-analyzer"] = {
            checkOnSave = true,
            check = {
              command = "clippy",
            },
          },
        },
      })
      vim.lsp.enable("rust_analyzer")
    end,
  },
}
