local map = require('util.utils').map

require('codecompanion').setup({
	strategies = {
		chat = { adapter = 'qwen3' },
		inline = { adapter = 'qwen3' },
		agent = { adapter = 'qwen3' },
	},
	adapters = {
		http = {
			qwen3 = function()
				return require('codecompanion.adapters.http').extend('ollama', {
					name = 'qwen3',
					opts = {
						vision = true,
						stream = true,
					},
					schema = {
						model = {
							-- default = 'qwen3:4b-instruct-2507-q8_0',
							default = 'qwen3:8b',
						},
						think = {
							default = false,
						},
						num_ctx = {
							default = 16384,
						},
						keep_alive = {
							default = '5m',
						},
					}
				})
			end,
		}
	},
})

map('nv', '<D-o>', '<CMD>CodeCompanionChat Toggle<CR>', 'Open the LLM')
