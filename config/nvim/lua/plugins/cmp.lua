return {
    {
        'saghen/blink.cmp',
        dependencies = { 'rafamadriz/friendly-snippets' },

        version = '1.*',

        opts = {
            keymap = {
  		preset = 'default',
  		['<CR>'] = {}, -- disable enter completely
  		['<Tab>'] = { 'select_and_accept', 'fallback' }, -- use tab to confirm instead
	},

            appearance = {
                nerd_font_variant = 'mono'
            },

            -- completion = {
            --     documentation = {
            --         auto_show = true,
            --         auto_show_delay_ms = 50
            --     }
            -- },

            sources = {
                default = { 'lsp', 'path', 'snippets', 'buffer' },
            },

            signature = { enabled = true },
            fuzzy = { implementation = "prefer_rust_with_warning" }
        },
    }
}
