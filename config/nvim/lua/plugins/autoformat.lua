return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>F",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = "",
      desc = "[F]ormat buffer manually",
    },
  },
  opts = {
    default_format_opts = { async = true, lsp_fallback = true },
    notify_on_error = false,
    format_on_save = function(bufnr)
      -- Disable for languages without a standardized style
      local disable_filetypes = { c = true, cpp = true }
      return {
        timeout_ms = 500,
        lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
      }
    end,
    formatters_by_ft = {
      rust        = { "rustfmt" },
      lua         = { "stylua" },
      javascript  = { "biome-check", "prettierd", "prettier", stop_after_first = true },
      typescript  = { "biome-check", "prettierd", "prettier", stop_after_first = true },
      html        = { "prettierd", stop_after_first = true },
      css         = { "prettierd", "prettier", stop_after_first = true },
      json        = { "biome-check", "prettierd", stop_after_first = true },
      nix         = { "alejandra" },
    },
    formatters = {
      ["biome-check"] = {
        command = "biome",
      },
    },
  },
}
