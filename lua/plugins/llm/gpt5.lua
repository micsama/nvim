-- ===========================================================================
-- fakercode GPT 适配器配置
-- ===========================================================================

local M = require("codecompanion.adapters.http").extend("openai", {
	name = "gpt5.2",
	url = "https://www.fakercode.top/v1/chat/completions",
	env = { api_key = "CODEAPIKEY" },
	schema = {
		model = { default = "gpt5.2" },
	},
})
return M
