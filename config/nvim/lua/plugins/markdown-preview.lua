return {
  "selimacerbas/markdown-preview.nvim",
  dependencies = { "selimacerbas/live-server.nvim" },
  lazy = false,  -- load immediately
  config = function()
    require("markdown_preview").setup({
      instance_mode = "takeover",  -- "takeover" (1 tab) or "multi" (tab per instance)
      port = 0,                    -- 0 = auto
      open_browser = true,          -- auto-open browser
      debounce_ms = 300,            -- refresh debounce
      scroll_sync = true,           -- cursor scroll sync
      mermaid_renderer = "rust",      -- "js" or "rust" (~400x faster)
    })

    -- Recommended keymaps
    local map = vim.keymap.set
    local opts = { noremap = true, silent = true }
    map("n", "<space>mps", "<cmd>MarkdownPreview<CR>", opts)  -- start preview
    map("n", "<space>mpS", "<cmd>MarkdownPreviewStop<CR>", opts)  -- stop preview
    map("n", "<space>mpr", "<cmd>MarkdownPreviewRefresh<CR>", opts) -- refresh preview
  end,
}
