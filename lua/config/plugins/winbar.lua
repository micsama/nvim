return {
	"Bekaboo/dropbar.nvim",
	event = "BufReadPost", -- 懒加载配置：当读取文件时加载插件
	keys = {
		{ '<Leader>;', function() require("dropbar.api").pick() end,                desc = 'Pick dropbar menu' },
		{ '[c',        function() require("dropbar.api").goto_context_start() end,  desc = 'Go to context start' },
		{ ']c',        function() require("dropbar.api").select_next_context() end, desc = 'Select next context' },
	},
	config = function()
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

		-- 设置 Tab 页显示编号
		-- vim.o.tabline = '%!v:lua.require("dropbar.tabline").setup()'
	end,
}
