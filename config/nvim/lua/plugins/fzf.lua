return {
  {
    "ibhagwan/fzf-lua",
    lazy = false, -- load immediately
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- optional
    config = function()
      -- wrap in pcall to avoid errors if plugin didn't load
      local ok, FzfLua = pcall(require, "fzf-lua")
      if not ok then
        vim.notify("fzf-lua failed to load", vim.log.levels.ERROR)
        return
      end

      -- keymaps
      local map = vim.keymap.set
      local opts = { noremap = true, silent = true }

      map("n", "<Space>f", function() FzfLua.files() end, opts)
      map("n", "<Space>g", function() FzfLua.live_grep() end, opts)
      map("n", "<Space>b", function() FzfLua.buffers() end, opts)
      map("n", "<Space>c", function() FzfLua.commands() end, opts)
      map("n", "<F1>", function() FzfLua.help() end, opts)
    end,
  },
}
