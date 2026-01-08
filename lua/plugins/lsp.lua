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
-- ============================================================================
-- LSP Configuration (Neovim 0.12+ Native Style)
-- ============================================================================
-- 1. Global Defaults
vim.lsp.config("*", {
	root_markers = { ".git", ".venv", "pyproject.toml", "Cargo.toml", "package.json", "init.lua" },
	capabilities = {
		textDocument = { semanticTokens = { multilineTokenSupport = true } },
	},
})

-- 2. Specialized Server Settings
vim.lsp.config.lua_ls = {
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
		},
	},
	on_attach = function(client, bufnr)
		-- 硬性禁用格式化
		client.server_capabilities.documentFormattingProvider = false
		client.server_capabilities.documentRangeFormattingProvider = false
		client.server_capabilities.documentOnTypeFormattingProvider = false
	end,
}

vim.lsp.config.ruff = {
	capabilities = {
		hoverProvider = false, -- 直接在此禁用
	},
}
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
	settings = {
		python = {
			analysis = {
				typeCheckingMode = "basic",
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
				diagnosticMode = "openFilesOnly",
			},
		},
	},
	on_attach = function(client, bufnr)
		vim.api.nvim_buf_create_user_command(bufnr, "Venv", set_python_path, { nargs = "?" })
	end,
}

-- 3. Diagnostics Configuration
vim.diagnostic.config({
	severity_sort = true,
	underline = true,
	signs = {
		text = {
			[1] = "✘",
			[2] = "▲",
			[3] = "⚑",
			[4] = "»",
		},
	},
	virtual_text = false, -- Handled by tiny-inline-diagnostic
	float = { border = "rounded", source = "always" },
})

-- 4. Fast Activation & Tooling
-- 仅需在此列表添加 Server 名称即可自动继承全局配置
vim.lsp.enable({
	"lua_ls",
	"pyright",
	"ruff",
	"rust_analyzer",
	"biome",
	"markdown-oxide",
	"dockerls",
	"bashls",
	"nushell",
	"tombi",
	"stylua",
})

-- Inlay Hints (Optional: Toggle with <leader>ih)
vim.keymap.set("n", "<leader>ih", function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "LSP: Toggle Inlay Hints" })

-- Mason Infrastructure
require("mason").setup({ ui = { icons = { package_installed = "✓" } } })

-- 格式化整个文件并保留光标位置
local map = require("utils").map
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
