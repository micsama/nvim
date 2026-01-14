-- ===========================================================================
-- 本地Olama-qwen3 适配器配置
-- ===========================================================================

local M = require("codecompanion.adapters.http").extend("ollama", {
	name = "qwen3",
	opts = { vision = true, stream = true },
	schema = {
		model = { default = "qwen3:4b-instruct" },
		think = { default = false },
		num_ctx = { default = 16384 },
		keep_alive = { default = "5m" },
	},
})
return M
