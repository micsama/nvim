local now, add, later = MiniDeps.now, MiniDeps.add, MiniDeps.later
local map = require("util.utils").map

now(function()
	add("akinsho/bufferline.nvim")
	require("bufferline").setup({
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
				icon = '▎ ',    -- this should be omitted if indicator style is not 'icon'
				style = "icon", -- style = 'icon' | 'underline' | 'none',
			},
			show_buffer_close_icons = true,
			color_icons = true,
			show_close_icon = true,
			enforce_regular_tabs = true,
			show_duplicate_prefix = false,
			tab_size = 16,
			padding = 0,
			separator_style = "thick",
			left_trunc_marker = ' ',
			right_trunc_marker = ' ',
		}
	})
end)


now(function()
	add({ source = "nvim-lualine/lualine.nvim" })
	require('lualine').setup {
		options = {
			icons_enabled = true,
			theme = 'autO',
			component_separators = { left = '', right = '' },
			section_separators = { left = '', right = '' },
			disabled_filetypes = {
				statusline = {},
				winbar = {},
			},
			ignore_focus = {},
			always_divide_middle = true,
			globalstatus = true,
			refresh = {
				statusline = 1000,
				tabline = 1000,
				winbar = 1000,
			}
		},
		sections = {
			lualine_a = { 'filename' },
			lualine_b = { 'branch', 'diff', 'diagnostics' },
			lualine_x = { {
				"swenv",
				cond = function()
					-- 检查文件类型是否为 Python 或 buf 类型是命令行
					local ft = vim.bo.filetype
					local buftype = vim.bo.buftype
					return ft == "python" or buftype == "terminal" or buftype == "prompt"
				end,
				icon = ""
			} },
			lualine_y = { 'filesize', 'filetype' },
			lualine_z = { 'location' }
		},
		inactive_sections = {
			lualine_a = {},
			lualine_b = {},
			lualine_c = { 'filename' },
			lualine_x = { 'location' },
			lualine_y = {},
			lualine_z = {}
		},
		tabline = {},
		winbar = {},
		inactive_winbar = {},
		extensions = {}
	}
end)

later(function()
	add("akinsho/toggleterm.nvim")
	require("toggleterm").setup({
		shade_terminals = false,
		autochdir = true,

	})
end)



now(function()
	add("dstein64/nvim-scrollview")
	require("scrollview").setup({
		mode = "virtual",
		excluded_filetypes = { 'nerdtree' },
		current_only = true,
		base = 'right',
		column = 1,
		signs_on_startup = { 'all' },
		diagnostics_severities = { vim.diagnostic.severity.ERROR }
	})
end)
later(function()
	add("Bekaboo/dropbar.nvim")
	local api = require("dropbar.api")

	-- Confirm function to handle Enter and interaction with menu
	local confirm = function()
		local menu = api.get_current_dropbar_menu()
		if not menu then
			return
		end
		local cursor = vim.api.nvim_win_get_cursor(menu.win)
		local component = menu.entries[cursor[1]]:first_clickable(cursor[2])
		if component then
			menu:click_on(component)
		end
	end

	-- Function to quit the current menu
	local quit_curr = function()
		local menu = api.get_current_dropbar_menu()
		if menu then
			menu:close()
		end
	end

	require("dropbar").setup({
		menu = {
			quick_navigation = true, -- 自动快速导航
			keymaps = {
				['<LeftMouse>'] = function()
					local menu = api.get_current_dropbar_menu()
					if not menu then
						return
					end
					local mouse = vim.fn.getmousepos()
					if mouse.winid ~= menu.win then
						local parent_menu = api.get_dropbar_menu(mouse.winid)
						if parent_menu and parent_menu.sub_menu then
							parent_menu.sub_menu:close()
						end
						if vim.api.nvim_win_is_valid(mouse.winid) then
							vim.api.nvim_set_current_win(mouse.winid)
						end
						return
					end
					menu:click_at({ mouse.line, mouse.column }, nil, 1, 'l')
				end,
				['<CR>'] = confirm,
				['i'] = confirm,
				['<esc>'] = quit_curr,
				['q'] = quit_curr,
				['n'] = quit_curr,
				['<MouseMove>'] = function()
					local menu = api.get_current_dropbar_menu()
					if not menu then
						return
					end
					local mouse = vim.fn.getmousepos()
					if mouse.winid ~= menu.win then
						return
					end
					menu:update_hover_hl({ mouse.line, mouse.column - 1 })
				end,
			},
		},
	})
end)

later(function()
	add("folke/which-key.nvim")
	require("which-key").setup()
end)


now(function()
	add({
		source = 'nvim-telescope/telescope.nvim',
		branch = "0.1.x",
		depends = {
			'nvim-lua/plenary.nvim',
			'nvim-telescope/telescope-fzf-native.nvim' },
	})

	local telescope = require('telescope')
	telescope.setup({
		extensions = {
			-- fzf = {
			--     fuzzy = true,               -- false will only do exact matching
			--     override_generic_sorter = true, -- override the generic sorter
			--     override_file_sorter = true, -- override the file sorter
			--     case_mode = "smart_case",   -- or "ignore_case" or "respect_case"
			-- }
		}
	})

	-- TODO:
	-- telescope.load_extension("workspaces")
	-- telescope.load_extension('fzf')


	map("nv", '<leader>ff', function() require('telescope.builtin').find_files() end, 'Find Files')
	map("nv", '<leader>fg', function() require('telescope.builtin').live_grep() end, 'Live Grep')
	map("nv", '<leader>fb', function() require('telescope.builtin').buffers() end, 'Find Buffers')
	map("nv", '<leader>fh', function() require('telescope.builtin').help_tags() end, 'Find Help Tags')
	map("nv", '<leader>fw', "<CMD>Telescope workspaces<CR>", 'Find workspaces')
end)

now(function()
	add('nvimdev/dashboard-nvim')
	require('dashboard').setup {
		theme = "hyper",
		config = {
			shortcut = {
				-- action can be a function type
			},
			packages = { enable = true },       -- show how many plugins neovim loaded
			project = { enable = true, limit = 8, icon = '󱠿', label = '\t近期 ^_^ 目录', action = 'Telescope find_files cwd=' },
			mru = { limit = 10, icon = '', label = '\t近期 $_$ 文件', cwd_only = false },
			footer = {},       -- footer
		}

	}
end)

