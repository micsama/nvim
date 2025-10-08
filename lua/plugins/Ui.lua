local map = require('util.utils').map

local term = require("floatty").setup({
	id = vim.fn.getcwd,   -- Use the current working directory as the float's ID
})
map('ntv', '<D-g>', function() term.toggle() end, "切换终端")

local lazygit = require("floatty").setup({
	window ={
		width = 0.95,
		height = 0.95,
	},
	cmd = "lazygit",
	id = vim.fn.getcwd,   -- Use the current working directory as the float's ID
})
map('nt', '<leader>gg', function() lazygit.toggle() end, "打开lazygit")

require('bufferline').setup({
	options = {
		mode = 'tabs',
		numbers = function(opts)
			return string.format('%s%s', opts.ordinal, opts.raise(opts.id)) -- 格式为 '2. ¹3'
		end,
		diagnostics = 'nvim_lsp',
		diagnostics_indicator = function(count, level, diagnostics_dict, context)
			local icon = level:match('error') and ' ' or ' '
			return ' ' .. icon .. count
		end,
		indicator = {
			icon = '▎ ', -- this should be omitted if indicator style is not 'icon'
			style = 'icon', -- style = 'icon' | 'underline' | 'none',
		},
		show_buffer_close_icons = true,
		color_icons = true,
		show_close_icon = true,
		enforce_regular_tabs = true,
		show_duplicate_prefix = false,
		tab_size = 16,
		padding = 0,
		separator_style = 'thick',
		left_trunc_marker = ' ',
		right_trunc_marker = ' ',
	}
})
require('lualine').setup {
	options = {
		ignore_focus = { 'neo-tree' },
		globalstatus = true,
	},
	sections = {
		lualine_a = { 'filename' },
		lualine_b = { 'branch', 'diff', 'diagnostics' },
		lualine_x = {},
		lualine_y = { 'filesize', 'filetype' },
		lualine_z = { 'location' }
	},
	tabline = {},
	winbar = {},
	inactive_winbar = {},
	extensions = {}
}

require('scrollview').setup({
	mode = 'virtual',
	excluded_filetypes = { 'nerdtree' },
	current_only = true,
	base = 'right',
	column = 1,
	signs_on_startup = { 'all' },
	diagnostics_severities = { vim.diagnostic.severity.ERROR }
})

require('which-key').setup()

local telescope = require('telescope')
telescope.setup({
	extensions = {}
})

-- TODO:
-- telescope.load_extension('workspaces')
-- telescope.load_extension('fzf')
-- require('telescope').load_extension('lazygit')

-- TODO:放到keymaps里
map('nv', '<leader>ff', function() require('telescope.builtin').find_files() end, 'Find Files')
map('nv', '<leader>fg', function() require('telescope.builtin').live_grep() end, 'Live Grep')
map('nv', '<leader>fb', function() require('telescope.builtin').buffers() end, 'Find Buffers')
map('nv', '<leader>fh', function() require('telescope.builtin').help_tags() end, 'Find Help Tags')

require('dashboard').setup {
	theme = 'hyper',
	config = {
		shortcut = {
			-- action can be a function type
		},
		packages = { enable = true }, -- show how many plugins neovim loaded
		project = { enable = true, limit = 8, icon = '󱠿', label = '\t近期 ^_^ 目录', action = 'Telescope find_files cwd=' },
		mru = { limit = 10, icon = '', label = '\t近期 $_$ 文件', cwd_only = false },
		footer = {}, -- footer
	}
}
