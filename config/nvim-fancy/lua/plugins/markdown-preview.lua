return {
	"selimacerbas/markdown-preview.nvim",
	dependencies = { "selimacerbas/live-server.nvim" },
	lazy = false,
	config = function()
		require("markdown_preview").setup({
			instance_mode = "takeover",
			port = 0,
			open_browser = true,
			debounce_ms = 300,
			scroll_sync = true,
			mermaid_renderer = "rust",
		})
		local map = vim.keymap.set
		local opts = { noremap = true, silent = true }
		map("n", "<space>mps", "<cmd>MarkdownPreview<CR>", opts)
		map("n", "<space>mpS", "<cmd>MarkdownPreviewStop<CR>", opts)
		map("n", "<space>mpr", "<cmd>MarkdownPreviewRefresh<CR>", opts)
	end,
}
