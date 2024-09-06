local M = {}

M.config = {
	{
		'VonHeikemen/lsp-zero.nvim', -- lsp-zero插件，用于简化Neovim中的LSP配置
		branch = 'v4.x',
		dependencies = {
			{
				"folke/trouble.nvim", -- Trouble插件，用于增强显示LSP诊断信息
				config = function()
					require("trouble").setup({
						use_diagnostic_signs = true, -- 使用LSP的诊断符号
					})
				end,
			},
			{ 'neovim/nvim-lspconfig' }, -- LSP配置插件，用于配置各类语言服务器
			{
				'williamboman/mason.nvim', -- Mason插件，用于管理LSP、DAP等开发工具的安装
				build = function()
					vim.cmd([[MasonInstall]])
				end,
			},
			{ 'williamboman/mason-lspconfig.nvim' },               -- mason-lspconfig插件，用于自动配置mason安装的LSP
			{ 'ray-x/lsp_signature.nvim' },                        -- lsp_signature插件，用于在输入时显示函数签名
			{ 'folke/neodev.nvim' },                               -- neodev插件，为Neovim API提供增强的LSP支持
			{ 'j-hui/fidget.nvim',                  tag = "legacy" }, -- fidget插件，用于显示LSP的加载状态
			{ 'airblade/vim-rooter' },                             -- vim-rooter插件，用于自动将工作目录设置为项目根目录
			{ 'hrsh7th/nvim-cmp' },                                -- nvim-cmp插件，用于自动补全
			{ 'hrsh7th/cmp-buffer' },                              -- cmp-buffer插件，用于补全当前缓冲区中的内容
			{ 'hrsh7th/cmp-path' },                                -- cmp-path插件，用于补全文件路径
			{ 'hrsh7th/cmp-nvim-lsp' },                            -- cmp-nvim-lsp插件，用于补全LSP提供的内容
			{ "quangnguyen30192/cmp-nvim-ultisnips" },             -- cmp-nvim-ultisnips插件，用于将UltiSnips与nvim-cmp集成

			{ 'hrsh7th/cmp-nvim-lua' },                            -- cmp-nvim-lua插件，用于补全Neovim Lua API
			{ 'hrsh7th/cmp-calc' },                                -- cmp-calc插件，用于计算表达式并补全结果
			{
				'onsails/lspkind.nvim',                              -- lspkind插件，为补全项添加图标
				lazy = false,
				config = function() require("lspkind").init() end
			},
		},
		config = function()
			local lsp = require('lsp-zero')

			-- Setup Mason and ensure specific LSP servers are installed
			require('mason').setup({})
			require('mason-lspconfig').setup({
				ensure_installed = { 'rust_analyzer', 'pyright', 'jsonls', 'lua_ls', 'ruff' },
			})

			-- LSP server configurations
			local lspconfig = require('lspconfig')

			lspconfig.rust_analyzer.setup({
				settings = {
					["rust-analyzer"] = {
						cargo = { allFeatures = true },
						checkOnSave = { command = "clippy" },
					},
				},
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
			})

			lspconfig.jsonls.setup({})
			lspconfig.lua_ls.setup({
				settings = {
					Lua = {
						diagnostics = { globals = { 'vim' } },
						workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
					},
				},
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

			-- Auto format on save
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

			-- Keybinds configuration
			vim.api.nvim_create_autocmd('LspAttach', {
				desc = 'LSP actions',
				callback = function(event)
					local opts = { buffer = event.buf, noremap = true, nowait = true }

					-- Consolidated key mappings for LSP actions
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
			local cmp_ultisnips_mappings = require("cmp_nvim_ultisnips.mappings") -- 确保这个模块可以正确引用

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
			-- Function to check if there are words before the cursor position
			local has_words_before = function()
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0 and not vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s")
			end


			-- Define the entry_comparator function for sorting entries, especially handling Python-specific cases
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

			-- Define the limitStr function to shorten strings if needed
			local limitStr = function(str)
				return #str > 25 and string.sub(str, 1, 22) .. "..." or str
			end
			-- Configure cmp settings
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
					priority_weight = 1, -- 添加 priority_weight 字段，数值可以根据需求调整
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
					expandable_indicator = true, -- 添加 expandable_indicator 字段，表示补全项是否可展开
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
