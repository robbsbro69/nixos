return {
	"nvim-telescope/telescope.nvim",
	event = "VimEnter",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
			cond = function()
				return vim.fn.executable("make") == 1
			end,
		},
		{ "nvim-telescope/telescope-ui-select.nvim" },
	},
	config = function()
		require("telescope").setup({
			defaults = {
				vimgrep_arguments = {
					"rg",
					"--follow",
					"--hidden",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
					"--glob=!**/.git/*",
					"--glob=!**/node_modules/",
					"--glob=!**/dist/*",
					"--glob=!**/build/*",
				},
			},
			pickers = {
				find_files = {
					hidden = true,
					find_command = {
						"rg",
						"--files",
						"--hidden",
						"--glob=!**/.git/*",
						"--glob=!**/node_modules/",
					},
				},
			},
			extensions = {
				["ui-select"] = {
					require("telescope.themes").get_dropdown(),
				},
				fzf = {},
			},
		})

		pcall(require("telescope").load_extension, "fzf")
		pcall(require("telescope").load_extension, "ui-select")

		local builtin = require("telescope.builtin")

		vim.keymap.set("n", "<Space>f", builtin.find_files, { desc = "[S]earch [F]iles" })
		vim.keymap.set("n", "<Space>g", builtin.live_grep, { desc = "[S]earch by [G]rep" })
		vim.keymap.set("n", "<Space>b", builtin.buffers, { desc = "Find existing [B]uffers" })
		vim.keymap.set("n", "<Space>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
		vim.keymap.set("n", "<Space>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
		vim.keymap.set("n", "<Space>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
		vim.keymap.set("n", "<Space>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
		vim.keymap.set("n", "<Space>sr", builtin.resume, { desc = "[S]earch [R]esume" })
		vim.keymap.set("n", "<Space>s.", builtin.oldfiles, { desc = "[S]earch Recent files" })
		vim.keymap.set("n", "<Space>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
		vim.keymap.set("n", "<F1>", builtin.help_tags, { desc = "Help" })

		vim.keymap.set("n", "<Space>/", function()
			builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
				winblend = 10,
				previewer = false,
				skip_empty_lines = true,
			}))
		end, { desc = "[/] Fuzzily search in current buffer" })
	end,
}
