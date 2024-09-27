local function o_temp()
	require('overseer').register_template({
			name = "Python run this file!",
			builder = function()
				-- 定义任务的具体行为
				local file_path = vim.fn.expand("%:p")
				local file_name = vim.fn.expand("%:t")
				return {
					cmd = { "fish","-c","python "..file_path },
					name = file_name .. " running", -- 任务的名字
					cwd = "./",
					env = {},
					components = {
						{ "on_complete_dispose", { timeout = 1000 } },
						"default",
					},
					metadata = { foo = "bar", },
				}
			end,
			-- 定义任务的描述和标签
			description = "Run this file in python",
			tags = { "Run File" },
			params = {}, -- 如果需要，可以在这里添加任务参数
		},
		{
			name = "Pull & build Neovim!",
			builder = function()
				-- 定义任务的具体行为
				return {
					cmd = { "bash", "build.sh" },
					name = " Try to build Neovim", -- 任务的名字
					cwd = "~/workspace/tools/neovim/",
					components = {
						{ "on_complete_dispose", { timeout = 2000 } },
						"default",
					},
				}
			end,
			-- 定义任务的描述和标签
			description = "Try to pull and build the newest Neovim",
			tags = { "Build", "Neovim" },
			params = {}, -- 如果需要，可以在这里添加任务参数
		})
end
return {
	{
		'stevearc/overseer.nvim',
		opts = {},
		keys = {
			{ "<leader>or", ":OverseerRun<CR>",    desc = "Run Overseer Task" },
			{ "<leader>oo", ":OverseerToggle<CR>", desc = "Toggle Overseer" },
		},
		config = function()
			require('overseer').setup({
				-- strategy = {
				-- 	"toggleterm",
				-- 	open_on_start = false,
				-- 	auto_scroll = true,
				-- },
				templates = { "builtin" },
				task_defaults = {
					-- 设置默认 shell 为 Fish
					cmd = { 'fish', '-c' },
				},
			})
			o_temp()
		end
	},
	{
		'akinsho/toggleterm.nvim',
		version = "*",
		keys = {
			{ "<D-g>", ":ToggleTerm dir=git_dir<CR>",            mode = { "n", "v" }, desc = "Toggle terminal" },
			{ "<D-g>", "<C-\\><C-n>:ToggleTerm dir=git_dir<CR>", mode = { "i", "t" }, desc = "Toggle terminal" },
		},
		opts = {
			shade_terminals = false,
			autochdir = true,
		},
	},
	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		opts = {}
	},
	
}
