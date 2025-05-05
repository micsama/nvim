local now, add, later = MiniDeps.now, MiniDeps.add, MiniDeps.later


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
    vim.fn.sign_define('DapLogPoint',
        { text = '', texthl = 'DapLogPoint', linehl = 'DapLogPoint', numhl = 'DapLogPoint' })
    vim.fn.sign_define('DapStopped', { text = '', texthl = 'DapStopped', linehl = 'DapStopped', numhl = 'DapStopped' })
end

local function set_dap_keys()
    local map = require("util.utils").map
    map("nv", "<f5>", ":up<CR>:Telescope dap configurations<CR>", "start debug")
    map("nv", "<F10>", function() require('dap').step_over() end, "DAP Step Over")
    map("nv", "<F11>", function() require('dap').step_into() end, "DAP Step Into")
    map("nv", "<F12>", function() require('dap').step_out() end, "DAP Step Out")
    map("nv", "<Leader>b", function() require('dap').toggle_breakpoint() end, "DAP Toggle Breakpoint")
    map("nv", "<Leader>B", function() require('dap').set_breakpoint() end, "DAP Set Breakpoint")
    map("nv", "<Leader>lp", function() require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end,
        "DAP Set Log Point")
    map("nv", "<Leader>dr", function() require('dap').repl.open() end, "DAP Open REPL")
    map("nv", "<Leader>dl", function() require('dap').run_last() end, "DAP Run Last")
    map("nv", "<Leader>dh", function() require('dap.ui.widgets').hover() end, "DAP Hover")
    map("nv", "<Leader>dp", function() require('dap.ui.widgets').preview() end, "DAP Preview")
    map("nv", "<Leader>df", function() require('dap.ui.widgets').centered_float(require('dap.ui.widgets').frames) end,
        "DAP Frames")
    map("nv", "<Leader>ds", function() require('dap.ui.widgets').centered_float(require('dap.ui.widgets').scopes) end,
        "DAP Scopes")
end

-- 设置 DAP UI 的监听器
local function set_dap_ui_listeners(dap, dapui)
    dap.listeners.before.attach.dapui_config = function() dapui.open() end
    dap.listeners.before.launch.dapui_config = function() dapui.open() end
    dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
    dap.listeners.before.event_exited.dapui_config = function() dapui.close() end
end

later(function()
    add("mfussenegger/nvim-dap")
    add("mfussenegger/nvim-dap-python")
    add("jay-babu/mason-nvim-dap.nvim")
    add("williamboman/mason.nvim")
    add("theHamsta/nvim-dap-virtual-text")
    add({
        source = "rcarriga/nvim-dap-ui",
        depends = { 
            "nvim-telescope/telescope-dap.nvim",
            "nvim-neotest/nvim-nio" }
    })
    local dap = require("dap")
    local dapui = require("dapui")

    -- 设置 DAP UI
    require("mason").setup()
    require("nvim-dap-virtual-text").setup()
    require("mason-nvim-dap").setup({ ensure_installed = { "python" } })
    require("dap-python").setup("python")
    dapui.setup()

    -- 设置 DAP UI 监听器
    set_dap_ui_listeners(dap, dapui)
    set_dap_keys()
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
        }
    }

    -- 加载 Telescope 的 DAP 扩展
    require('telescope').load_extension('dap')
end)
