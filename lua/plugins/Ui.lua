-- ===========================================================================
-- UI 与外观：状态栏 / 标签页 / 通知 / 查找器
-- ===========================================================================
local map = require("utils.map").map
-- ============================================================================
-- 1) Which-Key (Keymap Helper)
-- ============================================================================
require("which-key").setup({ preset = "modern" })

-- ============================================================================
-- 2) Notify (Notifications)
-- ============================================================================
require("notify").setup({
	timeout = 1500,
	render = "compact",
	icons = { ERROR = "✘ ", WARN = "󱓈 ", INFO = "󰋽 ", DEBUG = "󰛩 ", TRACE = "󰓎 " },
})
vim.notify = require("notify")

-- ============================================================================
-- 3) Lualine (Statusline)
-- ============================================================================
local function short_cwd(max_len)
	local dir = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
	return (#dir > max_len) and (dir:sub(1, max_len) .. "...") or dir
end

require("lualine").setup({
	sections = {
		lualine_a = { {
			function()
				return short_cwd(10)
			end,
			icon = "󰉖",
		}, "filename" },
		lualine_b = { "branch" },
		lualine_c = { "diff", "diagnostics" },
		lualine_x = { "filesize", "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
})

-- ============================================================================
-- 4) Telescope (Finder) + Keymaps
-- ============================================================================
local telescope, builtin = require("telescope"), require("telescope.builtin")
telescope.setup({
	defaults = {
		path_display = { "filename_first" },
		sorting_strategy = "ascending",
		layout_config = { prompt_position = "top" }, -- ascending + top prompt
	},
})
telescope.load_extension("fzf")

-- stylua: ignore start
local telescope_maps = {
  -- 文件 / 搜索（高频）
  { "nv", "<leader>ff", builtin.find_files,           "📁 查找文件" },
  { "nv", "<leader>fb", builtin.buffers,              "📁 查找Buffer" },
  { "nv", "<leader>fr", builtin.oldfiles,             "🕒 最近文件" },
  { "nv", "<leader>fg", builtin.live_grep,            "🔎 全局搜索" },
  { "nv", "<leader>fw", builtin.grep_string,          "🔦 搜索光标词" },
  { "nv", "<leader>f/", builtin.search_history,       "📜 搜索历史（/）" },
  { "nv", "<leader>f:", builtin.command_history,      "⌨️ 指令历史" },
  { "nv", "<leader>fs", builtin.treesitter,           "🌳 语法树符号" },
  { "nv", "<leader>fy", "<CMD>Telescope neoclip<CR>", "📋 剪贴板历史" },
  { "nv", "<leader>fn", "<CMD>Telescope notify<CR>",  "🔔 通知历史" },
  { "nv", "<leader>fp", "<CMD>Telescope pickers<CR>", "🧰 Picker 历史" },
}
vim.iter(telescope_maps):each(function(m) map(unpack(m)) end)
-- stylua: ignore end

-- ============================================================================
-- 5) Noice (UI Layer)
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
