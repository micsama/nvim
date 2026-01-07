--  ██╗     ███████╗██████╗
--  ██║     ██╔════╝██╔══██╗
--  ██║     ███████╗██████╔╝
--  ██║     ╚════██║██╔═══╝
--  ███████╗███████║██║
--  ╚══════╝╚══════╝╚═╝
-- Language Server Protocol Configuration
-- 💻 Intelligent Code Completion & Analysis
-- ============================================================================
-- 模块引入与实用工具
-- ============================================================================
-- 1. Lua 诊断与分析
vim.lsp.config.lua_ls = {
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
			diagnostics = { globals = { "vim" } },
			workspace = { checkThirdParty = false },
		},
	},
	on_attach = function(client)
		-- 核心：必须禁用 lua_ls 的格式化，确保不与 StyLua 冲突
		client.server_capabilities.documentFormattingProvider = false
		client.server_capabilities.documentRangeFormattingProvider = false
	end,
}

-- 3. Python 及其它配置 (保持之前的优化结构)
local function set_python_path(command)
	local path = (command.args and #command.args > 0) and command.args or "./.venv/bin/python"
	local clients = vim.lsp.get_clients({ bufnr = 0, name = "pyright" })
	for _, client in ipairs(clients) do
		client.config.settings.python.pythonPath = path
		client:notify("workspace/didChangeConfiguration", { settings = client.config.settings })
	end
	vim.notify("Pyright path -> " .. path, vim.log.levels.INFO)
end

vim.lsp.config.pyright = {
	settings = { python = { analysis = { typeCheckingMode = "off" } } },
	on_attach = function(client, bufnr)
		vim.api.nvim_buf_create_user_command(bufnr, "Venv", set_python_path, { nargs = "?" })
	end,
}

-- Ruff 编码补丁
vim.lsp.config.ruff = {
	capabilities = { offsetEncoding = { "utf-16" } },
}

-- 4. 诊断 UI 配置
vim.diagnostic.config({
	severity_sort = true,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "✘",
			[vim.diagnostic.severity.WARN] = "▲",
			[vim.diagnostic.severity.HINT] = "⚑",
			[vim.diagnostic.severity.INFO] = "»",
		},
	},
	virtual_text = false,
	float = { border = "rounded" },
})

-- 5. 一键启用所有服务
vim.lsp.enable({
	"lua_ls",
	"stylua",
	"pyright",
	"ruff",
	"rust_analyzer",
	"jsonls",
	"markdown-oxide",
	"bashls",
	"dockerls",
	"biome",
	"tombi",
	"nushell",
})
-- 格式化整个文件并保留光标位置
map("niv", "<D-S-f>", function()
	vim.notify("Formatting...")
	local cursor = vim.api.nvim_win_get_cursor(0)
	vim.lsp.buf.format({ async = false })
	pcall(vim.api.nvim_win_set_cursor, 0, cursor)
end, "格式化文件")

-- ============================================================================
-- Treesitter 及其他辅助插件
-- ============================================================================

-- Treesitter 要求禁用 smartindent
vim.opt.smartindent = false

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "<filetype>" },
	callback = function()
		vim.treesitter.start()
	end,
})
require("nvim-treesitter").setup({
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = "<CR>",
			node_incremental = "<CR>",
			node_decremental = "<s-CR>",
			scope_incremental = "<c-l>",
		},
	},
	install_dir = vim.fn.stdpath("data") .. "/site",
})

-- Treesitter 辅助插件
require("treesitter-context").setup()
require("faster").setup({
	behaviours = {
		bigfile = {
			features_disabled = {
				"illuminate",
				"matchparen",
				"lsp",
				"treesitter",
				"indent_blankline",
				"vimopts",
				-- "syntax",
				-- "filetype",
			},
			filesize = 10,
		},
	},
})
require("render-markdown").setup({
	file_types = { "markdown", "codecompanion", "vimwiki" },
	completions = { lsp = { enabled = true } },
})
