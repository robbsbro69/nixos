return {
	{
		"j-hui/fidget.nvim",
		opts = {},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"j-hui/fidget.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc)
						vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end
					map("gd", function()
						require("telescope.builtin").lsp_definitions()
					end, "[G]oto [D]efinition")
					map("gr", function()
						require("telescope.builtin").lsp_references()
					end, "[G]oto [R]eferences")
					map("gI", function()
						require("telescope.builtin").lsp_implementations()
					end, "[G]oto [I]mplementation")
					map("<leader>D", function()
						require("telescope.builtin").lsp_type_definitions()
					end, "Type [D]efinition")
					map("<leader>ds", function()
						require("telescope.builtin").lsp_document_symbols()
					end, "[D]ocument [S]ymbols")
					map("<leader>ws", function()
						require("telescope.builtin").lsp_dynamic_workspace_symbols()
					end, "[W]orkspace [S]ymbols")
					map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
					map("K", vim.lsp.buf.hover, "Hover docs")
					map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame symbol")
					map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
					map("[d", vim.diagnostic.goto_prev, "Prev [D]iagnostic")
					map("]d", vim.diagnostic.goto_next, "Next [D]iagnostic")

					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
						map("<leader>th", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
						end, "[T]oggle Inlay [H]ints")
					end
					if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
						local hi = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							group = hi,
							callback = vim.lsp.buf.document_highlight,
						})
						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							group = hi,
							callback = vim.lsp.buf.clear_references,
						})
					end
				end,
			})
			local capabilities = vim.tbl_deep_extend(
				"force",
				vim.lsp.protocol.make_client_capabilities(),
				require("cmp_nvim_lsp").default_capabilities()
			)
			vim.lsp.config("rust_analyzer", {
				capabilities = capabilities,
				settings = {
					["rust-analyzer"] = {
						checkOnSave = true,
						check = { command = "clippy" },
					},
				},
			})
			vim.lsp.config("lua_ls", {
				capabilities = capabilities,
				settings = {
					Lua = {
						completion = { callSnippet = "Replace" },
						diagnostics = { globals = { "vim" } },
					},
				},
			})
			vim.lsp.enable("rust_analyzer")
			vim.lsp.enable("lua_ls")
		end,
	},
}
