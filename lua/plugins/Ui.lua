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

local apps = {
	["<D-g>"] = { "切换终端" },
	["<D-i>"] = { "Lazygit", { cmd = "lazygit", window = { width = 1, height = 1 } } },
	["<D-e>"] = { "Codex", { cmd = "codex", window = { width = 0.9, height = 0.95 } } },
}

local base = { id = vim.fn.getcwd, wo = { wrap = true } }
for key, cfg in pairs(apps) do
	local opts = vim.tbl_deep_extend("force", base, cfg[2] or {})
	map("ntv", key, require("floatty").setup(opts).toggle, "打开" .. cfg[1])
end

-- 3. Which-Key 基础配置
require("which-key").setup({
	preset = "modern",
})

-- ============================================================================
-- 界面和状态栏 (Bufferline / Lualine)
-- ============================================================================

-- 1. Bufferline (顶部标签页)
require("bufferline").setup({
	options = {
		mode = "tabs",
		numbers = "ordinal",
		diagnostics = "nvim_lsp",
		diagnostics_indicator = function(count, level)
			local icon = level:match("error") and " " or " "
			return " " .. icon .. count
		end,
		indicator = {
			icon = "▎ ",
			style = "icon",
		},
		tab_size = 12,
		padding = 0,
	},
})

require("notify").setup({
	timeout = 1500,
	render = "compact",
	icons = {
		ERROR = "✘ ",
		WARN = "󱓈 ",
		INFO = "󰋽 ",
		DEBUG = "󰛩 ",
		TRACE = "󰓎 ",
	},
})

vim.notify = require("notify")

-- 2. Lualine (底部状态栏)
require("lualine").setup({
	sections = {
		lualine_a = {
			{
				function()
					local dir = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
					return #dir > 10 and dir:sub(1, 10) .. "..." or dir
				end,
				icon = "󰉖",
			},
			"filename",
		},
		lualine_b = { "branch" },
		lualine_c = { "diff", "diagnostics" },
		lualine_x = { "filesize", "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
})

-- ============================================================================
-- 模糊查找 (Telescope) 及快捷键
-- ============================================================================
require("telescope").setup({
	defaults = {
		path_display = { "filename_first" },
		sorting_strategy = "ascending",
		layout_config = {
			prompt_position = "top", -- 配合上面的 ascending，搜索框就在最顶端
		},
	},
})
local builtin = require("telescope.builtin")
require("telescope").load_extension("fzf")

-- stylua: ignore start
local telescope_maps = {
  -- 文件 / 搜索（高频）
  { "nv", "<leader>ff", builtin.find_files,      "📁 查找文件" },
  { "nv", "<leader>fr", builtin.oldfiles,        "🕒 最近文件" },
  { "nv", "<leader>fg", builtin.live_grep,       "🔎 全局搜索" },
  { "nv", "<leader>fw", builtin.grep_string,     "🔦 搜索光标词" },
  { "nv", "<leader>f/", builtin.search_history,  "📜 搜索历史（/）" },
	{ "nv", "<leader>f:", builtin.command_history, "⌨️ 指令历史" },

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
