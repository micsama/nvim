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
local function disable_diagnostics(client)
	client.handlers["textDocument/publishDiagnostics"] = function() end
end
-- 1. Global Defaults
vim.filetype.add({
	-- 1. 处理特定的文件名
	filename = {
		["docker-compose.yaml"] = "yaml",
		["docker-compose.yml"] = "yaml",
		["compose.yaml"] = "yaml",
		["compose.yml"] = "yaml",
	},
	-- 2. 处理后缀名（解决 typescript.tsx 这种非标准识别）
	extension = {
		tsx = "typescriptreact",
		jsx = "javascriptreact",
		-- 如果你有其他的非标准后缀也可以往这加
	},
})
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
		client.server_capabilities.documentFormattingProvider = false
		client.server_capabilities.documentRangeFormattingProvider = false
		client.server_capabilities.documentOnTypeFormattingProvider = false
	end,
}

vim.lsp.config.ruff = {
	on_attach = function(client, bufnr)
		client.server_capabilities.hoverProvider = false
	end,
	init_options = {
		settings = {
			showSyntaxErrors = false, -- 关键：不要让 ruff 报语法错误
		},
	},
}

vim.lsp.config.basedpyright = {
	settings = {
		basedpyright = {
			analysis = {
				diagnosticSeverityOverrides = {
					-- reportUnusedImport = "none",
					-- reportUnusedVariable = "none",
					-- reportUnusedParameter = "none",
					-- reportUnusedFunction  = "none",
					-- reportUnusedClass     = "none",
				},
				typeCheckingMode = "basic",
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
				diagnosticMode = "openFilesOnly",
			},
		},
	},
	on_attach = function(client, bufnr)
		-- 把“高频交互、性能敏感”的能力交给 pyrefly
		client.server_capabilities.referencesProvider = false
		client.server_capabilities.completionProvider = false
		client.server_capabilities.definitionProvider = false
		client.server_capabilities.documentHighlightProvider = false
		client.server_capabilities.renameProvider = false
		client.server_capabilities.semanticTokensProvider = false
		-- vim.api.nvim_buf_create_user_command(bufnr, "Venv", set_python_path, { nargs = "?" })
	end,
}

vim.lsp.config.pyrefly = {
	cmd = { "pyrefly", "lsp" },
	filetypes = { "python" },
	on_attach = function(client, bufnr)
		-- basedpyright 更权威：这些都关掉，后续pyrefly发展好了的话，在启用。
		client.server_capabilities.hoverProvider = false
		client.server_capabilities.signatureHelpProvider = false
		client.server_capabilities.referenceProvider = false
		client.server_capabilities.documentSymbolProvider = false
		client.server_capabilities.inlayHintProvider = false
		client.server_capabilities.codeActionProvider = false
		disable_diagnostics(client)
	end,
}

-- local function set_python_path(command)
--   local path = (command.args and #command.args > 0) and command.args or "./.venv/bin/python"
--   local clients = vim.lsp.get_clients({ bufnr = 0, name = "basedpyright" })
--   for _, client in ipairs(clients) do
--     client.config.settings.basedpyright.pythonPath = path
--     client:notify("workspace/didChangeConfiguration", { settings = client.config.settings })
--   end
--   vim.notify("pythonPath -> " .. path, vim.log.levels.INFO)
-- end
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
	"lua_ls", -- Lua: 针对 Neovim 配置的核心支持
	"basedpyright", -- Python: 微软提供的静态类型检查与补全
	"pyrefly",
	"ruff", -- Python: 极速的代码规范检查与格式化 (替代 flake8/isort)
	"rust_analyzer", -- Rust: 官方推荐的高级语言支持
	"biome", -- JS/TS/JSON: 性能极高的 Web 开发工具链 (取代 Prettier/ESLint)
	"markdown-oxide", -- Markdown: 基于 PKM 理念的超强双向链接与补全
	"docker_language_server", -- Docker: Dockerfile 的官方语法支持与 Lint
	"bashls", -- Bash: 脚本自动补全与 shellcheck 集成
	"nushell", -- Nushell: 针对这个现代 Shell 的脚本支持
	"tombi", -- Taplo/TOML: 如果是用于 TOML 文件 (通常包名为 taplo)
	"stylua", -- Lua Formatter:
	"jsonls", -- JSON: 官方提供的模式验证与属性补全
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
