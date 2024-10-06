local kind_icons = {
	["Class"] = "🅒 ",
	["Interface"] = "🅘 ",
	["TypeParameter"] = "🅣 ",
	["Struct"] = "🅢 ",
	["Enum"] = "🅔 ",
	["Unit"] = "🅤 ",
	["EnumMember"] = "🅔 ",
	["Constant"] = "🅒 ",
	["Field"] = "🅕 ",
	["Property"] = "🅟 ",
	["Variable"] = "🅥 ",
	["Reference"] = "🅡 ",
	["Function"] = "🅕 ",
	["Method"] = "🅜 ",
	["Constructor"] = "🅒 ",
	["Module"] = "🅜 ",
	["File"] = "🅕 ",
	["Folder"] = "🅕 ",
	["Keyword"] = "🅚 ",
	["Operator"] = "🅞 ",
	["Snippet"] = "🅢 ",
	["Value"] = "🅥 ",
	["Color"] = "🅒 ",
	["Event"] = "🅔 ",
	["Text"] = "🅣 ",

	-- crates.nvim extensions
	["Version"] = "🅥 ",
	["Feature"] = "🅕 ",
}
return {
	{
		'saecki/crates.nvim',
		event = { "BufRead Cargo.toml" },
		opts = {
			formatting = {
				fields = { "abbr", "kind" },
				format = function(_, vim_item)
					vim_item.kind = kind_icons[vim_item.kind] or "  "
					return vim_item
				end,
			},
			completion = {
				crates = {
					enabled = true,
					max_results = 8,
					min_chars = 3,
				},
				cmp = {
					use_custom_kind = true,
					-- optionally change the text and highlight groups
					kind_text = {
						version = "Version",
						feature = "Feature",
					},
					kind_highlight = {
						version = "CmpItemKindVersion",
						feature = "CmpItemKindFeature",
					},
				},
			},
			lsp = {
				enabled = true,
				on_attach = function(client, bufnr)
					-- the same on_attach function as for your other lsp's
				end,
				actions = true,
				completion = true,
				hover = true,
			},
		},
	},
	{
		'vxpm/ferris.nvim',
		opts = {
			-- your options here
		}
	}
}
