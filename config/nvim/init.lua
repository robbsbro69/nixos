-- ~/.config/nvim/init.lua — minimal: just code and run (tsoding vibes)
-- one file · gruber-darker · compile mode · built-in LSP · no icons, no trees, no popups

vim.g.mapleader = " "

-- ── options ────────────────────────────────────────────────────
local o = vim.o
o.number, o.relativenumber = true, true
o.tabstop, o.shiftwidth, o.softtabstop, o.expandtab = 4, 4, 4, true
o.smartindent = true
o.scrolloff = 8
o.signcolumn = "auto"
o.termguicolors = true
o.clipboard = "unnamedplus"
o.undofile, o.swapfile = true, false
o.ignorecase, o.smartcase = true, true
o.mouse = "a"
o.cursorline = false
o.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20"
o.path = ".,**"                               -- :find searches the project
o.wildoptions = "pum,fuzzy"                   -- fuzzy file / command completion
o.wildignore = "*.o,*.a,*/target/*,*/node_modules/*,*/.git/*,*/result/*"
o.grepprg = "rg --vimgrep --smart-case"
o.grepformat = "%f:%l:%c:%m"
o.laststatus = 2
o.statusline = " %f %m%r%=%y  %l:%c "
o.completeopt = "menuone,noselect,popup"
vim.g.netrw_banner = 0

-- ── plugins (built-in vim.pack, nvim 0.12) ─────────────────────
vim.pack.add({
	"https://github.com/blazkowolf/gruber-darker.nvim",
	"https://github.com/neovim/nvim-lspconfig",   -- only server configs; nothing runs unless the server is installed
}, { confirm = false })
pcall(vim.cmd.colorscheme, "gruber-darker")

-- ── compile mode (like emacs M-x compile) ──────────────────────
-- <leader>c asks for a command (prefilled), runs it, streams output into the quickfix list;
-- errors become jumpable entries (]q / [q / <CR> on a line). <leader>r reruns. % = current file.
local last_cmd
local function default_cmd()
	local ft, has = vim.bo.filetype, function(f) return vim.fn.filereadable(f) == 1 end
	if has("Makefile") or has("makefile") then return "make" end
	if has("Cargo.toml") then return "cargo run" end
	if has("build.sh") then return "./build.sh" end
	return ({
		c = "cc -Wall -Wextra -g -o /tmp/a.out % && /tmp/a.out",
		cpp = "c++ -std=c++20 -Wall -Wextra -g -o /tmp/a.out % && /tmp/a.out",
		rust = "rustc % -o /tmp/a.out && /tmp/a.out",
		python = "python3 %",
		lua = "lua %",
		sh = "bash %",
		go = "go run %",
		javascript = "node %",
		typescript = "npx tsx %",
		nix = "nix eval --file %",
	})[ft] or ""
end

local job
local function compile(cmd)
	if not cmd or cmd == "" then return end
	last_cmd = cmd
	local expanded = vim.fn.expandcmd(cmd)
	vim.cmd("silent! wall")
	if job then vim.fn.jobstop(job) end
	vim.fn.setqflist({}, " ", { title = expanded, lines = { "-*- compile: " .. expanded .. " -*-", "" } })
	vim.cmd("botright copen 12 | wincmd p")
	local start, partial = vim.uv.hrtime(), { "", "" }
	local function feed(i)
		return function(_, data)
			if not data then return end
			data[1] = partial[i] .. data[1]
			partial[i] = table.remove(data)            -- last piece may be an unfinished line
			if #data > 0 then
				vim.fn.setqflist({}, "a", { lines = data, efm = vim.o.errorformat })
				vim.cmd("cbottom")
			end
		end
	end
	job = vim.fn.jobstart({ "sh", "-c", expanded }, {
		stdout_buffered = false, on_stdout = feed(1), on_stderr = feed(2),
		on_exit = function(_, code)
			job = nil
			local rest = vim.tbl_filter(function(s) return s ~= "" end, partial)
			local secs = (vim.uv.hrtime() - start) / 1e9
			table.insert(rest, "")
			table.insert(rest, code == 0 and ("Compilation finished in %.2fs"):format(secs)
				or ("Compilation exited abnormally with code %d after %.2fs"):format(code, secs))
			vim.fn.setqflist({}, "a", { lines = rest, efm = vim.o.errorformat })
			vim.cmd("cbottom")
		end,
	})
end

local map = vim.keymap.set
map("n", "<leader>c", function()
	vim.ui.input({ prompt = "Compile: ", default = last_cmd or default_cmd(), completion = "shellcmd" }, compile)
end, { desc = "compile / run" })
map("n", "<leader>r", function() if last_cmd then compile(last_cmd) else vim.notify("nothing to recompile") end end, { desc = "recompile" })
map("n", "<leader>k", function() if job then vim.fn.jobstop(job) end end, { desc = "kill compilation" })
map("n", "<leader>q", "<cmd>cclose<cr>", { desc = "close output" })

-- ── navigation (all built-in) ──────────────────────────────────
map("n", "<leader>f", ":find ", { desc = "find file (fuzzy)" })
map("n", "<leader>b", ":buffer ", { desc = "switch buffer" })
map("n", "<leader>g", ":silent grep! ", { desc = "grep project → quickfix" })
map("n", "-", "<cmd>Explore<cr>", { desc = "file browser" })
map("n", "<leader>t", "<cmd>botright split | resize 12 | terminal<cr>i", { desc = "terminal" })
map("t", "<Esc><Esc>", [[<C-\><C-n>]])
map("n", "<Esc>", "<cmd>nohlsearch<cr>")
vim.api.nvim_create_autocmd("QuickFixCmdPost", { pattern = "grep", command = "botright cwindow" })

-- ── LSP: completion + go-to, quietly ───────────────────────────
-- enabled only for servers that are actually installed
local servers = {
	clangd = "clangd", pyright = "pyright-langserver", rust_analyzer = "rust-analyzer",
	lua_ls = "lua-language-server", nil_ls = "nil", nixd = "nixd", ts_ls = "typescript-language-server",
	gopls = "gopls", qmlls = "qmlls",
}
for name, bin in pairs(servers) do
	if vim.fn.executable(bin) == 1 then vim.lsp.enable(name) end
end
vim.lsp.config("lua_ls", { settings = { Lua = { diagnostics = { globals = { "vim", "hl" } } } } })

vim.diagnostic.config({ virtual_text = false, signs = false, underline = true, severity_sort = true, float = { border = "single" } })
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if client and client:supports_method("textDocument/completion") then
			vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
		end
		local b = { buffer = ev.buf }
		map("n", "gd", vim.lsp.buf.definition, b)
		map("n", "<leader>d", vim.diagnostic.open_float, b)
		map("n", "<leader>a", function() vim.diagnostic.setqflist() end, b)   -- all diagnostics → quickfix
		-- built-in defaults stay: K hover, grn rename, gra code action, grr references, ]d [d
	end,
})

-- ── yazi (Space y): floating yazi, Enter on a file opens it here ──
map("n", "<leader>y", function()
	if vim.fn.executable("yazi") == 0 then return vim.notify("yazi not installed") end
	local chooser = vim.fn.tempname()
	local start = vim.fn.expand("%:p")
	if start == "" or vim.bo.buftype ~= "" then start = vim.fn.getcwd() end
	local w, h = math.floor(vim.o.columns * 0.88), math.floor(vim.o.lines * 0.82)
	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor", width = w, height = h, style = "minimal", border = "single",
		col = math.floor((vim.o.columns - w) / 2), row = math.floor((vim.o.lines - h) / 2),
	})
	vim.fn.jobstart({ "yazi", start, "--chooser-file=" .. chooser }, {
		term = true,
		on_exit = function()
			vim.schedule(function()
				if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
				if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
				local f = io.open(chooser)
				if not f then return end
				for path in f:lines() do vim.cmd.edit(vim.fn.fnameescape(path)) end
				f:close(); os.remove(chooser)
			end)
		end,
	})
	vim.cmd.startinsert()
end, { desc = "yazi file manager" })

-- see-through background: kitty's colour + opacity show behind nvim
local function clear_bg()
  for _, g in ipairs({ "Normal", "NormalNC", "SignColumn", "LineNr", "CursorLineNr", "EndOfBuffer", "FoldColumn", "WinSeparator" }) do
    local hl = vim.api.nvim_get_hl(0, { name = g, link = false })
    hl.bg, hl.ctermbg = nil, nil
    vim.api.nvim_set_hl(0, g, hl)
  end
end
vim.api.nvim_create_autocmd("ColorScheme", { callback = clear_bg })
clear_bg()

-- wrap long lines to the window, at word boundaries, keeping indentation
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
