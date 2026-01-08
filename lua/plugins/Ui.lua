--  ██╗   ██╗██╗
--  ██║   ██║██║
--  ██║   ██║██║
--  ██║   ██║██║
--  ╚██████╔╝██║
--   ╚═════╝ ╚═╝
-- User Interface & Appearance Plugins
-- 🎨 Themes, Statuslines, and Visual Enhancements
-- ============================================================================
-- 模块引入与实用工具
-- ============================================================================
local map = require("utils").map

-- ============================================================================
-- 核心工具 (Floatty / Lazygit / Which-Key)
-- ============================================================================

-- Floatty 配置基础（使用当前工作目录作为 ID）
local floatty_opts = { id = vim.fn.getcwd, wo = { wrap = true } }

-- 1. 普通浮动终端 (term)
local term = require("floatty").setup(floatty_opts)
map("ntv", "<D-g>", term.toggle, "切换终端")

-- 2. Lazygit 浮动窗口
local lazygit = require("floatty").setup(vim.tbl_deep_extend("force", floatty_opts, {
	cmd = "lazygit",
	window = { width = 1, height = 1 },
}))
-- map("n", "<leader>gg", lazygit.toggle, "打开lazygit")
map("ntv", "<D-i>", lazygit.toggle, "打开lazygit")

-- 2. Codex 浮动窗口
local codex = require("floatty").setup(vim.tbl_deep_extend("force", floatty_opts, {
	cmd = "codex",
	window = { width = 0.9, height = 0.95 },
}))
map("ntv", "<D-e>", codex.toggle, "打开codex")

-- 3. Which-Key 基础配置
require("which-key").setup()

-- ============================================================================
-- 界面和状态栏 (Bufferline / Lualine)
-- ============================================================================

-- 1. Bufferline (顶部标签页)
require("bufferline").setup({
	options = {
		mode = "tabs",
		numbers = function(opts)
			return string.format("%s", opts.ordinal)
		end,
		diagnostics = "nvim_lsp",
		diagnostics_indicator = function(count, level, diagnostics_dict, context)
			local icon = level:match("error") and " " or " "
			return " " .. icon .. count
		end,
		indicator = {
			icon = "▎ ",
			style = "icon",
		},
		tab_size = 12,
		padding = 0,
		left_trunc_marker = " ",
		right_trunc_marker = " ",
	},
})

-- 2. Lualine (底部状态栏)
require("lualine").setup({
	sections = {
		lualine_a = {
			' (function(d) return d:len() > 10 and d:sub(1, 10) .. "..." or d end)(vim.fn.fnamemodify(vim.fn.getcwd(), ":t")) ',
			"filename",
		},
		lualine_b = { "branch" },
		lualine_c = { "diff", "diagnostics" },
		lualine_x = { "progress" },
		lualine_y = { "filesize", "filetype" },
		lualine_z = { "location" },
	},
	-- tabline = {},
	-- winbar = {},
	-- inactive_winbar = {},
	-- extensions = {}
})

-- ============================================================================
-- 模糊查找 (Telescope) 及快捷键
-- ============================================================================
local builtin = require("telescope.builtin")
require("telescope").load_extension("fzf")

-- Telescope 快捷键映射
local map = require("utils").map
local builtin = require("telescope.builtin")

-- stylua: ignore start
local telescope_maps = {
  -- 文件 / 搜索（高频）
  { "nv", "<leader>ff", builtin.find_files,      "📁 查找文件" },
  { "nv", "<leader>fr", builtin.oldfiles,        "🕒 最近文件" },
  { "nv", "<leader>fg", builtin.live_grep,       "🔎 全局搜索" },
  { "nv", "<leader>fw", builtin.grep_string,     "🔦 搜索光标词" },
  { "nv", "<leader>f/", builtin.search_history,  "📜 搜索历史（/）" },

  -- 代码结构
  { "nv", "<leader>fs", builtin.treesitter,      "🌳 语法树符号" },

  -- 历史 / 回溯
  { "nv", "<leader>fy", "<CMD>Telescope neoclip<CR>", "📋 剪贴板历史" },
  { "nv", "<leader>fn", "<CMD>Telescope noice<CR>",   "🔔 通知历史" },
  { "nv", "<leader>fp", "<CMD>Telescope pickers<CR>", "🧰 Picker 历史" },
}

-- stylua: ignore end

vim.iter(telescope_maps):each(function(m)
	map(unpack(m))
end)
