# 从头开始的个人 Nvim 配置

这是我用于日常开发的 Neovim 配置，偏向轻量、可读、易维护。
最开始入门时受到 @theniceboy 启发：  
[theniceboy 的 Neovim 配置](https://github.com/theniceboy/nvim/tree/lua-migration)

## 目录结构

- `init.lua`：入口配置
- `lua/`：核心配置与模块
- `lsp/`：语言服务相关配置
- `ftplugin/`：按文件类型加载的设置
- `snippets/`：代码片段
- `nvim-pack-lock.json`：插件锁定文件
- `tmp/`：临时文件

## 依赖

- Neovim nightly 0.12

## 安装

1. 备份原有配置
   ```bash
   mv ~/.config/nvim ~/.config/nvim.bak
   ```
2. 克隆本仓库
   ```bash
   git clone <repo-url> ~/.config/nvim
   ```
3. 启动 Neovim
   ```bash
   nvim
   ```

> 如果你配置了插件管理器，请根据其提示完成首次安装。

## 使用

- 根据需要在 `lua/` 中调整模块开关与选项
- 语言相关配置放在 `lsp/` 或 `ftplugin/`

## 参考

- [Neovim 官方文档](https://neovim.io/doc/)
