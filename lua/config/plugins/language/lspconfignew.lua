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
				'j-hui/fidget.nvim', -- Fidget插件，用于在右下角显示LSP加载状态
				tag = "legacy",
				config = function()
					require("fidget").setup({
						text = {
							spinner = "dots", -- 显示加载动画的样式，可以根据喜好调整
						},
						window = {
							blend = 0, -- 窗口透明度，0表示不透明
						},
					})
				end,
			},
			{ 'hrsh7th/nvim-cmp' },
			{ 'hrsh7th/cmp-buffer' },
			{ 'hrsh7th/cmp-path' },
			{ 'hrsh7th/cmp-nvim-lsp' },
			{ "quangnguyen30192/cmp-nvim-ultisnips" },
			{ 'hrsh7th/cmp-nvim-lua' },
			{ 'hrsh7th/cmp-calc' },
			{ 'onsails/lspkind.nvim',
			},
		},
		config = function()
			local lsp = require('lsp-zero')

			require('mason').setup({})
			require('mason-lspconfig').setup({
				ensure_installed = { 'rust_analyzer', 'pyright', 'jsonls', 'lua_ls', 'ruff' },
			})

			-- 提取通用的 on_attach 配置
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

			-- 使用提取的 on_attach 配置
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

			lspconfig.jsonls.setup({
				on_attach = on_attach,
			})

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


			-- 提取自动格式化相关设置
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

			-- 在配置中调用优化后的自动格式化函数
			format_on_save()
			-- Keybinds configuration for LSP Attach
			vim.api.nvim_create_autocmd('LspAttach', {
				desc = 'LSP actions',
				callback = function(event)
					local opts = { buffer = event.buf, noremap = true, nowait = true }

					-- Key mappings
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

			-- Configure cmp (completion) settings
			local cmp = require("cmp")
			local lspkind = require("lspkind")
			local cmp_ultisnips_mappings = require("cmp_nvim_ultisnips.mappings")

			-- Set highlights for cmp items
			local function setCompHL()
				local hl_settings = {
					{ "CmpItemAbbrMatch",         "#82AAFF", "NONE",   true },
					{ "CmpItemAbbrMatchFuzzy",    "#82AAFF", "NONE",   true },
					{ "CmpItemAbbrDeprecated",    "#7E8294", "NONE",   nil, true },
					{ "CmpItemMenu",              "#808080", "NONE",   nil, nil, true },
					{ "CmpItemKindField",         "#2E3440", "#B5585F" },
					{ "CmpItemKindProperty",      "#2E3440", "#B5585F" },
					{ "CmpItemKindEvent",         "#2E3440", "#B5585F" },
					{ "CmpItemKindText",          "#2E3440", "#9FBD73" },
					{ "CmpItemKindEnum",          "#2E3440", "#9FBD73" },
					{ "CmpItemKindKeyword",       "#2E3440", "#9FBD73" },
					{ "CmpItemKindConstant",      "#2E3440", "#D4BB6C" },
					{ "CmpItemKindConstructor",   "#2E3440", "#D4BB6C" },
					{ "CmpItemKindReference",     "#2E3440", "#D4BB6C" },
					{ "CmpItemKindFunction",      "#2E3440", "#A377BF" },
					{ "CmpItemKindStruct",        "#2E3440", "#A377BF" },
					{ "CmpItemKindClass",         "#2E3440", "#A377BF" },
					{ "CmpItemKindModule",        "#2E3440", "#A377BF" },
					{ "CmpItemKindOperator",      "#2E3440", "#A377BF" },
					{ "CmpItemKindVariable",      "#2E3440", "#cccccc" },
					{ "CmpItemKindFile",          "#2E3440", "#7E8294" },
					{ "CmpItemKindUnit",          "#2E3440", "#D4A959" },
					{ "CmpItemKindSnippet",       "#2E3440", "#D4A959" },
					{ "CmpItemKindFolder",        "#2E3440", "#D4A959" },
					{ "CmpItemKindMethod",        "#2E3440", "#6C8ED4" },
					{ "CmpItemKindValue",         "#2E3440", "#6C8ED4" },
					{ "CmpItemKindEnumMember",    "#2E3440", "#6C8ED4" },
					{ "CmpItemKindInterface",     "#2E3440", "#58B5A8" },
					{ "CmpItemKindColor",         "#2E3440", "#58B5A8" },
					{ "CmpItemKindTypeParameter", "#2E3440", "#58B5A8" },
				}

				for _, hl in ipairs(hl_settings) do
					vim.api.nvim_set_hl(0, hl[1], { fg = hl[2], bg = hl[3], bold = hl[4], strikethrough = hl[5], italic = hl[6] })
				end
			end

			setCompHL()

			local has_words_before = function()
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0 and not vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s")
			end

			local entry_comparator = function(entry1, entry2)
				if vim.bo.filetype == "python" then
					local entry1StartsWithUnderscore = string.sub(entry1.completion_item.label, 1, 1) == "_" and
							entry1.source.name == 'nvim_lsp'
					local entry2StartsWithUnderscore = string.sub(entry2.completion_item.label, 1, 1) == "_" and
							entry2.source.name == 'nvim_lsp'
					if entry1StartsWithUnderscore ~= entry2StartsWithUnderscore then
						return not entry1StartsWithUnderscore
					end
				end
				return entry1.completion_item.label < entry2.completion_item.label
			end

			local limitStr = function(str)
				return #str > 25 and string.sub(str, 1, 22) .. "..." or str
			end

			cmp.setup({
				preselect = cmp.PreselectMode.None,
				snippet = {
					expand = function(args) vim.fn["UltiSnips#Anon"](args.body) end,
				},
				window = {
					completion = { col_offset = -3, side_padding = 0 },
					documentation = cmp.config.window.bordered(),
				},
				sorting = {
					priority_weight = 1,
					comparators = {
						entry_comparator,
						cmp.config.compare.offset,
						cmp.config.compare.exact,
						cmp.config.compare.score,
						cmp.config.compare.recently_used,
						cmp.config.compare.kind,
					},
				},
				formatting = {
					fields = { "kind", "abbr", "menu" },
					maxwidth = 60,
					maxheight = 10,
					expandable_indicator = true,
					format = function(entry, vim_item)
						local kind = lspkind.cmp_format({ mode = "symbol_text", symbol_map = { Codeium = "" } })(entry, vim_item)
						kind.kind = " " .. (vim.split(kind.kind, "%s", { trimempty = true })[1] or "") .. " "
						kind.menu = limitStr(entry:get_completion_item().detail or "")
						return kind
					end,
				},
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "buffer" },
				}, {
					{ name = "path" },
					{ name = "nvim_lua" },
					{ name = "calc" },
				}),
				mapping = cmp.mapping.preset.insert({
					['<C-o>'] = cmp.mapping.complete(),
					["<c-e>"] = cmp.mapping(
						function() cmp_ultisnips_mappings.compose { "expand", "jump_forwards" } (function() end) end,
						{ "i", "s" }
					),
					["<c-n>"] = cmp.mapping(
						function(fallback) cmp_ultisnips_mappings.jump_backwards(fallback) end,
						{ "i", "s" }
					),
					['<c-f>'] = cmp.mapping({
						i = function(fallback)
							cmp.close()
							fallback()
						end
					}),
					['<c-y>'] = cmp.mapping({ i = function(fallback) fallback() end }),
					['<c-u>'] = cmp.mapping({ i = function(fallback) fallback() end }),
					['<CR>'] = cmp.mapping({
						i = function(fallback)
							if cmp.visible() and cmp.get_active_entry() then
								cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
							else
								fallback()
							end
						end
					}),
					["<Tab>"] = cmp.mapping({
						i = function(fallback)
							if cmp.visible() then
								cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
							elseif has_words_before() then
								cmp.complete()
							else
								fallback()
							end
						end,
					}),
					["<S-Tab>"] = cmp.mapping({
						i = function(fallback)
							if cmp.visible() then
								cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
							else
								fallback()
							end
						end,
					}),
				}),
			})
		end,
	},
}

return M
