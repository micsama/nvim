local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

local lazy_cmd = require("lazy.view.config").commands
local lazy_keys = {
	{ cmd = "install", key = "i" },
	{ cmd = "update",  key = "u" },
	{ cmd = "sync",    key = "s" },
	{ cmd = "clean",   key = "cl" },
	{ cmd = "check",   key = "ch" },
	{ cmd = "log",     key = "l" },
	{ cmd = "restore", key = "rs" },
	{ cmd = "profile", key = "p" },
	{ cmd = "profile", key = "p" },
}
for _, v in ipairs(lazy_keys) do
	lazy_cmd[v.cmd].key = "<SPC>" .. v.key
	lazy_cmd[v.cmd].key_plugin = "<leader>" .. v.key
end

vim.keymap.set("n", "<leader>pl", ":Lazy<CR>", { noremap = true })
require("lazy").setup({

	-- 编辑器美化与界面优化
	require("config.plugins.colorscheme"),
	require("config.plugins.treesitter"),
	require("config.plugins.statusline"),
	require("config.plugins.winbar"),
	require("config.plugins.scrollbar"),
	require("config.plugins.tabline"),
	require("config.plugins.indent"),

	-- 增强编辑效率
	require("config.plugins.filemanager"),
	require("config.plugins.telescope"),
	require("config.plugins.notify"),
	require("config.plugins.editor"),
	require("config.plugins.project"),
	require("config.plugins.search"),
	require("config.plugins.undo"),
	require("config.plugins.window-management"),
	require("config.plugins.fun"),

	-- 语言支持与配置
	require("config.plugins.language.lspconfig"),
	require("config.plugins.language.python"),
	require("config.plugins.language.rust"),
	require("config.plugins.language.markdown"),
	require("config.plugins.language.debugger"),

	-- 自动补全
	require("config.plugins.autocomplete").config,

	-- 其他功能扩展
	require("config.plugins.comment"),
	require("config.plugins.git"),
	require("config.plugins.yank"),
	require("config.plugins.surround"),
	require("config.plugins.wilder"),
	require("config.plugins.tex"),
	require("config.plugins.wezterm"),
	{ "dstein64/vim-startuptime" },
})
