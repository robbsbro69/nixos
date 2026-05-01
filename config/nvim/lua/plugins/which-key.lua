return {
	"folke/which-key.nvim",
	event = "VimEnter",
	config = function()
		require("which-key").setup()
		require("which-key").add({
			{ "<leader>c", group = "[C]ode" },
			{ "<leader>d", group = "[D]ocument" },
			{ "<leader>r", group = "[R]ename" },
			{ "<leader>s", group = "[S]earch" },
			{ "<leader>w", group = "[W]orkspace" },
			{ "<leader>t", group = "[T]oggle" },
			{ "<leader>h", group = "[H]arpoon" },
			{ "<leader>g", group = "[G]it" },
			{ "<leader>l", group = "[L]LM / opencode" },
			{ "<leader>m", group = "[M]arkdown preview" },
		})
	end,
}
