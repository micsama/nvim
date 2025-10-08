require('onedarkpro').setup({
	colors = {
		cursorline = '#303442' -- 自定义光标行颜色 (可选，默认基于背景)
	},
	options = {
		cursorline = true -- 启用 onedarkpro 对光标行的着色
	}
})
vim.cmd.colorscheme('onedark') -- 应用 onedark 主题


-- 加载功能模块配置 (Loading Functional Plugin Configurations)
require('plugins.mini')        -- 配置 mini家族的 核心插件
require('plugins.Ui')          -- 用户界面和外观
require('plugins.lsp')         -- 语言服务器协议 (LSP)
require('plugins.editor')      -- 编辑器增强功能
require('plugins.filemanager') -- 文件管理/导航
require('plugins.dap')         -- 调试适配器协议 (DAP)
require('plugins.cmp')         -- 补全引擎 (Completion)
require('plugins.other')       -- 其他通用插件
require('plugins.llm')         -- 大型语言模型相关插件
require('plugins.git')         -- Git 集成插件
