-- 设置 on_attach 函数，用于设置 LSP 连接时的操作
local function on_attach(client, bufnr)
	require("lsp_signature").on_attach(client, bufnr)
	-- 启用 inlay hints
	if client.server_capabilities.inlayHintProvider then
		vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
	end

	-- 设置诊断配置
	vim.diagnostic.config({
		severity_sort = true,
		underline = true,
		signs = true,
		virtual_text = false,
		update_in_insert = false,
		float = true,
	})

	-- 设置 LSP 图标
	require('lsp-zero').set_sign_icons({
		error = '✘',
		warn = '▲',
		hint = '⚑',
		info = '»',
	})
end

-- 通用格式化函数，区分手动和自动
_G.format_buffer = function(is_manual)
	local format_on_save_filetypes = {
		python = true,
		rust = true,
		lua = true,
	}

	-- 自动保存时需要检查文件类型
	if not is_manual and not format_on_save_filetypes[vim.bo.filetype] then
		return
	end

	local lineno = vim.api.nvim_win_get_cursor(0)
	vim.lsp.buf.format({ async = false })
	pcall(vim.api.nvim_win_set_cursor, 0, lineno)
end

-- 自动格式化保存
local function format_on_save()
	vim.api.nvim_create_autocmd("BufWritePre", {
		pattern = "*",
		callback = function()
			_G.format_buffer(false) -- 自动保存时传入 false
		end,
	})
end

-- 初始化自动格式化保存功能
format_on_save()

-- LSP 服务器配置
local lsp_servers = {
	vimls = {},
	rust_analyzer = {
		settings = {
			["rust-analyzer"] = {
				completion = { autoimport = { enable = false } },
				inlayHints = { typeHints = true },
				cargo = { allFeatures = true },
				checkOnSave = { command = "clippy" },
			}
		},
	},
	pyright = {
		settings = {
			python = {
				pythonPath = "python",
				analysis = {
					autoImportCompletions = false,
					ignore = { '*' },
				},
			},
		},
	},
	jsonls = {},
	lua_ls = {
		settings = {
			Lua = {
				diagnostics = { globals = { 'vim' } },
				workspace = {
					library = vim.api.nvim_get_runtime_file("", true),
					checkThirdParty = false,
				},
			},
		},
	},
	ruff = {
		trace = 'messages',
		init_options = {
			settings = {
				logLevel = 'debug',
				configuration = "~/.config/nvim/ruff.toml",
				configurationPreference = "filesystemFirst",
				lineLength = 100,
				fixAll = true,
				organizeImports = true,
				showSyntaxErrors = true,
			},
		},
	},
}

return {
	{
		'VonHeikemen/lsp-zero.nvim',
		branch = 'v4.x',
		dependencies = {
			{ 'neovim/nvim-lspconfig' },
			{
				'williamboman/mason.nvim',
				build = function()
					vim.cmd([[MasonInstall]])
				end,
			},
			{ 'williamboman/mason-lspconfig.nvim' },
			{ 'ray-x/lsp_signature.nvim' },
			{ 'folke/neodev.nvim' },
			{
				'j-hui/fidget.nvim',
				tag = "legacy",
				config = function()
					require("fidget").setup({
						text = { spinner = "dots" },
						window = { blend = 0 },
					})
				end,
			},
		},
		keys = {
			-- LSP相关快捷键
			{ '<leader>h',  function() vim.lsp.buf.hover() end,                  desc = "LSP Hover" },
			{ 'gd',         function() vim.lsp.buf.definition() end,             desc = "Go to Definition" },
			{ 'gD',         '<cmd>tab split | lua vim.lsp.buf.definition()<CR>', desc = "Open Definition in New Tab" },
			{ 'gi',         function() vim.lsp.buf.implementation() end,         desc = "Go to Implementation" },
			{ 'go',         function() vim.lsp.buf.type_definition() end,        desc = "Go to Type Definition" },
			{ 'gr',         function() vim.lsp.buf.references() end,             desc = "Go to References" },
			{ '<leader>rn', function() vim.lsp.buf.rename() end,                 desc = "Rename Symbol" },
			{ '<leader>,',  function() vim.lsp.buf.code_action() end,            desc = "Code Action" },
			{ '<leader>t',  '<cmd>Trouble<CR>',                                  desc = "Open Trouble" },
			{
				'<leader>-',
				function()
					vim.diagnostic.jump({
						count = -1,                     -- 指定跳转到上一个
						float = true,                   -- 显示浮动窗口
						pos = vim.api.nvim_win_get_cursor(0), -- 当前光标位置
					})
				end,
				desc = "Previous Diagnostic"
			},
			-- 跳转到下一个诊断信息
			{
				'<leader>=',
				function()
					vim.diagnostic.jump({
						count = 1,                      -- 指定跳转到下一个
						float = true,                   -- 显示浮动窗口
						pos = vim.api.nvim_win_get_cursor(0), -- 当前光标位置
					})
				end,
				desc = "Next Diagnostic"
			},
			-- Insert mode keymap
			{ '<c-f>', function() vim.lsp.buf.signature_help() end, mode = 'i', desc = "Signature Help" },
		},
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lsp = require('lsp-zero')

			require('mason').setup({})
			require('mason-lspconfig').setup({
				ensure_installed = {
					'vimls',
					'markdown_oxide',
					'rust_analyzer',
					'pyright',
					'jsonls',
					'lua_ls',
					'ruff'
				},
			})

			-- 设置各个 LSP server
			for server, config in pairs(lsp_servers) do
				require('lspconfig')[server].setup(vim.tbl_extend("force", config, { on_attach = on_attach }))
			end
			lsp.setup()

			-- 绑定快捷键进行手动格式化
			vim.api.nvim_set_keymap('n', '<M-S-f>', ':lua _G.format_buffer(true)<CR>', { noremap = true, silent = true })
		end,
	},
}
