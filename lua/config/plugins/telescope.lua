return {
	{
		'nvim-telescope/telescope.nvim',
		branch = '0.1.x',
		dependencies = {
			'nvim-lua/plenary.nvim',
			{ 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
		},
		config = function()
			-- 加载 Telescope 和相关扩展
			local telescope = require('telescope')

			-- 配置 Telescope 的核心功能和扩展
			telescope.setup {
				defaults = {
					-- 可以在这里添加默认配置
				},
				extensions = {
					fzf = {
						fuzzy = true,                               -- false will only do exact matching
						override_generic_sorter = true,             -- override the generic sorter
						override_file_sorter = true,                -- override the file sorter
						case_mode = "smart_case",                   -- or "ignore_case" or "respect_case"
					}
				}
			}

			-- 加载 fzf 扩展
			telescope.load_extension('fzf')
		end,
		keys = {
			-- 使用 keys 部分来定义快捷键映射
			{ '<leader>ff', function() require('telescope.builtin').find_files() end, desc = 'Find Files' },
			{ '<leader>fg', function() require('telescope.builtin').live_grep() end,  desc = 'Live Grep' },
			{ '<leader>fb', function() require('telescope.builtin').buffers() end,    desc = 'Find Buffers' },
			{ '<leader>fh', function() require('telescope.builtin').help_tags() end,  desc = 'Find Help Tags' },
		},
	}
}
