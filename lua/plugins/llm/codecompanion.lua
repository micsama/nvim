-- ===========================================================================
-- LLM 配置：CodeCompanion
-- 插件只安装不加载（见 init.lua），首次 <D-o> / :CodeCompanion* 时才加载
-- ===========================================================================
local lazy = require("utils.lazy")
local M = {}

M.load = lazy.once(function()
	vim.cmd.packadd("codecompanion.nvim")
	-- 插件用 BufEnter 记录"最近编辑的 buffer"作为聊天上下文；加载前的那次 BufEnter 错过了，补发一次
	vim.api.nvim_exec_autocmds("BufEnter", { group = "codecompanion.buffers", buffer = 0 })

	local deepseek_adapter = require("codecompanion.adapters.http").extend("deepseek", {
		name = "deepseek",
		url = "https://api.deepseek.com/chat/completions",
		env = { api_key = "DEEPSEEK_API_KEY" },
		schema = {
			model = { default = "deepseek-chat" },
		},
	})

	require("codecompanion").setup({
		opts = { language = "简体中文" },
		interactions = {
			chat = { adapter = "deepseek" },
			inline = { adapter = "deepseek" },
		},
		adapters = {
			http = {
				opts = { show_presets = false, show_model_choices = false },
				deepseek = deepseek_adapter,
			},
		},
	})
end)

lazy.on_cmd({
	"CodeCompanion",
	"CodeCompanionChat",
	"CodeCompanionCmd",
	"CodeCompanionCLI",
	"CodeCompanionActions",
	"CodeCompanionCodeReview",
}, M.load)

return M
