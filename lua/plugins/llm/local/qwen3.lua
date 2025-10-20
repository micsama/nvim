
-- ============================================================================
-- CodeCompanion Ollama (qwen3) 适配器配置
-- ============================================================================

-- 提取 Ollama (qwen3) 适配器的配置

local qwen3_ollama_adapter = require('codecompanion.adapters.http').extend('ollama', {
	name = 'qwen3',
	opts = { vision = true, stream = true },
	schema = {
		model = { default = 'qwen3:4b-instruct-2507-q8_0' },
		think = { default = false },
		num_ctx = { default = 16384 },
		keep_alive = { default = '5m' },
	}
})
return qwen3_ollama_adapter
