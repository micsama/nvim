-- ============================================================================
-- 导入各个LLM适配器模块
-- ============================================================================

local gpt5_adapter = require("plugins.llm.gpt5")
local qwen3_ollama_adapter = require("plugins.llm.ollamaqwen3")

local deepseek_adapter = require("codecompanion.adapters.http").extend("deepseek", {
	name = "deepseek",
	url = "https://api.deepseek.com/chat/completions",
	env = { api_key = "DEEPSEEK_API_KEY" },
	schema = {
		model = { default = "deepseek-chat" },
	},
})

local v = os.getenv("CODECOMPANION_LLM")
local env_llm = (v == "gpt5" or v == "qwen3_ollama") and v or "deepseek"

require("codecompanion").setup({
	opts = { language = "简体中文" },
	interactions = {
		chat = { adapter = env_llm },
		inline = { adapter = env_llm },
	},
	-- 适配器配置
	adapters = {
		http = {
			opts = { show_presets = false, show_model_choices = false },
			deepseek = deepseek_adapter,
			gpt5 = gpt5_adapter,
			qwen3_ollama = qwen3_ollama_adapter,
		},
	},
})
