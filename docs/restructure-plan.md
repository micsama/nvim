# 架构重组方案（第三部分，待执行）

> 记录于 2026-09-23。第一 / 二 / 四部分（bug 修复、启动性能、逻辑小修）已完成，本文件只记录**尚未动手**的结构性重组。
> 原则：每一步独立可提交、可回退；每步做完重启 nvim 验证（不做部分 source）。

## 现状问题一览

| 问题 | 位置 |
|---|---|
| floatty 分散在 4 个文件、跨 3 个目录 | `apps/floatty.lua`(657 行) `apps/floatty_registry.lua` `utils/floatty_claude.lua` `config/floatty.lua` |
| floatty 在 `require` 时就注册 keymap / autocmd（副作用） | `apps/floatty.lua:604-655`，`init.lua:11` |
| `M.toggle` 单函数约 200 行 | `apps/floatty.lua:326` |
| app 入口不统一：有的 `setup()`，有的靠 require 副作用，有的 keymap 定义在别处 | `init.lua:11-12`、`plugins/mini.lua:153`（zoom 的 `<D-f>`） |
| statusline 直接依赖 floatty 内部实现 | `component/statusline.lua:9-10, 217-227` |
| `autocmds.lua` 反向调用 recent_repos | `config/autocmds.lua:34` |
| recent_repos 在 require 时注册全局 TermClose | `apps/recent_repos.lua:195` |
| floatty 顺手设置了全局 TermOpen `wrap=true` | `apps/floatty.lua:651` |
| `_G.titlestring_file` 全局函数 | `config/base.lua:42` |
| 主题是插件配置却放在 component/ | `component/theme.lua` |
| CLAUDE.md 过时 | 见第 5 节 |

## 1. floatty 收拢为目录模块

```
lua/apps/floatty/
  init.lua        -- setup()：keymap、autocmd（VimResized / WinClosed）、对外 API 再导出
  controller.lua  -- toggle / pick / kill / idle 定时器；把 M.toggle 拆成
                  --   resolve_cfg() → ensure_term() → open_win() → after_open()
  registry.lua    -- 原 apps/floatty_registry.lua
  claude.lua      -- 原 utils/floatty_claude.lua（会话元数据 watcher、STATUS_GLYPHS）
  pulse.lua       -- 呼吸边框（原 hex_from_hl / pulse_base_color / blend / start_pulse / stop_pulse，约 80 行）
```

- `lua/config/floatty.lua` **保留**，作为用户可调选项（APPS / RUNNERS 等）。
- `require("apps.floatty")` 的调用方不用改，目录下的 `init.lua` 会自动被找到。
- `utils/floatty_claude` 的引用方：statusline（第 3 节会去掉）、floatty 本体。改完之后 `grep -rn floatty_claude` 应该一个都不剩。
- `json_store` 的消费者列表（CLAUDE.md 里）同步更新。

## 2. 统一 app 入口：`setup()`

约定：`lua/apps/*` 的模块在 require 时**没有任何副作用**，所有 keymap、user command、augroup 都在 `M.setup()` 里注册，augroup 统一命名 `apps.<name>`，并带 `clear = true`。

`init.lua` 改为：

```lua
for _, app in ipairs({ "floatty", "proctop", "zoom", "recent_repos" }) do
	require("apps." .. app).setup()
end
```

逐个 app 的改动：
- **floatty**：把 `apps/floatty.lua:604-649` 移进 `setup()`。
- **zoom**：`<D-f>` 从 `plugins/mini.lua:153` 移到 `zoom.setup()`。
- **recent_repos**：TermClose 自动命令（`:195`）移进 `setup()`；DirChanged 的处理见第 3 节。
- **proctop**：已经有 `setup()`，只需核对一下 require 时有没有副作用。

## 3. 解耦

### statusline ↔ floatty
- 由 floatty 暴露 `require("apps.floatty").statusline_segment()`，直接返回拼好的 statusline 字符串（或 `{text, hl}` 列表）。
- glyph（`STATUS_GLYPHS`）、`active_menu_indices` / `orphan_menu_indices` 的组合逻辑都放到 floatty 内部。
- 这样 `component/statusline.lua` 只需一行 `pcall(require, "apps.floatty")`，删掉对 `utils.floatty_claude` 的依赖。

### autocmds ↔ recent_repos
- 现状：`autocmds.lua` 的 BufEnter 算出项目根目录后，调用 `recent_repos.enter(git_root or nil)`。
- 目标：recent_repos 在 `setup()` 里自己监听 `DirChanged`，拿到新的 cwd 后用 `vim.fs.root(cwd, ".git") == cwd` 判断它是不是 git 根。
- **需要保留的语义**：离开仓库（切到非 git 目录）时要重置 `active_repo`，这样回到原仓库时会重新计数。另外 `M.open()` 里显式调用了 `record()`，要避免同一次打开被计两次（`enter` 已经用 `active_repo` 去重，确认一下即可）。
- 做完之后，`autocmds.lua` 只负责 `tcd`，不再知道 recent_repos 的存在。

## 4. 零碎挪位

- `component/theme.lua` → `plugins/theme.lua`（它是 catppuccin 的配置，不是自定义组件）。要同步修改 `init.lua` 的 require，以及 CLAUDE.md。
- `_G.titlestring_file` → 改成模块函数，例如放在 `component/util.lua`，titlestring 里用 `%{%v:lua.require'component.util'.titlestring_file()%}`。
- floatty 里的全局 TermOpen `wrap=true`（`apps/floatty.lua:651`）→ 移到 `config/autocmds.lua`，和 `startinsert` 那条 TermOpen 放在一起。

## 5. 更新 CLAUDE.md（当前已过时）

- 删掉已经不存在的 Noice、GPT5、Ollama-Qwen3。
- 版本要求：0.12 → 0.13-dev nightly。
- 插件管理的示例改成：`vim.pack` 的 spec 只认 `src / name / version / data`，`tag=` 要改成 `version = "v0.2.0"`，`build` 字段**不生效**。
- 补充几条说明：
  - 构建步骤放在 `init.lua` 的 `pack_builds` 表里，由 `PackChanged` 钩子执行，钩子必须在第一次 `vim.pack.add` 之前注册。
  - 按需加载的写法：第二段 `vim.pack.add({...}, { load = function() end })` 只安装不加载（注意 `load = false` 相当于 `:packadd!`，启动时仍会 source `plugin/`），配合 `utils/lazy.lua` 的 `once()` / `on_cmd()` 做命令 stub。
  - `utils/lazy.lua` 要写进 utils 列表。
- 目录说明要同步第 1、2、4 节改完后的结构（`apps/floatty/`、`plugins/theme.lua`、app `setup()` 约定）。
- 加上一句：`nvim-pack-lock.json` 已纳入版本控制。

## 6. 可选

- 用 `mini.indentscope` 替换 hlchunk.nvim：hlchunk 启动约 6ms（`chunk` 模块 + `ts_node_type`），mini 已经是依赖，少一个插件。缺点是没有 hlchunk 那种折角线的效果，要看个人喜好。
- `plugins/ui.lua` 里的 nvim-notify（约 5ms）可以考虑延迟到 `VimEnter` 之后再 setup，或者直接用 `vim._core.ui2` / `mini.notify`。

## 建议执行顺序

1 → 2 → 3 → 4 → 5（6 另议）。第 1、2 步最好一起做，因为 floatty 拆目录时顺手就把 `setup()` 抽出来了。
