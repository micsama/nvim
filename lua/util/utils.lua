-- 定义一个模块 M，用于管理键位映射
local M = {}

-- 在 Vim 命令行中定义一个函数：s:MakePair()
-- 功能：在插入模式下，按 <C-u> 可以自动补全括号（如 `)` 或 `,`）
-- 逻辑：
--   - 如果当前行末尾是分号 ; 或逗号 ,，则在行尾插入内容（避免重复）
--   - 否则，插入一个括号并把前面的内容复制到后面（形成完整结构）
-- 例如：
--   输入：foo(bar
--   按 <C-u> → foo(bar)
--   输入：foo(bar;
--   按 <C-u> → foo(bar);  （自动补全分号）
vim.cmd([[
fun! s:MakePair()
    let line = getline('.')  " 获取当前行
    let len = strlen(line)  " 获取行长
    if line[len - 1] == ";" || line[len - 1] == ","  " 如果末尾是 ; 或 ,
      normal! lx$P           " 在末尾插入前面的内容（不覆盖）
    else
      normal! lx$p           " 在末尾插入前面的内容（形成括号）
    endif
endfun

inoremap <c-u> <ESC>:call <SID>MakePair()<CR>
]])

-- 从 util.ctrlu 模块导入工具（目前未使用，预留扩展空间）
local ctrlu = require("util.ctrlu").ctrlu

-- 主函数 M.map：统一设置 Vim 键位映射
-- 功能：在指定模式（如 n, i）下，将某个按键绑定到某个操作
-- 例如：
--   M.map("i", "<c-n>", "p")  → 在插入模式下按 Ctrl+n 插入 p
-- 优点：
--   - 支持多模式（如 "ni" 表示在正常和插入模式下都生效）
--   - 支持配置选项（如 silent、noremap、desc 描述）
function M.map(mode, lhs, rhs, opts)
  -- mode：模式字符串或数组，如 "n"、"i" 或 {"n", "i"}
  -- lhs：按键，如 "j", "<c-s>"
  -- rhs：动作，如 "p", "d", ":echo"
  -- opts：可选配置，如 { silent = true, desc = "Jump down" }

  local modes = type(mode) == "string" and vim.split(mode, "") or mode  -- 转为模式数组

  local final_opts = { noremap = true, silent = true }  -- 默认不触发重映射，不显示提示

  if type(opts) == "string" then
    final_opts.desc = opts  -- 如果是字符串，作为描述信息
  elseif type(opts) == "table" then
    final_opts = vim.tbl_extend("force", final_opts, opts)  -- 覆盖配置
  end

  for _, m in ipairs(modes) do
    vim.keymap.set(m, lhs, rhs, final_opts)  -- 设置映射
  end
end

return M
