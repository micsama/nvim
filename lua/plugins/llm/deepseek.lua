-- ============================================================================
-- DeepSeek 适配器配置
-- ============================================================================

local M = require("codecompanion.adapters.http").extend("deepseek", {
	name = "deepseek",
	url = "https://api.deepseek.com/chat/completions",
	env = {
		api_key = "DEEPSEEK_API_KEY",
	},
	schema = {
		model = { default = "deepseek-chat" },
	},
})
return M
