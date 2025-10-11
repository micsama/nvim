-- ============================================================================
-- 模块引入
-- ============================================================================
local map = require('util.utils').map

-- ============================================================================
-- CodeCompanion Ollama (qwen3) 适配器配置
-- ============================================================================

-- 提取 Ollama (qwen3) 适配器的配置，减少 setup 内部的嵌套深度
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

-- ============================================================================
-- CodeCompanion 主配置
-- ============================================================================
require('codecompanion').setup({
	-- 所有策略都使用 qwen3 适配器
	strategies = { chat = { adapter = 'qwen3' }, inline = { adapter = 'qwen3' }, agent = { adapter = 'qwen3' } },
	adapters = {
		http = { qwen3 = function() return qwen3_ollama_adapter end }
	},
})

-- 快捷键映射：直接调用 Lua 函数
map('nv', '<D-o>', require('codecompanion.chat').toggle, 'Open the LLM')
