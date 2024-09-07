-- cmp_config.lua
local M = {}

-- 设置高亮样式
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

	-- 应用高亮菜单的颜色
	for _, hl in ipairs(highlight_groups) do
		vim.api.nvim_set_hl(0, hl[1], { fg = hl[2], bg = hl[3], bold = hl[4], strikethrough = hl[5], italic = hl[6] })
	end
end

-- 检查当前光标前是否有文字
local function has_words_before()
	local line, col = table.unpack(vim.api.nvim_win_get_cursor(0))
	return col ~= 0 and not vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s")
end

-- 比较器：用于排序补全项，处理Python文件中以_开头的项优先级
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

-- 截取长字符串以适应界面显示
local function limit_string(str)
	return #str > 30 and string.sub(str, 1, 22) .. "..." or str
end

-- 设置补全的主要功能
local function setup_cmp(cmp, cmp_ultisnips_mappings, lspkind)
	local mode_is = {}
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
				kind.menu = limit_string(entry:get_completion_item().detail or "")
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
			["<c-e>"] = cmp.mapping(
				function() cmp_ultisnips_mappings.compose { "expand", "jump_forwards" } (function() end) end,
				mode_is
			),
			["<c-n>"] = cmp.mapping(
				function(fallback) cmp_ultisnips_mappings.jump_backwards(fallback) end,
				mode_is
			),
			['<C-f>'] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.close() -- 当补全菜单可见时，关闭菜单
				else
					cmp.complete() -- 当补全菜单不可见时，显示补全菜单
				end
			end, mode_is), -- 可用于插入模式和选择模式

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

-- 主配置函数
M.config = {
	{
		'hrsh7th/nvim-cmp',
		dependencies = {
			{ 'hrsh7th/cmp-buffer' },
			{ 'hrsh7th/cmp-path' },
			{ 'hrsh7th/cmp-nvim-lsp' },
			{ "quangnguyen30192/cmp-nvim-ultisnips" },
			{ 'hrsh7th/cmp-nvim-lua' },
			{ 'hrsh7th/cmp-calc' },
			{ 'onsails/lspkind.nvim' },
		},
		config = function()
			local cmp = require("cmp")
			local lspkind = require("lspkind")
			local cmp_ultisnips_mappings = require("cmp_nvim_ultisnips.mappings")

			set_highlights()
			setup_cmp(cmp, cmp_ultisnips_mappings, lspkind)
		end,
	},
}

return M
