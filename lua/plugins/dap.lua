-- ============================================================================
-- 模块引入
-- ============================================================================
local map = require('util.utils').map
local dap = require('dap')
local dapui = require('dapui')

-- ============================================================================
-- DAP UI 和 Adapter 基础设置
-- ============================================================================

-- DAP 辅助插件设置
require('mason').setup()
require('nvim-dap-virtual-text').setup()
require('mason-nvim-dap').setup({ ensure_installed = { 'python' } })
require('dap-python').setup('python')
dapui.setup()

-- ============================================================================
-- 调试器图标和高亮设置
-- ============================================================================

-- 设置高亮颜色
vim.api.nvim_set_hl(0, 'DapBreakpoint', { fg = '#993939', bg = '#31353f' })
vim.api.nvim_set_hl(0, 'DapLogPoint', { fg = '#61afef', bg = '#31353f' })
vim.api.nvim_set_hl(0, 'DapStopped', { fg = '#ffffff', bg = '#FE3C25' })

-- 定义调试器标志
local function define_sign(name, text, hl_group)
    vim.fn.sign_define(name, {
        text = text,
        texthl = hl_group,
        linehl = hl_group,
        numhl = hl_group
    })
end

define_sign('DapBreakpoint', '', 'DapBreakpoint')
define_sign('DapBreakpointCondition', 'ﳁ', 'DapBreakpoint')
define_sign('DapBreakpointRejected', '', 'DapBreakpoint')
define_sign('DapLogPoint', '', 'DapLogPoint')
define_sign('DapStopped', '', 'DapStopped')


-- ============================================================================
-- DAP UI 监听器 (自动打开/关闭 UI)
-- ============================================================================

-- 在 attach/launch 前打开 UI
dap.listeners.before.attach.dapui_config = dapui.open
dap.listeners.before.launch.dapui_config = dapui.open
-- 在 terminated/exited 后关闭 UI
dap.listeners.before.event_terminated.dapui_config = dapui.close
dap.listeners.before.event_exited.dapui_config = dapui.close


-- ============================================================================
-- DAP 快捷键设置
-- ============================================================================

-- <f5> 启动调试 (先保存文件，然后弹出配置选择)
map('nv', '<f5>', ':up<CR>:Telescope dap configurations<CR>', 'start debug')
map('nv', '<F10>', dap.step_over, 'DAP Step Over')
map('nv', '<F11>', dap.step_into, 'DAP Step Into')
map('nv', '<F12>', dap.step_out, 'DAP Step Out')
map('nv', '<Leader>b', dap.toggle_breakpoint, 'DAP Toggle Breakpoint')
map('nv', '<Leader>B', dap.set_breakpoint, 'DAP Set Breakpoint')

-- 设置 Log Point (带输入框)
map('nv', '<Leader>lp', function()
	dap.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))
end, 'DAP Set Log Point')

-- 其他 UI 和 REPL 快捷键
map('nv', '<Leader>dr', dap.repl.open, 'DAP Open REPL')
map('nv', '<Leader>dl', dap.run_last, 'DAP Run Last')
map('nv', '<Leader>dh', require('dap.ui.widgets').hover, 'DAP Hover')
map('nv', '<Leader>dp', require('dap.ui.widgets').preview, 'DAP Preview')
-- 居中浮动窗口：Frames
map('nv', '<Leader>df', function()
	require('dap.ui.widgets').centered_float(require('dap.ui.widgets').frames)
end, 'DAP Frames')
-- 居中浮动窗口：Scopes
map('nv', '<Leader>ds', function()
	require('dap.ui.widgets').centered_float(require('dap.ui.widgets').scopes)
end, 'DAP Scopes')

-- ============================================================================
-- DAP 调试配置
-- ============================================================================

-- Python 调试配置 (启动当前文件)
dap.configurations.python = {
	{
		type = 'python',
		request = 'launch',
		name = 'Launch File',
		program = '${file}',
		args = {'--prefix','test'}
	}
}

-- 加载 Telescope 的 DAP 扩展
require('telescope').load_extension('dap')
