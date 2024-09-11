-- 设置 DAP 相关的图标和高亮颜色
local function set_dap_signs_and_highlights()
	vim.api.nvim_set_hl(0, 'DapBreakpoint', { ctermbg = 0, fg = '#993939', bg = '#31353f' })
	vim.api.nvim_set_hl(0, 'DapLogPoint', { ctermbg = 0, fg = '#61afef', bg = '#31353f' })
	vim.api.nvim_set_hl(0, 'DapStopped', { ctermbg = 0, fg = '#ffffff', bg = '#FE3C25' })

	vim.fn.sign_define('DapBreakpoint',
		{ text = '', texthl = 'DapBreakpoint', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })
	vim.fn.sign_define('DapBreakpointCondition',
		{ text = 'ﳁ', texthl = 'DapBreakpoint', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })
	vim.fn.sign_define('DapBreakpointRejected',
		{ text = '', texthl = 'DapBreakpoint', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })
	vim.fn.sign_define('DapLogPoint', { text = '', texthl = 'DapLogPoint', linehl = 'DapLogPoint', numhl = 'DapLogPoint' })
	vim.fn.sign_define('DapStopped', { text = '', texthl = 'DapStopped', linehl = 'DapStopped', numhl = 'DapStopped' })
end

-- 设置 DAP UI 的监听器
local function set_dap_ui_listeners(dap, dapui)
	dap.listeners.before.attach.dapui_config = function() dapui.open() end
	dap.listeners.before.launch.dapui_config = function() dapui.open() end
	dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
	dap.listeners.before.event_exited.dapui_config = function() dapui.close() end
end

-- DAP 插件的配置
return {
	"rcarriga/nvim-dap-ui",
	dependencies = {
		{ "mfussenegger/nvim-dap" },
		{ "nvim-telescope/telescope-dap.nvim" },
		{ "theHamsta/nvim-dap-virtual-text" },
		{ "mfussenegger/nvim-dap-python" },
		{ "jay-babu/mason-nvim-dap.nvim" },
		{ "nvim-neotest/nvim-nio" }
	},
	-- 使用按键绑定懒加载
	keys = {
		{ "<F10>",      function() require('dap').step_over() end,                                                   desc = "DAP Step Over" },
		{ "<F11>",      function() require('dap').step_into() end,                                                   desc = "DAP Step Into" },
		{ "<F12>",      function() require('dap').step_out() end,                                                    desc = "DAP Step Out" },
		{ "<Leader>b",  function() require('dap').toggle_breakpoint() end,                                           desc = "DAP Toggle Breakpoint" },
		{ "<Leader>B",  function() require('dap').set_breakpoint() end,                                              desc = "DAP Set Breakpoint" },
		{ "<Leader>lp", function() require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end, desc = "DAP Set Log Point" },
		{ "<Leader>dr", function() require('dap').repl.open() end,                                                   desc = "DAP Open REPL" },
		{ "<Leader>dl", function() require('dap').run_last() end,                                                    desc = "DAP Run Last" },
		{ "<Leader>dh", function() require('dap.ui.widgets').hover() end,                                            mode = { "n", "v" },           desc = "DAP Hover" },
		{ "<Leader>dp", function() require('dap.ui.widgets').preview() end,                                          mode = { "n", "v" },           desc = "DAP Preview" },
		{ "<Leader>df", function() require('dap.ui.widgets').centered_float(require('dap.ui.widgets').frames) end,   desc = "DAP Frames" },
		{ "<Leader>ds", function() require('dap.ui.widgets').centered_float(require('dap.ui.widgets').scopes) end,   desc = "DAP Scopes" },
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		-- 设置 DAP UI
		require("nvim-dap-virtual-text").setup()
		require("mason-nvim-dap").setup({ ensure_installed = { "python" } })
		require("dap-python").setup("python")
		dapui.setup()

		-- 设置 DAP UI 监听器
		set_dap_ui_listeners(dap, dapui)

		-- 设置 DAP 图标和高亮
		set_dap_signs_and_highlights()

		-- DAP 配置
		dap.configurations.python = {
			{
				type = "python",
				request = "launch",
				name = "Launch File",
				program = "${file}",
				args = {}
			},
			{
				type = "python",
				request = "launch",
				name = "Launch File1",
				program = "${file}",
				args = {}
			}
		}

		-- 加载 Telescope 的 DAP 扩展
		require('telescope').load_extension('dap')
	end,
}
