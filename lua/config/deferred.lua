-- ===========================================================================
-- 延迟加载：依赖插件的初始化
-- ===========================================================================

local map = require("utils.map").map -- 统一的 keymap 封装
local lsp_maps = require("config.keymaps").lsp_maps -- LSP 相关映射配置

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		-- 进入 UI 后再尝试加载目录 Session，并延迟初始化 LSP
		local path = vim.fn.argv(0)
		local s = path and path .. "/Session.vim"
		local path_stat = path and vim.uv.fs_stat(path)
		if s and path_stat and path_stat.type == "directory" and vim.uv.fs_stat(s) then
			vim.cmd.source(s)
		end
		require("config.lsp")
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	callback = function(args)
		-- 仅在真正打开缓冲区时加载 LLM 插件，并启用 treesitter
		require("plugins.llm.codecompanion")
		pcall(vim.treesitter.start, args.buf)
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("LspKeymaps", { clear = true }),
	once = true,
	callback = function()
		-- LSP 启动后再注册映射，避免启动期引入 vim.lsp 链路
		vim.iter(lsp_maps):each(function(m)
			map(unpack(m))
		end)
	end,
})
