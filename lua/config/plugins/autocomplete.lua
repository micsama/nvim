local has_words_before = function()
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	return col ~= 0 and not vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s")
end

local limitStr = function(str)
	return #str > 25 and string.sub(str, 1, 22) .. "..." or str
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

local setCompHL = function()
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

local M = {}
M.config = {
	"hrsh7th/nvim-cmp",
	after = "SirVer/ultisnips",
	dependencies = {
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-nvim-lua",
		"hrsh7th/cmp-calc",
		{
			"onsails/lspkind.nvim",
			lazy = false,
			config = function() require("lspkind").init() end
		},
	},
}

M.configfunc = function()
	local cmp = require("cmp")
	local lspkind = require("lspkind")
	local cmp_ultisnips_mappings = require("cmp_nvim_ultisnips.mappings")

	setCompHL()
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
end

return M

