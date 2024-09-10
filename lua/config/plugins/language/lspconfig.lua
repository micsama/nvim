-- lsp_config.lua
-- 提取 on_attach 函数，用于设置 LSP 连接时的操作
local function on_attach(client, bufnr)
	require("lsp_signature").on_attach(client, bufnr)
	-- 在 on_attach 函数中添加以下代码来启用 inlay hints
	if client.server_capabilities.inlayHintProvider then
		vim.lsp.inlay_hint.enable(true, { bufnr = bufnr }) -- 设置 enable 为 true，指定当前的 bufnr
	end

	vim.diagnostic.config({
		severity_sort = true,
		underline = true,
		signs = true,
		virtual_text = false,
		update_in_insert = false,
		float = true,
	})

	local lsp = require('lsp-zero')
	lsp.set_sign_icons({
		error = '✘',
		warn = '▲',
		hint = '⚑',
		info = '»',
	})

	-- 定义快捷键配置
	local keymaps = {
		['n'] = {
			['<leader>h'] = vim.lsp.buf.hover,
			['gd'] = vim.lsp.buf.definition,
			['gD'] = '<cmd>tab split | lua vim.lsp.buf.definition()<CR>',
			['gi'] = vim.lsp.buf.implementation,
			['go'] = vim.lsp.buf.type_definition,
			['gr'] = vim.lsp.buf.references,
			['<leader>rn'] = vim.lsp.buf.rename,
			['<leader>,'] = vim.lsp.buf.code_action,
			['<leader>t'] = ':Trouble<CR>',
			['<leader>-'] = function() vim.diagnostic.goto_prev({ float = true }) end,
			['<leader>='] = function() vim.diagnostic.goto_next({ float = true }) end,
		},
		['i'] = {
			['<c-f>'] = vim.lsp.buf.signature_help,
		},
	}

	-- 应用快捷键
	for mode, mappings in pairs(keymaps) do
		for keys, cmd in pairs(mappings) do
			vim.keymap.set(mode, keys, cmd, { buffer = bufnr, noremap = true, nowait = true })
		end
	end
end

-- 自动格式化保存函数优化
local function format_on_save()
	local format_on_save_filetypes = {
		python = true,
		rust = true,
		-- json = true,
		lua = true
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
				pythonPath = "/opt/homebrew/Caskroom/miniforge/base/bin/python",
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
