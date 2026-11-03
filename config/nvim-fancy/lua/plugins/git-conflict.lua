return {
	"akinsho/git-conflict.nvim",
	version = "*",
	event = "VeryLazy",
	opts = {
		default_mappings = true,
		default_commands = true,
		disable_diagnostics = false,
		list_opener = "copen",
		highlights = {
			incoming = "DiffAdd",
			current = "DiffText",
		},
	},
}
