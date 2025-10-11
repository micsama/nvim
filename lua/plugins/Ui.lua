-- ============================================================================
-- 模块引入与实用工具
-- ============================================================================
local map = require('util.utils').map
local telescope_builtin = require('telescope.builtin')

-- Floatty 配置基础（使用当前工作目录作为 ID）
local floatty_opts = { id = vim.fn.getcwd }

-- ============================================================================
-- 核心工具 (Floatty / Lazygit / Which-Key)
-- ============================================================================

-- 1. 普通浮动终端 (term)
local term = require("floatty").setup(floatty_opts)
map('ntv', '<D-g>', term.toggle, "切换终端")

-- 2. Lazygit 浮动窗口
local lazygit = require("floatty").setup(vim.tbl_deep_extend("force", floatty_opts, {
	cmd = "lazygit", window = { width = 0.95, height = 0.95, } }))
map('n', '<leader>gg', lazygit.toggle, "打开lazygit")

-- 3. Which-Key 基础配置
require('which-key').setup()

-- ============================================================================
-- 界面和状态栏 (Bufferline / Lualine)
-- ============================================================================

-- 1. Bufferline (顶部标签页)
require('bufferline').setup({
	options = {
		mode = 'tabs',
		-- 格式为 '2. ¹3'
		numbers = function(opts)
			return string.format('%s%s', opts.ordinal, opts.raise(opts.id))
		end,
		diagnostics = 'nvim_lsp',
		diagnostics_indicator = function(count, level, diagnostics_dict, context)
			local icon = level:match('error') and ' ' or ' '
			return ' ' .. icon .. count
		end,
		indicator = {
			icon = '▎ ',
			style = 'icon',
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

-- 2. Lualine (底部状态栏)
require('lualine').setup {
	sections = {
		lualine_a = { 'filename' },
		lualine_b = { 'branch', 'diff', 'diagnostics' },
		lualine_x = { 'progress' },
		lualine_y = { 'filesize', 'filetype' },
		lualine_z = { 'location' }
	},
	tabline = {},
	winbar = {},
	inactive_winbar = {},
	extensions = {}
}

-- ============================================================================
-- 模糊查找 (Telescope) 及快捷键
-- ============================================================================

require('telescope').setup({
	extensions = {}
})

-- -- TODO: 如果需要，取消注释启用 fzf 扩展
-- -- require('telescope').load_extension('fzf')

-- Telescope 快捷键映射
map('nv', '<leader>ff', telescope_builtin.find_files, 'Find Files')
map('nv', '<leader>fg', telescope_builtin.live_grep, 'Live Grep')
map('nv', '<leader>fb', telescope_builtin.buffers, 'Find Buffers')
map('nv', '<leader>fh', telescope_builtin.help_tags, 'Find Help Tags')
