return {
	{
		"abecodes/tabout.nvim",
		lazy = false,
		priority = 1000,
		event = "InsertCharPre",
		config = function()
			require("tabout").setup({
				tabkey = "<Tab>",
				backwards_tabkey = "<S-Tab>",
				act_as_tab = true,
				enable_backwards = true,
				completion = false,
				tabouts = {
					{ open = "'", close = "'" },
					{ open = '"', close = '"' },
					{ open = "`", close = "`" },
					{ open = "(", close = ")" },
					{ open = "[", close = "]" },
					{ open = "{", close = "}" },
				},
				ignore_beginning = true,
			})
		end,
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"L3MON4D3/LuaSnip",
			"hrsh7th/nvim-cmp",
		},
	},
	{
		"L3MON4D3/LuaSnip",
		keys = function()
			return {}
		end,
	},
}
