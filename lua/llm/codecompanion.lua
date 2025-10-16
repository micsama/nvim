local qwen3_ollama_adapter = require('llm.local.qwen3')
local deepseek_adapter = require('llm.deepseek')

-- Common configuration for all strategies
local adapter = {
  opts = { language = '简体中文' },
  adapter = 'deepseek'
}

require('codecompanion').setup({
  strategies = {
    chat = adapter,
    inline = adapter,
    agent = adapter
  },
  adapters = {
    http = {
      deepseek = function() return deepseek_adapter end,
      qwen3 = function() return qwen3_ollama_adapter end,
    }
  },
})

