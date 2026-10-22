# Floatty 跨 Neovim 实例内部通知

状态：已实现。重启 Neovim，并重新启动 Floatty 中的 AI 会话后生效。

## 交互方式

使用本机共享文件，不使用 RPC / gRPC、常驻服务或系统通知。

```text
Codex / Claude 官方事件回调
          ↓
脚本原子写入事件 JSON
          ↓
当前聚焦的 Neovim 领取事件
          ↓
vim.notify / nvim-notify
```

## 用户体验

- A 实例的 AI 结束一轮，用户正在操作 B：由 B 提醒，显示应用名和项目名。
- 用户正在操作对应 AI 浮窗：本轮结束事件静默消费。
- 等待授权：WARN 提醒，即使正在对应浮窗中也不静默。
- 所有窗口在后台：先保留事件，重新聚焦时合并提醒，最多列出 5 条，授权事件优先。
- 工具执行返回后清理对应的待处理授权事件；本轮结束时清理该会话剩余授权事件。
- 通知展示约 5 秒，沿用 nvim-notify 的置顶配置和历史。

“本轮结束”不代表任务成功，也不等于进程退出。通知不替用户批准操作，不显示猜测的百分比。

## 官方事件接入

| 应用 | 完成事件 | 授权事件 | 接入范围 |
| --- | --- | --- | --- |
| Claude | Stop hook | Notification，matcher 为 permission_prompt | 默认 Claude 和自定义配置入口，含恢复会话 |
| Codex | notify 的 agent-turn-complete | PermissionRequest hook | 新会话和 resume --last |

Claude 的 permission_prompt 在实际等待约 6 秒后触发，避免对立即处理的授权重复提醒，也覆盖不触发 PermissionRequest 的沙箱网络授权。PostToolUse 用于移除已经处理的待显示授权事件。

Codex 通过启动参数将 notify 替换为本方案脚本，关闭 TUI 终端通知，不调用原有 Computer Use 通知命令。使用 --no-daemon 确保回调继承本次 Floatty 的实例环境。

**Codex 首次使用需在 `/hooks` 中信任新增 PermissionRequest 和 PostToolUse hook。** 这是 CLI 的官方信任机制；未信任时这些 hook 会被跳过，完成 notify 不依赖这一步。不使用绕过 hook 信任的参数。

Claude 使用 --settings 附加通知 hooks，保留原有业务配置。没有写入 ~/.codex/config.toml 或 Claude 全局 settings，也没有修改旧 osascript 脚本。若其他来源另行配置了系统通知，本功能不会全局删除它们。

## 文件与实例身份

每个 Neovim 使用 PID 与启动时间标识，终端在此基础上使用 buffer ID 区分，通过 jobstart 的进程级环境传给回调：

- FLOATTY_INSTANCE_ID / FLOATTY_TERM_ID：定位来源，同一项目多个实例也不会串。
- FLOATTY_APP_NAME：菜单显示名。
- FLOATTY_EVENT_DIR / FLOATTY_CWD：共享目录与来源工作目录。

事件存放于 stdpath("state")/floatty-notifications/：

- pending/：待处理 JSON；脚本先写临时文件，再原子发布。
- claimed/：已领取事件及短期去重标识。
- foreground.json：当前聚焦实例标识，防止切换窗口时旧实例继续消费。

每个实例约每秒检查一次；后台实例不扫描事件。FocusGained 立即领取，FocusLost 停止领取；初次真实按键也可确认焦点。领取通过原子重命名完成，只有领取成功的实例显示通知。依赖宿主正确上报焦点事件。

事件仅保存应用、实例、会话、项目、事件类型和时间；不落盘 prompt、回复正文、工具命令或认证信息。去重使用 turn ID 或回复/请求指纹。授权事件直接跟随官方回调，不另做时间窗口去重；重复请求仍会提醒。目录 0700、事件文件 0600。

事件保留 24 小时，聚焦时低频清理。没有任何 Neovim 打开时不提供提醒。实例恰好在领取后、显示前崩溃可能漏掉该条通知；第一版不增加确认协议。

## 代码位置

| 文件 | 职责 |
| --- | --- |
| lua/apps/floatty/notifications.lua | 聚焦状态、领取、去重、合并通知与启动参数 |
| scripts/floatty_event.py | CLI 回调转换、清理待授权事件、原子写入；只依赖 Python 标准库 |
| lua/apps/floatty/controller.lua | 注入子进程环境，标识当前 Floatty |
| lua/apps/floatty/init.lua | 注册模块与生命周期 |
| lua/config/floatty.lua | enabled、poll_ms、timeout_ms、retention_s |

旧会话恢复注册表的格式不变；文件读取不进入 statusline 渲染路径。回调输出保持为空，不返回授权决定，不调用模型 API。

## 验证与边界

已使用本地模拟事件检查：双实例领取、焦点切换、同浮窗静默、授权提醒、去重、批量汇总、并发发布和恢复会话参数。Codex 生成的配置覆盖已通过本机 CLI 解析。未调用真实模型或发系统通知。临时测试文件已按要求删除。

CLI 升级、业务 hook、宿主焦点事件仍可能影响实际回调；Codex 权限通知需先完成上述官方信任步骤。

## 参考

- [Codex notify 配置](https://learn.chatgpt.com/docs/config-file/config-reference)
- [Codex hooks 与信任要求](https://learn.chatgpt.com/docs/hooks)
- [Claude Code hooks](https://code.claude.com/docs/en/hooks)
