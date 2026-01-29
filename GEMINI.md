# Neovim 配置项目上下文 (Gemini Context)

这是一个用于个人日常开发的 Neovim 配置，主要设计理念是轻量、可读和易维护。该配置专为 Neovim 0.12 Nightly 版本设计，并大量使用了 `mini.nvim` 套件。

## 项目概览

*   **项目类型:** Neovim 配置文件 (Lua)
*   **目标版本:** Neovim Nightly 0.12+
*   **核心理念:** 集中式插件管理，模块化配置，自定义工具链 (Floatty)，延迟加载优化。

## 目录结构详解

*   `init.lua`: **配置入口**。负责启用 LuaJIT 加载器，加载核心配置，并通过 `vim.pack.add` 集中定义所有插件列表。
*   `lua/config/`: 核心配置模块。
    *   `base.lua`: 基础 Vim 选项设置 (`vim.opt`)。
    *   `keymaps.lua`: 全局快捷键映射及 `vim.g.mapleader` 定义。
    *   `autocmds.lua`: 自动命令配置（如自动切换工作目录、恢复光标位置）。
    *   `deferred.lua`: 延迟加载逻辑，用于在 `VimEnter` 或 `FileType` 事件后加载 LSP 和重型插件。
    *   `lsp.lua`: LSP 配置的主入口文件。
    *   `neovide.lua`: Neovide GUI 客户端的特定设置。
    *   `theme.lua`: 颜色主题配置。
*   `lua/plugins/`: 插件的具体配置文件（在 `init.lua` 添加插件后加载）。
    *   `mini.lua`: `mini.nvim` 全家桶的详细配置（补全、Surround、Files、Git 等）。
    *   `ui.lua`: 界面相关插件配置（Notify, Noice, Dropbar 等）。
    *   `editor.lua`: 编辑增强插件配置（Treesitter, Matchup 等）。
    *   `llm/`: LLM/AI 工具配置 (CodeCompanion, GPT5 等)。
*   `lua/component/`: 自定义 UI 组件。
    *   `statusline.lua`: 自定义状态栏。
    *   `tabline.lua`: 自定义标签栏。
*   `lua/utils/`: 通用工具模块。
    *   `floatty.lua`: **自定义浮动终端管理器**。支持普通终端、Lazygit、以及代码运行器 (Runner)。
    *   `map.lua`: 快捷键辅助工具，处理 macOS 的 Command 键映射及全角符号自动转半角。
    *   `zoom.lua`: 窗口最大化/恢复切换工具。
*   `lsp/`: 独立的 LSP 服务器配置文件 (例如 `basedpyright.lua`, `rust_analyzer.lua`)。
*   `ftplugin/`: 特定文件类型的设置 (部分文件类型特定的插件在此处通过 `vim.pack.add` 加载)。
*   `snippets/`: `mini.snippets` 使用的 JSON 格式代码片段。

## 关键技术与模式

### 1. 插件管理 (`vim.pack.add`)
*   **机制:** 本配置不依赖传统的第三方插件管理器（如 lazy.nvim 或 packer），而是使用 Neovim 0.12 Nightly 的原生（或自定义封装的）`vim.pack.add` 功能。
*   **定义:** 所有插件在 `init.lua` 中声明式列表定义。
*   **锁定:** 根目录下有 `nvim-pack-lock.json` 文件用于版本锁定。

### 2. 核心插件体系
*   **`mini.nvim`**: 承担了大部分基础功能，包括代码补全 (`mini.completion`)、文件浏览 (`mini.files`)、Git 集成 (`mini.git`, `mini.diff`)、图标 (`mini.icons`) 和代码片段 (`mini.snippets`)。
*   **`codecompanion.nvim`**: 提供 AI 辅助编程能力。
*   **`treesitter`**: 提供语法高亮和代码结构解析。

### 3. 自定义工具 (Utils)
*   **Floatty (`lua/utils/floatty.lua`)**: 一个轻量级但功能强大的浮动窗口管理器。
    *   支持多种模式：Terminal, Lazygit, AI Chat。
    *   **Runner 模式**: 根据当前文件类型自动选择命令运行代码 (如 Python 使用 `uv run`, Lua 使用 `lua`)。
*   **按键映射 (`lua/utils/map.lua`)**:
    *   自动识别 macOS 环境，处理 Command 键 (`<D-key>`) 映射。
    *   提供全角标点自动转半角功能（如全角冒号自动转为命令模式冒号）。

## 开发与使用指南

*   **安装:** 克隆仓库到 `~/.config/nvim`。
*   **自定义配置:**
    *   修改通用选项：编辑 `lua/config/base.lua`。
    *   修改快捷键：编辑 `lua/config/keymaps.lua`。
    *   添加/删除插件：在 `init.lua` 中的 `vim.pack.add` 列表中修改，并在 `lua/plugins/` 下添加配置。
    *   LSP 设置：在 `lsp/` 目录下添加新的服务器配置文件，并确保 `lua/config/lsp.lua` 会加载它们（通常是自动的或需手动 require）。
*   **注意事项:**
    *   必须使用 **Neovim 0.12 Nightly** 或更高版本。
    *   利用 `lua/config/deferred.lua` 实现了启动优化，LSP 和 heavy 插件通常不会在启动时立即加载。
