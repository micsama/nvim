local M = {}

M.config = {
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
			{ 'j-hui/fidget.nvim',                tag = "legacy" },
		},
		config = function()
			local lsp = require('lsp-zero')
			lsp.preset('recommended')

			-- Mason setup
			require('mason').setup({})
			require('mason-lspconfig').setup({
				ensure_installed = { 'rust_analyzer', 'pyright' },
			})

			-- Rust Analyzer setup
			local lspconfig = require('lspconfig')
			lspconfig.rust_analyzer.setup({
				settings = {
					["rust-analyzer"] = {
						cargo = {
							allFeatures = true,
						},
						checkOnSave = {
							command = "clippy",
						},
					},
				},
			})

			-- Pyright setup for Python
			lspconfig.pyright.setup({
				settings = {
					python = {
						pythonPath = "/opt/homebrew/Caskroom/miniforge/base/bin/python",
						analysis = {
							autoImportCompletions = false,
							autoSearchPaths = true,
							diagnosticMode = "openFilesOnly",
							useLibraryCodeForTypes = true,
						},
					},
				},
			})

			-- Common LSP settings
			lsp.on_attach(function(client, bufnr)
				lsp.default_keymaps({ buffer = bufnr })
				require("lsp_signature").on_attach({}, bufnr)

				vim.diagnostic.config({
					severity_sort = true,
					underline = true,
					signs = true,
					virtual_text = false,
					update_in_insert = false,
					float = true,
				})

				lsp.set_sign_icons({
					error = '✘',
					warn = '▲',
					hint = '⚑',
					info = '»',
				})
			end)

			lsp.setup()

			-- Keybinds configuration
			vim.api.nvim_create_autocmd('LspAttach', {
				desc = 'LSP actions',
				callback = function(event)
					local opts = { buffer = event.buf, noremap = true, nowait = true }

					-- Key mappings for LSP actions
					vim.keymap.set('n', '<leader>h', vim.lsp.buf.hover, opts)
					vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
					vim.keymap.set('n', 'gD', ':tab sp<CR><cmd>lua vim.lsp.buf.definition()<cr>', opts)
					vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
					vim.keymap.set('n', 'go', vim.lsp.buf.type_definition, opts)
					vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
					vim.keymap.set('i', '<c-f>', vim.lsp.buf.signature_help, opts)
					vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
					vim.keymap.set('n', '<leader>aw', vim.lsp.buf.code_action, opts)
					vim.keymap.set('n', "<leader>,", vim.lsp.buf.code_action, opts)
					vim.keymap.set('n', '<leader>t', ':Trouble<cr>', opts)
					vim.keymap.set('n', '<leader>-', vim.diagnostic.goto_prev, opts)
					vim.keymap.set('n', '<leader>=', vim.diagnostic.goto_next, opts)
				end
			})
		end,
	},
}

return M
