local M = {}

vim.cmd([[
fun! s:MakePair()
    let line = getline('.')
		let len = strlen(line)
    if line[len - 1] == ";" || line[len - 1] == ","
        normal! lx$P
    else
        normal! lx$p
    endif
endfun
inoremap <c-u> <ESC>:call <SID>MakePair()<CR>
]])
local ctrlu = require("util.ctrlu").ctrlu

function M.map(mode, lhs, rhs, opts)
  -- 转换模式输入：支持字符串如 "ni" 或表如 {"n", "i"}
  local modes = type(mode) == "string" and vim.split(mode, "") or mode

  -- 默认选项：非递归映射 + 静默执行
  local final_opts = { noremap = true, silent = true }

  -- 处理 opts 参数：
  -- 1. 字符串类型视为描述文本 2. 表类型则合并选项
  if type(opts) == "string" then
    final_opts.desc = opts
  elseif type(opts) == "table" then
    final_opts = vim.tbl_extend("force", final_opts, opts)
  end

  -- 为每个模式设置键位映射
  for _, m in ipairs(modes) do
    vim.keymap.set(m, lhs, rhs, final_opts)
  end
end

return M
