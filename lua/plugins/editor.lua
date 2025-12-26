--  ███████╗██████╗ ██╗████████╗ ██████╗ ██████╗
--  ██╔════╝██╔══██╗██║╚══██╔══╝██╔═══██╗██╔══██╗
--  █████╗  ██║  ██║██║   ██║   ██║   ██║██████╔╝
--  ██╔══╝  ██║  ██║██║   ██║   ██║   ██║██╔══██╗
--  ███████╗██████╔╝██║   ██║   ╚██████╔╝██║  ██║
--  ╚══════╝╚═════╝ ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝
-- Editor Enhancement Plugins
-- ✨ Productivity Boosters & Workflow Optimizers
-- ============================================================================
-- 插件配置
-- ============================================================================

-- ## Undotree
-- 统一使用 Lua 变量来配置 Undotree 的全局选项
vim.g.undotree_DiffAutoOpen = 1
vim.g.undotree_SetFocusWhenToggle = 1
vim.g.undotree_ShortIndicators = 1
vim.g.undotree_WindowLayout = 2 -- 布局：1=左侧，2=右侧
vim.g.undotree_DiffpanelHeight = 8
vim.g.undotree_SplitWidth = 24

-- 使用 Lua 的 autocmd 来创建 Buffer 级的快捷键映射，替换 Vimscript 函数
vim.api.nvim_create_autocmd("FileType", {
	pattern = "undotree",
	callback = function()
		vim.keymap.set("n", "k", "<plug>UndotreeNextState", { buffer = true, silent = true })
		vim.keymap.set("n", "j", "<plug>UndotreePreviousState", { buffer = true, silent = true })
		vim.keymap.set("n", "K", "5<plug>UndotreeNextState", { buffer = true, silent = true })
		vim.keymap.set("n", "J", "5<plug>UndotreePreviousState", { buffer = true, silent = true })
	end,
	desc = "Undotree 自定义快捷键",
})

-- ## 其他插件配置
require("wildfire").setup({
		surrounds = {
			{ "(", ")" },
			{ "{", "}" },
			{ "<", ">" },
			{ "[", "]" },
		},
		keymaps = {
			init_selection = "<CR>",
			node_incremental = "<CR>",
			node_decremental = "<BS>",
		},
		filetype_exclude = { "qf" }, --keymaps will be unset in excluding filetypes
})

require("yazi").setup()

require("Bullets").setup({})

require("tiny-inline-diagnostic").setup()

require("neoclip").setup({ enable_persistent_history = true })
