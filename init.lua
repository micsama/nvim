-- ===========================================================================
-- Neovim 主配置文件 (init.lua)
-- 负责加载 LuaJIT 模块、基础配置、快捷键以及所有插件
-- ===========================================================================
vim.loader.enable() -- 启用 LuaJIT 加载器，优化启动速度

-- 1. 加载核心配置
require("config.base") -- 加载基础 Vim/Neovim 选项配置
require("config.keymaps") -- 加载全局键盘快捷键映射
require("config.autocmds") -- 纯内置自动命令
-- 自制独立功能：require 时无副作用，keymap / 命令 / augroup 都在各自的 setup() 里
-- floatty 浮窗终端 · proctop 进程监控 · zoom 窗口放大 · recent_repos 最近仓库
for _, app in ipairs({ "floatty", "proctop", "zoom", "recent_repos" }) do
	require("apps." .. app).setup()
end

-- 2. GUI 客户端特定配置
if vim.g.neovide then
	require("config.neovide") -- 仅在 Neovide 环境下加载 GUI 特有配置
end


-- stylua: ignore start

-- 3. 插件管理：使用 vim.pack.add 定义所有插件列表，方便统一管理，都放一起。
-- vim.pack 的 spec 只认 src/name/version/data，构建步骤要靠 PackChanged 钩子执行；
-- 必须在第一次 vim.pack.add 之前注册，首次安装时才会触发。
local pack_builds = {
    ["telescope-fzf-native.nvim"] = function(path) vim.system({ "make" }, { cwd = path }) end,
    ["nvim-treesitter"] = function(_, active)
        if not active then vim.cmd.packadd("nvim-treesitter") end
        vim.cmd("TSUpdate")
    end,
}
vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(ev)
        local build = pack_builds[ev.data.spec.name]
        if build and (ev.data.kind == "install" or ev.data.kind == "update") then
            build(ev.data.path, ev.data.active)
        end
    end,
})

vim.pack.add({
    "https://github.com/nvim-treesitter/nvim-treesitter",
    "https://github.com/nvim-mini/mini.nvim",                        -- mini.nvim(具体配置见mini.lua)

    -- A. 核心依赖 & 基础工具 (Core Dependencies & Utilities)
    "https://github.com/nvim-lua/plenary.nvim",                      -- Lua 基础工具库，许多插件依赖(6个月没更新)
    "https://github.com/kkharji/sqlite.lua",                         -- SQLite 数据库支持 (如 Neoclip 依赖)

    -- B. UI / 外观 / 状态栏 (UI / Appearance / Statusline)
    "https://github.com/catppuccin/nvim",                            -- 主题色
    "https://github.com/folke/which-key.nvim",                       -- 快捷键提示系统

    "https://github.com/rcarriga/nvim-notify",                       -- 通知系统

    -- D. 编辑器增强与生产力 (Editing Enhancements & Productivity)
    "https://github.com/SUSTech-data/wildfire.nvim",                 -- 支持按回车键范围选择
    "https://github.com/nvim-treesitter/nvim-treesitter-context",    -- Treesitter 上下文显示
    "https://github.com/shellRaining/hlchunk.nvim",                  -- 高亮当前代码块/缩进块
    "https://github.com/mbbill/undotree",                            -- 可视化撤销树
    "https://github.com/AckslD/nvim-neoclip.lua",                    -- 剪贴板历史管理器
    "https://github.com/windwp/nvim-ts-autotag",                     -- HTML/JSX 标签自动闭合/重命名

    -- E. 文件管理与工作区 (File Management & Workspaces)
    "https://github.com/pteroctopus/faster.nvim",                    -- 大型文件优化处理

    -- 语言工具安装器（setup 延迟到首次 :Mason*，见 plugins/editor.lua）
    "https://github.com/williamboman/mason.nvim",
})

-- 只安装、完全不加载：load=false 等同 :packadd!（仍会在启动时 source plugin/），故传空函数；首次使用时再 packadd
vim.pack.add({
    -- Telescope + FZF 排序器（见 plugins/telescope.lua）
    "https://github.com/nvim-telescope/telescope.nvim",
    "https://github.com/nvim-telescope/telescope-fzf-native.nvim",
    -- LLM/AI 代码伴侣工具（见 plugins/llm/codecompanion.lua）
    "https://github.com/olimorris/codecompanion.nvim",
    -- Markdown（见 ftplugin/markdown.lua）
    "https://github.com/kaymmm/bullets.nvim",                        -- Markdown 列表增强
    "https://github.com/MeanderingProgrammer/render-markdown.nvim",  -- Markdown 实时渲染/预览
}, { load = function() end })
-- stylua: ignore end
require("plugins.theme") -- 主题（须在 plugins.ui 之前加载，notify 等插件的高亮依赖当前 colorscheme）
require("plugins.editor") -- 编辑器增强功能
require("plugins.ui") -- 用户界面和外观
require("plugins.telescope") -- 搜索与项目导航（按需加载）
require("plugins.llm.codecompanion") -- AI 聊天（按需加载）
require("plugins.mini") -- 配置 mini家族的 核心插件
require("config.deferred") -- 依赖插件的延迟加载
require("component.stldata").setup()
require("component.statusline").setup()
require("component.tabline").setup()

