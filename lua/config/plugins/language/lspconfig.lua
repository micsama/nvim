-- lsp_config.lua
local M = {}

M.config = {
	{
		'VonHeikemen/lsp-zero.nvim',
		branch = 'v4.x',
		dependencies = {
			{ "folke/trouble.nvim", },
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
			{ 'airblade/vim-rooter' },
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
				ensure_installed = { 'rust_analyzer', 'pyright', 'jsonls', 'lua_ls', 'ruff' },
			})

			-- Common on_attach configuration
			local on_attach = function(client, bufnr)
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

				local keymaps = {
					['n'] = {
						['<leader>h'] = vim.lsp.buf.hover,
						['gd'] = vim.lsp.buf.definition,
						['gD'] = '<cmd>tab split | lua vim.lsp.buf.definition()<CR>',
						['gi'] = vim.lsp.buf.implementation,
						['go'] = vim.lsp.buf.type_definition,
						['gr'] = vim.lsp.buf.references,
						['<leader>rn'] = vim.lsp.buf.rename,
						['<leader>aw'] = vim.lsp.buf.code_action,
						['<leader>,'] = vim.lsp.buf.code_action,
						['<leader>t'] = ':Trouble<CR>',
						['<leader>-'] = function() vim.diagnostic.goto_prev({ float = true }) end,
						['<leader>='] = function() vim.diagnostic.goto_next({ float = true }) end,
					},
					['i'] = {
						['<c-f>'] = vim.lsp.buf.signature_help,
					},
				}

				for mode, mappings in pairs(keymaps) do
					for keys, cmd in pairs(mappings) do
						vim.keymap.set(mode, keys, cmd, { buffer = bufnr, noremap = true, nowait = true })
					end
				end
			end

			-- Setup LSP configurations
			local lspconfig = require('lspconfig')

			lspconfig.rust_analyzer.setup({
				settings = {
					["rust-analyzer"] = {
						cargo = { allFeatures = true },
						checkOnSave = { command = "clippy" },
					},
				},
				on_attach = on_attach,
			})

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
				on_attach = on_attach,
			})

			lspconfig.jsonls.setup({ on_attach = on_attach })

			lspconfig.lua_ls.setup({
				settings = {
					Lua = {
						diagnostics = { globals = { 'vim' } },
						workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
					},
				},
				on_attach = on_attach,
			})

			lspconfig.ruff.setup({
				init_options = {
					settings = {
						configuration = "~/.config/nvim/ruff.toml",
						configurationPreference = "filesystemFirst",
						lineLength = 100,
						fixAll = true,
						organizeImports = true,
						showSyntaxErrors = true,
					},
				},
				on_attach = on_attach,
			})

			lsp.setup()

			-- Auto format on save
			local format_on_save = function()
				local format_on_save_filetypes = {
					python = true,
					rust = true,
					json = true,
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

			format_on_save()

			-- Keybinds configuration for LSP Attach
			vim.api.nvim_create_autocmd('LspAttach', {
				desc = 'LSP actions',
				callback = function(event)
					local opts = { buffer = event.buf, noremap = true, nowait = true }

					local keymaps = {
						['n'] = {
							['<leader>h'] = vim.lsp.buf.hover,
							['gd'] = vim.lsp.buf.definition,
							['gD'] = '<cmd>tab split | lua vim.lsp.buf.definition()<CR>',
							['gi'] = vim.lsp.buf.implementation,
							['go'] = vim.lsp.buf.type_definition,
							['gr'] = vim.lsp.buf.references,
							['<leader>rn'] = vim.lsp.buf.rename,
							['<leader>aw'] = vim.lsp.buf.code_action,
							['<leader>,'] = vim.lsp.buf.code_action,
							['<leader>t'] = ':Trouble<CR>',
							['<leader>-'] = function() vim.diagnostic.goto_prev({ float = true }) end,
							['<leader>='] = function() vim.diagnostic.goto_next({ float = true }) end,
						},
						['i'] = {
							['<c-f>'] = vim.lsp.buf.signature_help,
						},
					}

					for mode, mappings in pairs(keymaps) do
						for keys, cmd in pairs(mappings) do
							vim.keymap.set(mode, keys, cmd, opts)
						end
					end
				end
			})
		end,
	},
}

return M
