-- cmp_config.lua

--
local function set_highlights()
	local xj_font_color = "#1D4E45"
	local highlight_groups = {
		{ "CmpItemAbbrMatch",         "#82AAFF",     "NONE",   true },
		{ "CmpItemAbbrMatchFuzzy",    "#82AAFF",     "NONE",   true },
		{ "CmpItemAbbrDeprecated",    "#7E8294",     "NONE",   nil, true },
		{ "CmpItemMenu",              "#808080",     "NONE",   nil, nil, true },
		{ "CmpItemKindField",         xj_font_color, "#B5585F" },
		{ "CmpItemKindProperty",      xj_font_color, "#B5585F" },
		{ "CmpItemKindEvent",         xj_font_color, "#B5585F" },
		{ "CmpItemKindText",          xj_font_color, "#9FBD73" },
		{ "CmpItemKindEnum",          xj_font_color, "#9FBD73" },
		{ "CmpItemKindKeyword",       xj_font_color, "#9FBD73" },
		{ "CmpItemKindConstant",      xj_font_color, "#D4BB6C" },
		{ "CmpItemKindConstructor",   xj_font_color, "#D4BB6C" },
		{ "CmpItemKindReference",     xj_font_color, "#D4BB6C" },
		{ "CmpItemKindFunction",      xj_font_color, "#A377BF" },
		{ "CmpItemKindStruct",        xj_font_color, "#A377BF" },
		{ "CmpItemKindClass",         xj_font_color, "#A377BF" },
		{ "CmpItemKindModule",        xj_font_color, "#A377BF" },
		{ "CmpItemKindOperator",      xj_font_color, "#A377BF" },
		{ "CmpItemKindVariable",      xj_font_color, "#cccccc" },
		{ "CmpItemKindFile",          xj_font_color, "#7E8294" },
		{ "CmpItemKindUnit",          xj_font_color, "#D4A959" },
		{ "CmpItemKindSnippet",       xj_font_color, "#D4A959" },
		{ "CmpItemKindFolder",        xj_font_color, "#D4A959" },
		{ "CmpItemKindMethod",        xj_font_color, "#6C8ED4" },
		{ "CmpItemKindValue",         xj_font_color, "#6C8ED4" },
		{ "CmpItemKindEnumMember",    xj_font_color, "#6C8ED4" },
		{ "CmpItemKindInterface",     xj_font_color, "#58B5A8" },
		{ "CmpItemKindColor",         xj_font_color, "#58B5A8" },
		{ "CmpItemKindTypeParameter", xj_font_color, "#58B5A8" },
	}

	--
	for _, hl in ipairs(highlight_groups) do
		vim.api.nvim_set_hl(0, hl[1], { fg = hl[2], bg = hl[3], bold = hl[4], strikethrough = hl[5], italic = hl[6] })
	end
end

--
local function has_words_before()
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	return col ~= 0 and not vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s")
end

-- Python_
local function entry_comparator(entry1, entry2)
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

--
local function limit_string(str)
	return #str > 30 and string.sub(str, 1, 22) .. "..." or str
end

--
local function setup_cmp(cmp, lspkind)
	-- snippet
	require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/snippets" })
	cmp.setup({
		preselect = cmp.PreselectMode.None,
		snippet = {
			expand = function(args)
				require("luasnip").lsp_expand(args.body)
			end
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
				local kind = lspkind.cmp_format({ mode = "symbol_text", symbol_map = { Codeium = "" } })(entry, vim_item)
				kind.kind = " " .. (vim.split(kind.kind, "%s", { trimempty = true })[1] or "") .. " "
				kind.menu = limit_string(entry:get_completion_item().detail or "")
				return kind
			end,
		},
		sources = cmp.config.sources({
			{ name = 'nvim_lsp', priority = 1000 },                                     --  LSP
			{ name = 'luasnip',  priority = 2000, option = { show_autosnippets = true } }, --
			{ name = 'buffer',   priority = 400 },                                      --
		}, {
			{ name = 'path',     priority = 250 },                                      --
			{ name = 'nvim_lua', priority = 700 },                                      -- Neovim Lua API
			{ name = 'calc',     priority = 200 },                                      --
		}),
		mapping = cmp.mapping.preset.insert({
			['<c-g>'] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.close() --
				else
					cmp.complete() --
				end
			end),         --

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
end

--
return {
	--  cmp
	{
		'hrsh7th/nvim-cmp',
		event = { 'InsertEnter' }, --
		config = function()
			local cmp = require("cmp")
			local lspkind = require("lspkind")
			set_highlights()     --
			setup_cmp(cmp, lspkind) --
		end,
		dependencies = {
			{ 'onsails/lspkind.nvim' },                                                        --
			{ "L3MON4D3/LuaSnip",            version = "v2.x", build = "make install_jsregexp" }, --
			{ "rafamadriz/friendly-snippets" },                                                --
			{ 'saadparwaiz1/cmp_luasnip' }                                                     -- LuaSnip
		},
	},

	--
	{
		'hrsh7th/cmp-buffer',    --
		event = { 'InsertEnter' }, --
	},
	{
		'hrsh7th/cmp-path',      --
		event = { 'InsertEnter' }, --
	},
	{
		'hrsh7th/cmp-nvim-lsp',  -- LSP
		event = { 'InsertEnter' }, --
	},
	{
		'hrsh7th/cmp-nvim-lua',  -- Neovim Lua API
		event = { 'InsertEnter' }, --
	},
	{
		'hrsh7th/cmp-calc',      --
		event = { 'InsertEnter' }, --
	},

	-- cmdline
	{
		'hrsh7th/cmp-cmdline',    --
		event = { 'CmdlineEnter' }, --
		config = function()
			local cmp = require("cmp")
			cmp.setup.cmdline(':', {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = 'path' }
				}, {
					{ name = 'cmdline', option = { ignore_cmds = { 'Man', '!' } } }
				})
			})
		end,
	},
}
