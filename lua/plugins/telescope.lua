local map = require("utils.map").map
local lazy = require("utils.lazy")

-- ============================================================================
-- 4) Telescope (Finder) + Keymaps
-- 插件只安装不加载（见 init.lua），首次按键 / :Telescope / 最近仓库 picker 时才加载
-- ============================================================================
local M = {}

M.load = lazy.once(function()
	vim.cmd.packadd("telescope.nvim")
	vim.cmd.packadd("telescope-fzf-native.nvim")
	local telescope = require("telescope")
	telescope.setup({
		defaults = {
			path_display = { "filename_first" },
			sorting_strategy = "ascending",
			layout_config = { prompt_position = "top" }, -- ascending + top prompt
		},
	})
	telescope.load_extension("fzf")
end)

lazy.on_cmd({ "Telescope" }, M.load)

local function builtin(name)
	return function()
		M.load()
		require("telescope.builtin")[name]()
	end
end

-- stylua: ignore start
local telescope_maps = {
  -- 文件 / 搜索（高频）
  { "nv", "<leader>ff", builtin("find_files"),        "📁 查找文件" },
  { "nv", "<leader>fb", builtin("buffers"),           "📁 查找Buffer" },
  { "nv", "<leader>fR", builtin("oldfiles"),          "🕒 最近文件" },
  { "nv", "<leader>fg", builtin("live_grep"),         "🔎 全局搜索" },
  { "nv", "<leader>fw", builtin("grep_string"),       "🔦 搜索光标词" },
  { "nv", "<leader>f/", builtin("search_history"),    "📜 搜索历史（/）" },
  { "nv", "<leader>f:", builtin("command_history"),   "⌨️ 指令历史" },
  { "nv", "<leader>fs", builtin("treesitter"),        "🌳 语法树符号" },
  { "nv", "<leader>fy", "<CMD>Telescope neoclip<CR>", "📋 剪贴板历史" },
  { "nv", "<leader>fn", "<CMD>Telescope notify<CR>",  "🔔 通知历史" },
  { "nv", "<leader>fp", "<CMD>Telescope pickers<CR>", "🧰 Picker 历史" },
  { "nv", "<leader>fr", function() require("apps.recent_repos").picker() end, "🗂️ 最近仓库" },
}
vim.iter(telescope_maps):each(function(m) map(unpack(m)) end)
-- stylua: ignore end

return M
