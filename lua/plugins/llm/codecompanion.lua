-- ============================================================================
-- 导入各个LLM适配器模块
-- ============================================================================
local gpt5_adapter = require("plugins.llm.gpt5")
local deepseek_adapter = require("plugins.llm.deepseek")
local qwen3_ollama_adapter = require("plugins.llm.ollamaqwen3")

require("codecompanion").setup({
	opts = { language = "简体中文" },
	interactions = {
		chat = { adapter = "deepseek" },
		inline = { adapter = "deepseek" },
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
