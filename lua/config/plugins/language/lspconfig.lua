-- 设置 on_attach 函数，用于设置 LSP 连接时的操作
local function on_attach(client, bufnr)
	require("lsp_signature").on_attach(client, bufnr)
	-- 启用 inlay hints
	if client.server_capabilities.inlayHintProvider then
		vim.lsp.inlay_hint(bufnr, true)
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
	local lsp = require('lsp-zero')
	lsp.set_sign_icons({
		error = '✘',
		warn = '▲',
		hint = '⚑',
		info = '»',
	})
end

-- 自动格式化保存函数优化
local function format_on_save()
	local format_on_save_filetypes = {
		python = true,
		rust = true,
		lua = true,
	}
	vim.api.nvim_create_autocmd("BufWritePre", {
		pattern = "*",
		callback = function()
			if format_on_save_filetypes[vim.bo.filetype] then
				local lineno = vim.api.nvim_win_get_cursor(0)
				vim.lsp.buf.format({ async = false })
				pcall(vim.api.nvim_win_set_cursor, 0, lineno)
			end
		end,
	})
end

-- 合并配置中的重复代码，设置 LSP server
local lsp_servers = {
	vimls = {},
	rust_analyzer = {
		settings = {
			["rust-analyzer"] = {
				completion = {
					autoimport = {
						enable = false
					}
				},
				inlayHints = {
					typeHints = true,
				},
				cargo = { allFeatures = true },
				checkOnSave = { command = "clippy" },
			}
		},
	},
	pyright = {
		pyright = { disableOrganizeImports = true, },
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
			Lua = { diagnostics = { globals = { 'vim' } }, workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false } },
		},
	},
	ruff = {
		trace = 'messaegs',
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
						text = {
							spinner = "dots",
						},
						window = {
							blend = 0,
						},
					})
				end,
			},
		},
		-- 使用 keys 和事件懒加载
		keys = {
			-- Normal mode keymaps
			{ 'n', '<leader>h',  function() vim.lsp.buf.hover() end,                        desc = "LSP Hover" },
			{ 'n', 'gd',         function() vim.lsp.buf.definition() end,                   desc = "Go to Definition" },
			{ 'n', 'gD',         '<cmd>tab split | lua vim.lsp.buf.definition()<CR>',       desc = "Open Definition in New Tab" },
			{ 'n', 'gi',         function() vim.lsp.buf.implementation() end,               desc = "Go to Implementation" },
			{ 'n', 'go',         function() vim.lsp.buf.type_definition() end,              desc = "Go to Type Definition" },
			{ 'n', 'gr',         function() vim.lsp.buf.references() end,                   desc = "Go to References" },
			{ 'n', '<leader>rn', function() vim.lsp.buf.rename() end,                       desc = "Rename Symbol" },
			{ 'n', '<leader>,',  function() vim.lsp.buf.code_action() end,                  desc = "Code Action" },
			{ 'n', '<leader>t',  '<cmd>Trouble<CR>',                                        desc = "Open Trouble" },
			{ 'n', '<leader>-',  function() vim.diagnostic.goto_prev({ float = true }) end, desc = "Previous Diagnostic" },
			{ 'n', '<leader>=',  function() vim.diagnostic.goto_next({ float = true }) end, desc = "Next Diagnostic" },

			-- Insert mode keymaps
			{ 'i', '<c-f>',      function() vim.lsp.buf.signature_help() end,               desc = "Signature Help" },
		},
		-- 通过文件事件进行懒加载
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lsp = require('lsp-zero')

			require('mason').setup({})
			require('mason-lspconfig').setup({
				ensure_installed = {
					'vimls',
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
			format_on_save()
		end,
	},
}
