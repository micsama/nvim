local qwen3_ollama_adapter = require('plugins.llm.local.qwen3')
local deepseek_adapter = require('plugins.llm.deepseek')
local gpt5_code_adapter = require('plugins.llm.gpt5')

local IS_MACOS = vim.uv.os_uname().sysname == 'Darwin'



-- 定义 DeepSeek 模型的配置，语言设置为简体中文
local gpt5_apapter = {
  opts = { language = '简体中文' },
  adapter = 'gpt5'
}

-- 定义 DeepSeek 模型的配置，语言设置为简体中文
local ds_adapter = {
  opts = { language = '简体中文' },
  adapter = 'deepseek'
}

-- 定义 Qwen3 模型的配置，语言设置为简体中文
local qw_adapter = {
  opts = { language = '简体中文' },
  adapter = 'qwen3'
}

local gpt5 = {
  chat = gpt5_apapter,
  inline = gpt5_adapter,
  agent = gpt5_adapter
}
-- Qwen3 模型的策略配置，包括聊天、内联和代理模式，均使用 qw_adapter 配置
local qwen3_local = {
  chat = qw_adapter,
  inline = qw_adapter,
  agent = qw_adapter
}

-- DeepSeek 模型的策略配置，包括聊天、内联和代理模式，均使用 ds_adapter 配置
local deepseek = {
  chat = ds_adapter,
  inline = ds_adapter,
  agent = ds_adapter
}

-- 配置 codecompanion 插件，根据操作系统选择使用 Qwen3 或 DeepSeek 模型
-- 在 macOS 上使用 qwen3_local，否则使用 deepseek
require('codecompanion').setup({
  strategies = IS_MACOS and gpt5 or deepseek,
  adapters = {
    http = {
      gpt5 = function() return gpt5_code_adapter end,
      deepseek = function() return deepseek_adapter end,
      qwen3 = function() return qwen3_ollama_adapter end,
    }
  }
})
