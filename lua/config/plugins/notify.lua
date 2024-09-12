return {
	{
		"rcarriga/nvim-notify",
		event = "VeryLazy",
		keys = {
			{
				",;",
				function()
					require('telescope').extensions.notify.notify({
						layout_strategy = 'vertical',
						layout_config = {
							width = 0.9,
							height = 0.9,
						},
						wrap_results = true,
						previewer = false,
					})
				end,
				desc = "Open Notification History"
			},
			{
				"<LEADER>c;",
				function()
					require("notify").dismiss()
				end,
				desc = "Dismiss Notifications"
			},
		},
		config = function()
			local notify = require("notify")

			-- 自定义 vim.notify 函数，过滤特定错误信息
			vim.notify = function(msg, ...)
				if string.match(msg, "error drawing label for") then
					return
				end
				notify(msg, ...)
			end

			-- 设置 nvim-notify 配置
			notify.setup({
				on_open = function(win)
					vim.api.nvim_win_set_config(win, { border = "none" })
				end,
				background_colour = "#202020",
				fps = 60,
				level = 2,
				minimum_width = 50,
				render = "compact",
				stages = "fade_in_slide_out",
				timeout = 3000,
				top_down = true,
			})
		end,
	},
}
