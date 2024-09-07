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
-- Visual and Passive Enhancements: 被动以及美化插件
local visual_and_passive_enhancements = {
	require("config.plugins.treesitter"),
	require("config.plugins.colorscheme"),
	require("config.plugins.scrollbar"),
	require("config.plugins.statusline"),
	require("config.plugins.winbar"),
	require("config.plugins.indent"),
	require("config.plugins.notify"),
	require("config.plugins.tabline"),
	require("config.plugins.surround"),
}

-- Active Editor Tools: 编辑器主动功能插件
local active_editor_tools = {
	require("config.plugins.telescope"),
	require("config.plugins.filemanager"),
	require("config.plugins.editor"),
	require("config.plugins.comment"),
	require("config.plugins.project"),
	require("config.plugins.window-management"),
	require("config.plugins.yank"),
	require("config.plugins.search"),
	require("config.plugins.undo"),
	require("config.plugins.fun"),
	require("config.plugins.wezterm"),
}

-- Language and LSP Support: LSP插件
local language_and_lsp_support = {
	require("config.plugins.language.lspconfig").config,
	require("config.plugins.language.python"),
	require("config.plugins.language.rust"),
	require("config.plugins.language.markdown"),
	require("config.plugins.language.debugger"),
}

-- Completion and Snippet Plugins: 补全等插件
local completion_and_snippet_plugins = {
	require("config.plugins.autocomplete").config,
	require("config.plugins.snippets"),
	require("config.plugins.copilot"),
}

-- Miscellaneous Plugins: 其他插件
local miscellaneous_plugins = {
	{ "dstein64/vim-startuptime" },
	require("config.plugins.wilder"),
	require("config.plugins.git"),
	require("config.plugins.tex"),
}

-- 集中加载所有分组的插件
require("lazy").setup({
	table.unpack(visual_and_passive_enhancements),
	table.unpack(active_editor_tools),
	table.unpack(language_and_lsp_support),
	table.unpack(completion_and_snippet_plugins),
	table.unpack(miscellaneous_plugins),
})
