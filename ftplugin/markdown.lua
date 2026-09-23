-- ===========================================================================
-- ftplugin: markdown
-- ===========================================================================

vim.opt_local.complete = { ".", "b" }

-- 插件在 init.lua 里只安装不加载；首个 markdown（或 codecompanion）buffer 时加载一次
if not package.loaded["render-markdown"] then
	vim.cmd.packadd("render-markdown.nvim")
	vim.cmd.packadd("bullets.nvim")
	require("render-markdown").setup({
		file_types = { "markdown", "codecompanion", "vimwiki" },
		completions = { lsp = { enabled = true } },
	})
	require("Bullets").setup({}) -- 默认配置
end
