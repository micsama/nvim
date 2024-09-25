-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
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

	-- 基础功能与编辑器美化
	require("config.plugins.colorscheme"),
	require("config.plugins.statusline"),
	require("config.plugins.winbar"),
	require("config.plugins.scrollbar"),
	require("config.plugins.tabline"),
	require("config.plugins.indent"), -- 等官方修复bug
	require("config.plugins.notify"),
	require("config.plugins.dash"),

	-- 增强编辑效率
	require("config.plugins.editor"),
	require("config.plugins.filemanager"), -- 以后再看其他的功能
	require("config.plugins.whichkey"),
	require("config.plugins.telescope"),
	require("config.plugins.project"), -- 删除了vimrooter
	require("config.plugins.undo"),
	require("config.plugins.yank"),
	require("config.plugins.window-management"),
	require("config.plugins.surround"),
	require("config.plugins.comment"),

	-- 语言支持与配置
	require("config.plugins.language.lspconfig"),
	require("config.plugins.language.python"),
	require("config.plugins.language.rust"),
	require("config.plugins.language.markdown"),
	require("config.plugins.language.other"),
	require("config.plugins.language.dap"),
	require("config.plugins.language.coder-runner"),
	require("config.plugins.language.auto-cmp"),

	-- 较复杂的功能扩展
	require("config.plugins.treesitter"),
	require("config.plugins.wilder"),
	require("config.plugins.search"), -- 回头再研究
	require("config.plugins.fun"),
	require("config.plugins.llm"),
	require("config.plugins.git"),
	require("config.plugins.wezterm"),
	-- require("config.plugins.tex"),

	-- 其他插件
	{ "dstein64/vim-startuptime" },
})
