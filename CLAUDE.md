# Neovim 配置项目上下文 (Claude Context)

这是一个用于个人日常开发的 Neovim 配置，主要设计理念是轻量、可读和易维护。该配置专为 Neovim 0.12 Nightly 版本设计，并大量使用了 `mini.nvim` 套件。

## 项目概览

- **项目类型:** Neovim 配置文件 (Lua)
- **目标版本:** Neovim Nightly 0.12+
- **核心理念:** 集中式插件管理，模块化配置，自定义工具链 (Floatty)，延迟加载优化。

## 目录结构详解

- `init.lua`: **配置入口**。负责启用 LuaJIT 加载器，加载核心配置，并通过 `vim.pack.add` 集中定义所有插件列表。
- `lua/config/`: 核心配置模块。
  - `base.lua`: 基础 Vim 选项设置 (`vim.opt`)。
  - `keymaps.lua`: 全局快捷键映射及 `vim.g.mapleader` 定义。
  - `autocmds.lua`: 自动命令配置（如自动切换工作目录、恢复光标位置）。
  - `deferred.lua`: 延迟加载逻辑，用于在 `VimEnter` 或 `FileType` 事件后加载 LSP 和重型插件。
  - `lsp.lua`: LSP 配置的主入口文件。
  - `neovide.lua`: Neovide GUI 客户端的特定设置。
- `lua/plugins/`: 插件的具体配置文件（在 `init.lua` 添加插件后加载）。
  - `mini.lua`: `mini.nvim` 全家桶的详细配置（补全、Surround、Files、Git 等）。
  - `ui.lua`: 界面相关插件配置（Notify, Noice, Dropbar 等）。
  - `editor.lua`: 编辑增强插件配置（Treesitter, Matchup 等）。
  - `llm/`: LLM/AI 工具配置 (CodeCompanion, GPT5 等)。
- `lua/component/`: 自定义 UI 组件。
  - `statusline.lua`: 自定义状态栏。
  - `tabline.lua`: 自定义标签栏。
- `lua/utils/`: 通用工具模块。
  - `floatty.lua`: **自定义浮动终端管理器**。支持 Terminal、Lazygit、Runner、AI Chat 等模式。
  - `map.lua`: 快捷键辅助工具，处理 macOS 的 Command 键映射及全角符号自动转半角。
  - `zoom.lua`: 窗口最大化/恢复切换工具。
- `lsp/`: 独立的 LSP 服务器配置文件（如 `basedpyright.lua`, `rust_analyzer.lua`）。
- `ftplugin/`: 特定文件类型的设置。
- `snippets/`: `mini.snippets` 使用的 JSON 格式代码片段。

## 关键技术与模式

### 1. 插件管理 (`vim.pack.add`)

- **机制:** 不依赖传统第三方插件管理器（如 lazy.nvim 或 packer），使用 Neovim 0.12+ 的原生 `vim.pack.add`。
- **定义:** 所有插件在 `init.lua` 中集中声明。
- **锁定:** `nvim-pack-lock.json` 用于版本锁定。

### 2. 核心插件体系

- **`mini.nvim`**: 承担大部分基础功能，包括补全、文件浏览、Git 集成、图标、代码片段等。
- **`codecompanion.nvim`**: AI 辅助编程。
- **`treesitter`**: 语法高亮和代码结构解析。

### 3. 自定义工具 (Utils)

- **Floatty (`lua/utils/floatty.lua`)**: 浮动窗口管理器。Runner 模式根据文件类型自动选择命令（Python 用 `uv run`，Lua 用 `lua`，Rust 用 `cargo run`）。
- **按键映射 (`lua/utils/map.lua`)**: 自动识别 macOS，处理 `<D-key>` 映射，提供全角转半角功能。

## 开发指南

- **修改通用选项:** `lua/config/base.lua`
- **修改快捷键:** `lua/config/keymaps.lua`
- **添加/删除插件:** 修改 `init.lua` 中的 `vim.pack.add` 列表，并在 `lua/plugins/` 下添加对应配置。
- **LSP 设置:** 在 `lsp/` 目录下添加新服务器配置文件。

## 注意事项

- 必须使用 **Neovim 0.12 Nightly** 或更高版本。
- 利用 `lua/config/deferred.lua` 实现启动优化，LSP 和重型插件延迟加载。
- 工作区使用 git worktree，当前 worktree 位于 `.claude/worktrees/determined-taussig`，主分支为 `master`。
