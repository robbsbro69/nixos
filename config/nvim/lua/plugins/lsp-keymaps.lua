vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local map = vim.keymap.set
    local opts = { buffer = ev.buf, noremap = true, silent = true }

    map("n", "gd",         vim.lsp.buf.definition,      opts)  -- go to definition
    map("n", "K",          vim.lsp.buf.hover,            opts)  -- docs popup
    map("n", "<leader>rn", vim.lsp.buf.rename,           opts)  -- rename symbol
    map("n", "<leader>ca", vim.lsp.buf.code_action,      opts)  -- code actions
    map("n", "gr",         vim.lsp.buf.references,       opts)  -- find references
    map("n", "[d",         vim.diagnostic.goto_prev,     opts)  -- prev diagnostic
    map("n", "]d",         vim.diagnostic.goto_next,     opts)  -- next diagnostic
  end,
})

return {} -- lazy.nvim requires this
