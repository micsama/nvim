return {
	'akinsho/bufferline.nvim',
	dependencies = 'nvim-tree/nvim-web-devicons',
	opts = {
		options = {
			mode = "tabs",
			numbers = function(opts)
				return string.format('%s%s', opts.ordinal, opts.raise(opts.id)) -- 格式为 "2. ¹3"
			end,
			diagnostics = "nvim_lsp",
			diagnostics_indicator = function(count, level, diagnostics_dict, context)
				local icon = level:match("error") and " " or " "
				return " " .. icon .. count
			end,
			indicator = {
				-- icon = '▎', -- this should be omitted if indicator style is not 'icon'
				icon = '', -- this should be omitted if indicator style is not 'icon'
				-- style = 'icon' | 'underline' | 'none',
				style = "icon",
			},
			show_buffer_close_icons = false,
			color_icons = true,
			show_close_icon = false,
			enforce_regular_tabs = true,
			show_duplicate_prefix = false,
			tab_size = 16,
			padding = 0,
			separator_style = "thick",
			left_trunc_marker = ' ',
			right_trunc_marker = ' ',
		}
	},
}
