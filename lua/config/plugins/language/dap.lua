function set_dap_keys(dap)
	vim.keymap.set('n', '<F10>', function() dap.step_over() end)
	vim.keymap.set('n', '<F11>', function() dap.step_into() end)
	vim.keymap.set('n', '<F12>', function() dap.step_out() end)
	vim.keymap.set('n', '<Leader>b', function() dap.toggle_breakpoint() end)
	vim.keymap.set('n', '<Leader>B', function() dap.set_breakpoint() end)
	vim.keymap.set('n', '<Leader>lp',
		function() dap.set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end)
	vim.keymap.set('n', '<Leader>dr', function() dap.repl.open() end)
	vim.keymap.set('n', '<Leader>dl', function() dap.run_last() end)
	vim.keymap.set({ 'n', 'v' }, '<Leader>dh', function()
		require('dap.ui.widgets').hover()
	end)
	vim.keymap.set({ 'n', 'v' }, '<Leader>dp', function()
		require('dap.ui.widgets').preview()
	end)
	vim.keymap.set('n', '<Leader>df', function()
		local widgets = require('dap.ui.widgets')
		widgets.centered_float(widgets.frames)
	end)
	vim.keymap.set('n', '<Leader>ds', function()
		local widgets = require('dap.ui.widgets')
		widgets.centered_float(widgets.scopes)
	end)
	-- color & icon
	vim.api.nvim_set_hl(0, 'DapBreakpoint', { ctermbg = 0, fg = '#993939', bg = '#31353f' })
	vim.api.nvim_set_hl(0, 'DapLogPoint', { ctermbg = 0, fg = '#61afef', bg = '#31353f' })
	vim.api.nvim_set_hl(0, 'DapStopped', { ctermbg = 0, fg = '#ffffff', bg = '#FE3C25' })

	vim.fn.sign_define('DapBreakpoint',
		{ text = '', texthl = 'DapBreakpoint', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })
	vim.fn.sign_define('DapBreakpointCondition',
		{ text = 'ﳁ', texthl = 'DapBreakpoint', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })
	vim.fn.sign_define('DapBreakpointRejected',
		{ text = '', texthl = 'DapBreakpoint', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })
	vim.fn.sign_define('DapLogPoint', {
		text = '',
		texthl = 'DapLogPoint',
		linehl = 'DapLogPoint',
		numhl = 'DapLogPoint'
	})
	vim.fn.sign_define('DapStopped', { text = '', texthl = 'DapStopped', linehl = 'DapStopped', numhl = 'DapStopped' })
end

return {
	{
		"rcarriga/nvim-dap-ui",
		dependencies = {
			"jay-babu/mason-nvim-dap.nvim",
			'mfussenegger/nvim-dap',
			'nvim-telescope/telescope-dap.nvim',
			"nvim-neotest/nvim-nio",
			'theHamsta/nvim-dap-virtual-text',
			"mfussenegger/nvim-dap-python" },
		config = function()
			require("nvim-dap-virtual-text").setup()
			require("mason-nvim-dap").setup({
				ensure_installed = { "python" }
			})
			require("dap-python").setup("python")
			require("dapui").setup()
			local dap, dapui = require("dap"), require("dapui")
			set_dap_keys(dap)
			dap.listeners.before.attach.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.launch.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				dapui.close()
			end
			dap.listeners.before.event_exited.dapui_config = function()
				dapui.close()
			end
			require('telescope').load_extension('dap')
			-- dap.adapters.pyright = {
			-- 	type = 'executable',
			-- 	command = "python",
			-- 	args = { '-m'
			-- 	, 'debugpy.adapter' },
			-- }
			dap.configurations.python = {
				{
					type = "python",
					request = "launch",
					name = "Launch  File",
					program = "${file}",
					args = {}
				},
				{
					type = "python",
					request = "launch",
					name = "Launch  File1",
					program = "${file}",
					args = {}
				}
			}
		end
	}


}
