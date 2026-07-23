# CLAUDE.md

此文件为 Claude Code (claude.ai/code) 在该代码库中工作时提供指导建议。

## 项目概述

这是一个个人 Neovim 配置仓库，专注于轻量化、可读性以及易维护性。该配置针对 **Neovim 0.12 Nightly** 版本设计，核心插件套件使用 `mini.nvim`，并采用 `vim.pack.add`（Neovim 0.12 原生插件管理）替代了 lazy.nvim 或 packer.nvim 等外部插件管理器。

**核心设计原则：**

* 在 `init.lua` 中进行声明式插件管理
* 模块化的配置组织架构
* 通过延迟/延迟加载（Deferred/Lazy loading）优化启动速度
* 自定义实用组件（Floatty, Statusline, Tabline）
* 深度使用 `mini.nvim` 生态系统

## 架构与核心组件

### 配置层级

1. **init.lua** - 主入口文件
* 启用 LuaJIT 加载器
* 加载核心配置和插件定义
* 通过 `vim.pack.add()` 定义所有插件（含 URL 和构建脚本）
* 注册插件配置模块和自定义组件


2. **lua/config/** - 核心配置模块
* `base.lua`: Vim 选项 (`vim.opt`)、Shell 设置、环境变量
* `keymaps.lua`: 全局键位映射和 `vim.g.mapleader` 定义
* `autocmds.lua`: 原生 Neovim 自动命令
* `lsp.lua`: LSP 客户端设置（从 `lsp/` 目录加载特定语言配置）
* `deferred.lua`: 由 `VimEnter` 或 `FileType` 事件触发的延迟加载逻辑
* `neovide.lua`: 针对 Neovide 客户端的特定设置


3. **lua/plugins/** - 插件配置文件（在插件注册后加载）
* `mini.lua`: mini.nvim 各模块（补全、文件、git、图标、代码片段）的详细配置
* `ui.lua`: UI 插件（Notify, Noice, which-key 等）
* `editor.lua`: 编辑器增强（Treesitter, 匹配, 缩进）
* `llm/`: AI/LLM 工具（CodeCompanion, GPT5, Ollama-Qwen3）
* `dap.lua`: 调试适配器协议（DAP）设置


4. **lua/component/** - 自定义 UI 组件
* `statusline.lua`: 自定义状态栏
* `tabline.lua`: 自定义标签页栏
* `theme.lua`: 配色方案配置
* `stldata.lua`: 状态栏数据源（git/lsp/diagnostic → 纯数据）
* `hl.lua`: statusline/tabline 共享的高亮组派生与文件图标辅助


5. **lua/apps/** - 自制的独立功能（自成一体、自带 keymap，非横向复用的工具）
* **`floatty.lua`**: **自定义浮动终端/窗口管理器**，支持：
* 多种模式：终端、Lazygit、AI 聊天 (Codex/Gemini/Claude)、Shell
* **Runner 模式**: 根据文件类型自动选择运行命令（Python: `uv run`, Lua: `lua` 等）


* `proctop.lua`: 子进程 CPU/内存监视器（`<D-p>` / `:ProcTop`）
* `recent_repos.lua`: 最近 Git 仓库 frecency 排序与 Telescope picker
* `zoom.lua`: 窗口最大化/恢复切换


6. **lua/utils/** - 工具模块（被其他模块 `require` 复用的横向辅助）
* `map.lua`: 按键映射工具（处理 macOS Command 键、全角标点自动转换）
* `floatty_claude.lua`: 给 `apps/floatty.lua` 用的 Claude 会话元数据映射（watcher）
* `json_store.lua`: 小型 JSON 文件安全读写（`read(path, default)` / `write(path, tbl)`），消费者：`apps/floatty`、`apps/recent_repos`、`utils/floatty_claude`


7. **lsp/** - 语言服务器配置
* 每个 LSP 服务对应一个文件（如 `basedpyright.lua`, `rust_analyzer.lua`）
* 由 `lua/config/lsp.lua` 动态加载


8. **ftplugin/** - 特定文件类型设置
* 按文件类型应用
* 适当时可通过 `vim.pack.add` 加载额外插件


9. **snippets/** - mini.snippets 的 JSON 代码片段目录

### 插件管理

**模式：** 在 `init.lua` 中使用 `vim.pack.add()` 进行声明式列表管理

```lua
vim.pack.add({
  { src = "https://github.com/...", tag = "v0.2.0" },  -- 指定版本
  { src = "https://github.com/...", build = "make" },  -- 指定构建命令
  "https://github.com/...",  -- 简单 URL
})

```

**锁文件：** `nvim-pack-lock.json` - 用于跨环境保持插件版本一致。

### 核心插件

* **mini.nvim**: 基础功能库（补全、文件浏览、git、图标、代码片段）
* **Treesitter**: 语法高亮和代码结构分析
* **CodeCompanion.nvim**: AI 辅助编程
* **Telescope**: 带有 FZF 原生扩展的模糊搜索器
* **Mason**: LSP/DAP/Linter 安装器

## 常见开发任务

### 查看和修改键位映射

* 位置：`lua/config/keymaps.lua`
* 主 Leader 键：查看 `vim.g.mapleader` 定义

### 添加/修改插件

1. 在 `init.lua` 的 `vim.pack.add()` 中添加插件 URL
2. 如有需要，在 `lua/plugins/` 中创建相应的配置文件
3. 在 `init.lua` 底部通过 `require()` 加载该配置模块
4. 重启 Neovim

### 为新语言配置 LSP

1. 创建包含服务器配置的 `lsp/语言名称.lua`
2. 确保 `lua/config/lsp.lua` 加载该文件（通常为自动发现）
3. 可能还需要在 `ftplugin/` 中添加相关的语言配置

### 添加/修改 UI 组件

* 状态栏：`lua/component/statusline.lua`
* 标签页栏：`lua/component/tabline.lua`
* 两者均在 `init.lua` 中通过 `vim.o.statusline` 和 `vim.o.tabline` 注册

### 使用 Floatty（自定义终端）

* 通过快捷键启动不同模式：`<D-g>`（终端）、`<D-i>`（Lazygit）、`<D-e>`（AI/Shell 菜单）、`<D-r>`（Runner 运行）
* Runner 会自动识别文件类型并执行代码（定义在 `floatty.lua` 的 `RUNNERS` 表中）
* 详见 `lua/apps/floatty.lua` 的配置及选项

### 修改 Vim 选项

* 位置：`lua/config/base.lua`
* 通过 `vim.opt.*` 设置标准选项
* 包含部分系统相关设置（Python 路径、Shell、环境变量）

## 重要注意事项

1. **Neovim 版本要求**：必须使用 Neovim 0.12 Nightly 或更高版本（使用了原生 `vim.pack.add` 等特性）。
2. **启动优化**：LSP 和大型插件通过 `lua/config/deferred.lua` 延迟加载，以提升启动速度。它们会在 `VimEnter` 或特定的 `FileType` 事件中加载。
3. **macOS 特性**：
* 默认使用 `nu` (Nushell)（在 `base.lua` 中设置）
* `utils/map.lua` 中的 Command 键映射处理 macOS 的 `<D-key>` 语法
* PATH 路径包含 Homebrew 默认位置


4. **插件锁文件**：`nvim-pack-lock.json` 控制插件版本。在 `init.lua` 中更改插件版本时请同步更新。
5. **自定义组件**：状态栏和标签栏是自定义实现的，并非 Lualine 等标准插件。
6. **无外部插件管理器**：本配置使用 Neovim 原生插件管理，请勿添加 lazy.nvim、packer 或其他外部管理器。

## 文件组织规范

* 保持配置模块化：`lua/config/` 中的每个文件只负责一项职责
* 插件配置放在 `lua/plugins/`，文件名应与插件用途匹配
* 特定语言的 LSP 配置放在 `lsp/` 目录
* 横向复用的工具放在 `lua/utils/`（被其他模块 `require` 的辅助，如 `map`、`floatty_claude`、`json_store`）
* 自成一体、自带 keymap 的独立功能放在 `lua/apps/`（如 `floatty`、`proctop`、`recent_repos`、`zoom`）
* 自定义 UI 组件放在 `lua/component/`
* 特定文件类型的设置放在 `ftplugin/`，以文件类型命名

## 本地测试更改

由于这是 Neovim 配置（非编译项目），测试方法如下：

1. 重启 Neovim 或使用 `:source $MYVIMRC` 重新加载配置
2. 对于插件更改，可能需要完全重启 Neovim
3. 使用 `:messages` 查看错误或使用 `:checkhealth` 进行健康检查
