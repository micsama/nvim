--  ███████╗██████╗ ██╗████████╗ ██████╗ ██████╗
--  ██╔════╝██╔══██╗██║╚══██╔══╝██╔═══██╗██╔══██╗
--  █████╗  ██║  ██║██║   ██║   ██║   ██║██████╔╝
--  ██╔══╝  ██║  ██║██║   ██║   ██║   ██║██╔══██╗
--  ███████╗██████╔╝██║   ██║   ╚██████╔╝██║  ██║
--  ╚══════╝╚═════╝ ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝
-- Editor Enhancements
-- Productivity Boosters & Workflow Optimizers
-- ============================================================================

local map = require("utils.map").map

-- ============================================================================
-- 1) 命令 / 修复工具 (Commands & Fixers)
-- ============================================================================
vim.api.nvim_create_user_command("FixUI", function()
	vim.cmd("setlocal number relativenumber signcolumn=yes cursorline list")
end, { desc = "修复窗口 UI：行号 / signcolumn / cursorline / list" })

-- ============================================================================
-- 2) Undotree (Undo History UI)
-- ============================================================================
vim.g.undotree_DiffAutoOpen = 1
vim.g.undotree_SetFocusWhenToggle = 1
vim.g.undotree_ShortIndicators = 1
vim.g.undotree_WindowLayout = 2 -- 1=左侧，2=右侧
vim.g.undotree_DiffpanelHeight = 8
vim.g.undotree_SplitWidth = 24

vim.api.nvim_create_autocmd("FileType", {
	pattern = "undotree",
	desc = "Undotree 自定义快捷键",
	callback = function()
		map("n", "k", "<plug>UndotreeNextState", { buffer = true, silent = true })
		map("n", "j", "<plug>UndotreePreviousState", { buffer = true, silent = true })
		map("n", "K", "5<plug>UndotreeNextState", { buffer = true, silent = true })
		map("n", "J", "5<plug>UndotreePreviousState", { buffer = true, silent = true })
	end,
})

-- ============================================================================
-- 3) Editing Helpers (Text Objects / Writing)
-- ============================================================================
require("wildfire").setup({}) -- 默认配置
require("Bullets").setup({}) -- 默认配置

-- ============================================================================
-- 4) Noice (UI Layer)
-- ============================================================================
require("noice").setup({
	cmdline = { enabled = true, view = "cmdline_popup" }, -- 只保留 cmdline UI
	messages = { enabled = false },
	popupmenu = { enabled = false },
	notify = { enabled = false },
	lsp = {
		progress = { enabled = true, throttle = 1000 / 15, format = "lsp_progress" },
		message = { enabled = true },
		hover = { enabled = false },
		signature = { enabled = false },
	},
})

-- ============================================================================
-- 5) Clipboard History (Neoclip)
-- ============================================================================
require("neoclip").setup({ enable_persistent_history = true })

require("mason").setup({ ui = { icons = { package_installed = "✓" } } })
require("faster").setup({
	behaviours = {
		bigfile = {
			filesize = 10,
			features_disabled = {
				"illuminate", -- 引用高亮：大文件下频繁扫描，容易卡顿
				"matchparen", -- 括号匹配：嵌套复杂时重绘/计算开销高
				"lsp", -- LSP：诊断/语义分析在大文件下成本很高
				"treesitter", -- Treesitter：AST 构建与查询开销大，优先保障流畅
				"indent_blankline", -- 缩进线：大量虚拟文本影响渲染性能
				"vimopts", -- 自动本地选项：避免隐式副作用（大文件以稳定为先）
				-- "syntax",        -- 传统语法高亮：开启通常会明显拖慢
				-- "filetype",      -- 文件类型检测：一般无需禁用，除非极端场景
			},
		},
	},
})
