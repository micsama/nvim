# CLAUDE.md

此文件为 Claude Code (claude.ai/code) 在该代码库中工作时提供指导建议。

## 项目概述

这是一个个人 Neovim 配置仓库，专注于轻量化、可读性以及易维护性。该配置针对 **Neovim 0.13-dev Nightly** 版本设计，核心插件套件使用 `mini.nvim`，并采用 `vim.pack`（Neovim 原生插件管理）替代了 lazy.nvim 或 packer.nvim 等外部插件管理器。

**核心设计原则：**

* 在 `init.lua` 中进行声明式插件管理
* 模块化的配置组织架构
* 通过延迟/按需加载（Deferred/Lazy loading）优化启动速度
* 自定义实用组件（Floatty, Statusline, Tabline）
* 深度使用 `mini.nvim` 生态系统

## 架构与核心组件

### 配置层级

1. **init.lua** - 主入口文件
* 启用 LuaJIT 加载器
* 加载核心配置，并对 `lua/apps/` 下各功能统一调用 `setup()`
* 注册 `PackChanged` 构建钩子（`pack_builds` 表），然后通过 `vim.pack.add()` 定义所有插件
* 第二段 `vim.pack.add({...}, { load = function() end })` 只安装不加载按需插件
* 加载插件配置模块和自定义组件


2. **lua/config/** - 核心配置模块
* `base.lua`: Vim 选项 (`vim.opt`)、Shell 设置、环境变量、titlestring
* `keymaps.lua`: 全局键位映射和 `vim.g.mapleader` 定义（会删除内置 `gr*` LSP 映射，避免 `gr` 等待超时）
* `autocmds.lua`: 原生 Neovim 自动命令（项目根目录 `tcd`、光标恢复、终端 wrap + insert）
* `lsp.lua`: 诊断 UI + `vim.lsp.enable()` 服务列表（特定语言配置在 `lsp/` 目录）
* `deferred.lua`: 由 `VimEnter` 或 `FileType` 事件触发的延迟加载逻辑
* `floatty.lua`: Floatty 的用户可调选项（应用列表、快捷键、Runner、窗口、动画）
* `neovide.lua`: 针对 Neovide 客户端的特定设置


3. **lua/plugins/** - 插件配置文件（在插件注册后加载）
* `theme.lua`: catppuccin 配色与高亮覆盖（须在 `plugins.ui` 之前加载）
* `mini.lua`: mini.nvim 各模块（补全、文件、git、图标、代码片段）的详细配置
* `ui.lua`: UI 插件（nvim-notify、which-key、hlchunk、原生 UI2）
* `editor.lua`: 编辑器增强（Treesitter、匹配、Mason 按需 setup）
* `telescope.lua`: 搜索、历史和最近仓库入口（按需加载，导出 `M.load()`）
* `llm/codecompanion.lua`: CodeCompanion（deepseek 适配器，按需加载，导出 `M.load()`）


4. **lua/component/** - 自定义 UI 组件
* `statusline.lua`: 自定义状态栏
* `tabline.lua`: 自定义标签页栏
* `stldata.lua`: 状态栏数据源（git/lsp/diagnostic → 纯数据）
* `hl.lua`: statusline/tabline 共享的高亮组派生与文件图标辅助
* `util.lua`: 栏共用的文本截断/重绘调度，以及 `titlestring_file()`
* `profiler.lua`: statusline 耗时统计（`:StlProf`）


5. **lua/apps/** - 自制的独立功能（自成一体、自带 keymap，非横向复用的工具）
* **约定**：模块 `require` 时无副作用；keymap、user command、augroup（命名 `apps.<name>`）全部在 `M.setup()` 中注册，由 `init.lua` 的 apps 循环统一调用
* **`floatty/`**: **自定义浮动终端/窗口管理器**
  * `init.lua`: `setup()`（keymap / autocmd）、`statusline_segment()`（状态栏只调这一个）、`toggle` / `pick`
  * `controller.lua`: 终端生命周期；`toggle` = `resolve_target` → `hide_if_shown` → 互斥关窗 → `show_term`（→ `spawn_job`）
  * `registry.lua`: 持久会话注册表（Claude/Codex 孤儿会话续接）
  * `claude.lua`: Claude Code 会话元数据 watcher（`STATUS_GLYPHS`、`--session-id`、`-c` 续接）
  * `pulse.lua`: Claude busy 时的呼吸边框
  * 多种模式：终端、Lazygit、AI 菜单 (Codex/Claude/Shell)；**Runner 模式**根据文件类型自动选择运行命令（Python: `uv run`, Lua: `lua` 等）
* `proctop.lua`: 子进程 CPU/内存监视器（`<D-p>` / `:ProcTop`）
* `recent_repos.lua`: 最近 Git 仓库 frecency 排序与 Telescope picker；自己监听 `VimEnter` / `DirChanged` / `TabEnter`，cwd 为 git 根时计一次访问
* `zoom.lua`: 窗口最大化/恢复切换（`<D-f>`）


6. **lua/utils/** - 工具模块（被其他模块 `require` 复用的横向辅助）
* `map.lua`: 按键映射工具（处理 macOS Command 键、全角标点自动转换）
* `lazy.lua`: 按需加载辅助：`once(fn)` 只执行一次；`on_cmd(names, load)` 注册占位命令，首次调用/补全时加载真实插件并重新派发
* `json_store.lua`: 小型 JSON 文件安全读写（`read(path, default)` / `write(path, tbl)`，临时文件 + rename 原子写入），消费者：`apps/floatty/registry`、`apps/floatty/claude`、`apps/recent_repos`


7. **lsp/** - 语言服务器配置
* 每个 LSP 服务对应一个文件（如 `basedpyright.lua`, `rust_analyzer.lua`）
* 由 `lua/config/lsp.lua` 通过 `vim.lsp.enable()` 启用


8. **ftplugin/** - 特定文件类型设置
* 按文件类型应用
* `markdown.lua` 在首个 markdown/codecompanion buffer 时 `packadd` render-markdown 与 bullets


9. **snippets/** - mini.snippets 的 JSON 代码片段目录

### 插件管理

**模式：** 在 `init.lua` 中使用 `vim.pack.add()` 进行声明式列表管理

```lua
vim.pack.add({
  { src = "https://github.com/...", version = "v0.2.0" },  -- 指定版本
  "https://github.com/...",  -- 简单 URL
})
```

**注意 `vim.pack` 的限制：**

* spec 只认 `src` / `name` / `version` / `data`，**`tag`、`build` 等字段会被忽略**
* 构建步骤写在 `init.lua` 的 `pack_builds` 表中，由 `PackChanged` 钩子（kind 为 `install` / `update`）执行；钩子必须在第一次 `vim.pack.add` 之前注册
* `{ load = false }` 等同 `:packadd!`，启动时**仍会** source 插件的 `plugin/` 文件；要真正不加载，传 `{ load = function() end }`

**按需加载模式**（telescope、codecompanion 为例）：

1. 在 `init.lua` 第二段 `vim.pack.add({...}, { load = function() end })` 中声明
2. 配置模块里用 `lazy.once()` 包一个 `M.load()`：`packadd` + `setup()`
3. 键位直接调 `M.load()` 后再用插件；命令用 `lazy.on_cmd({...}, M.load)` 注册占位
4. 若插件依赖 `BufEnter` 等事件记录状态，加载后需补发一次（见 `codecompanion.lua`）

**锁文件：** `nvim-pack-lock.json` 已纳入版本控制，用于跨环境保持插件版本一致。

### 核心插件

* **mini.nvim**: 基础功能库（补全、文件浏览、git、图标、代码片段）
* **Treesitter**: 语法高亮和代码结构分析
* **CodeCompanion.nvim**: AI 辅助编程
* **Telescope**: 带有 FZF 原生扩展的模糊搜索器
* **Mason**: LSP/Linter 安装器（`mason/bin` 直接加入 PATH，UI 在首次 `:Mason*` 时 setup）

## 常见开发任务

### 查看和修改键位映射

* 位置：`lua/config/keymaps.lua`；独立功能的键位在各自 `lua/apps/*` 的 `setup()` 里
* 主 Leader 键：查看 `vim.g.mapleader` 定义

### 添加/修改插件

1. 在 `init.lua` 的 `vim.pack.add()` 中添加插件 URL（需要构建的在 `pack_builds` 加一项）
2. 如有需要，在 `lua/plugins/` 中创建相应的配置文件
3. 在 `init.lua` 底部通过 `require()` 加载该配置模块
4. 重启 Neovim

### 添加独立功能（app）

1. 新建 `lua/apps/<name>.lua`（复杂的用 `lua/apps/<name>/init.lua` 目录模块）
2. 导出 `M.setup()`，在其中注册 keymap / 命令 / augroup，`require` 时不做任何事
3. 把名字加进 `init.lua` 的 apps 列表

### 为新语言配置 LSP

1. 创建包含服务器配置的 `lsp/语言名称.lua`
2. 在 `lua/config/lsp.lua` 的 `vim.lsp.enable()` 列表中加入
3. 可能还需要在 `ftplugin/` 中添加相关的语言配置

### 添加/修改 UI 组件

* 状态栏：`lua/component/statusline.lua`（floatty 片段由 `apps.floatty.statusline_segment()` 提供）
* 标签页栏：`lua/component/tabline.lua`
* 两者均通过各自的 `setup()` 设置 `vim.o.statusline` 和 `vim.o.tabline`

### 使用 Floatty（自定义终端）

* 通过快捷键启动不同模式：`<D-g>`（终端）、`<D-i>`（Lazygit）、`<D-e>`（AI/Shell 菜单，`<M-e>` 选择器）、`<D-r>`（Runner 运行）
* Runner 会自动识别文件类型并执行代码（定义在 `lua/config/floatty.lua` 的 `runners` 表中）
* 常改选项在 `lua/config/floatty.lua`；实现在 `lua/apps/floatty/`

### 修改 Vim 选项

* 位置：`lua/config/base.lua`
* 通过 `vim.opt.*` 设置标准选项
* 包含部分系统相关设置（Python 路径、Shell、环境变量）

## 重要注意事项

1. **Neovim 版本要求**：必须使用 Neovim 0.13-dev Nightly（使用了原生 `vim.pack`、`vim._core.ui2` 等特性）。
2. **启动优化**：LSP 和部分插件通过 `lua/config/deferred.lua` 延迟到 `VimEnter` / `FileType`；telescope、codecompanion、markdown 插件、Mason 按需加载（见上文）。改动后可用 `nvim --startuptime` 对比，当前基线约 50ms。
3. **macOS 特性**：
* 默认使用 `nu` (Nushell)（在 `base.lua` 中设置）
* `utils/map.lua` 中的 Command 键映射处理 macOS 的 `<D-key>` 语法
* PATH 路径包含 Homebrew 默认位置


4. **插件锁文件**：`nvim-pack-lock.json` 控制插件版本。在 `init.lua` 中更改插件版本时请同步更新。
5. **自定义组件**：状态栏和标签栏是自定义实现的，并非 Lualine 等标准插件。
6. **无外部插件管理器**：本配置使用 Neovim 原生插件管理，请勿添加 lazy.nvim、packer 或其他外部管理器。
7. **undo/swap/backup**：使用 Neovim 默认的 `stdpath("state")` 目录，不在仓库内。

## 文件组织规范

* 保持配置模块化：`lua/config/` 中的每个文件只负责一项职责
* 插件配置放在 `lua/plugins/`，文件名应与插件用途匹配
* 特定语言的 LSP 配置放在 `lsp/` 目录
* 横向复用的工具放在 `lua/utils/`（被其他模块 `require` 的辅助，如 `map`、`lazy`、`json_store`）
* 自成一体、自带 keymap 的独立功能放在 `lua/apps/`（如 `floatty/`、`proctop`、`recent_repos`、`zoom`），遵守 `setup()` 约定
* 自定义 UI 组件放在 `lua/component/`；组件不直接依赖 app 内部实现，只调用 app 暴露的接口
* 特定文件类型的设置放在 `ftplugin/`，以文件类型命名

## 本地测试更改

由于这是 Neovim 配置（非编译项目），测试方法如下：

1. 重启 Neovim 应用配置（不使用部分 source 重载）
2. 对于插件更改，可能需要完全重启 Neovim
3. 使用 `:messages` 查看错误或使用 `:checkhealth` 进行健康检查
4. 可用 headless 快速自检：`nvim --headless +"luafile <绝对路径>" +qa!`（注意 BufEnter 会 `tcd` 到项目根，脚本和输出路径要写绝对路径）
