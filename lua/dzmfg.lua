require("onedarkpro").setup({
	colors = {
		cursorline = "#303442" -- This is optional. The default cursorline color is based on the background
	},
	options = {
		cursorline = true
	}
})
vim.cmd.colorscheme('onedark')

-- 加载对应的插件配置
require("plugins.Ui")
require("plugins.lsp")
require("plugins.editor")
require("plugins.filemanager")
require("plugins.dap")
require("plugins.cmp")
require("plugins.other")
require("plugins.llm")
require("plugins.git")
