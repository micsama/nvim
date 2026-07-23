-- proctop.lua
-- 把当前 nvim 进程的所有子孙进程（LSP、job、:terminal）按 CPU/内存排序，
-- 开一个独立 tab 展示。针对 macOS BSD ps 输出格式适配。
--
-- 用法：<D-p> 打开/关闭（toggle），或 :ProcTop
-- tab 内 q 关闭，r 手动刷新，t 切换排序方式(CPU% / 内存)
--
-- TODO 以后有空再加：
-- 1. 回车/d 对光标行 pid 发 SIGTERM（D 强制 SIGKILL），带确认
-- 2. CPU%/MEM 超阈值时高亮标红那一行
-- 3. 按 PPID 做树状缩进展示父子关系
-- 4. 每个 pid 保留最近几次采样，CMD 前加个 sparkline 看趋势
-- 5. 刷新间隔可调（+/- 键），或窗口不在前台时降低轮询频率

local map = require("utils.map").map

local M = {}

local BAR_WIDTH = 12
local NS = vim.api.nvim_create_namespace('proctop')

local state = {
  tab = nil,
  buf = nil,
  timer = nil,
  sort_by = 'cpu', -- 'cpu' | 'mem'
  tabname = 'ProcTop',
  -- 上一次采样的累计 CPU 时间，用来做差分算出"真实瞬时 CPU%"
  -- 结构: { [pid] = { cputime_sec = number, sampled_at = number(monotonic ms) } }
  last_samples = {},
  -- pid 消失后归档，一直渲染成"已退出"，不做过期清理（子进程本来就不多）
  -- 结构: { [pid] = row }
  dead_rows = {},
  -- 上一轮渲染过的全量行（活的+死的），用来在下一轮里发现"这次 ps 查不到了"的 pid，
  -- 从而判断它是不是刚挂掉
  prev_all_rows = {},
}

-- 排序方式：按 't' 循环切换。metric() 同时也是"对比"进度条用的取值，
-- 且决定表头哪一列显示排序箭头。
-- 已退出的行不再产生真实的 CPU%/MEM 数据，cpu/mem 排序下一律按 0 算，
-- 自然沉到列表最后；只有 cputime 是它们生前攒下的真实值，可以正常参与排序。
local SORT_KEYS = {
  cpu = { col = 'CPU%', metric = function(row) return (not row.dead) and row.live_cpu_pct or 0 end },
  mem = { col = 'MEM(MB)', metric = function(row) return (not row.dead) and (row.rss_kb / 1024) or 0 end },
  cputime = { col = 'CPUTIME', metric = function(row) return row.cputime_sec end },
}
local SORT_ORDER = { 'cpu', 'mem', 'cputime' }

-- 递归拿到 pid 的所有子孙进程 id
local function collect_descendants(pid, acc)
  acc = acc or {}
  local ok, children = pcall(vim.api.nvim_get_proc_children, pid)
  if not ok or not children then return acc end
  for _, cpid in ipairs(children) do
    table.insert(acc, cpid)
    collect_descendants(cpid, acc)
  end
  return acc
end

-- 把 macOS ps 的 `time` 字段（累计 CPU 时间）解析成秒数。
-- 可能的格式: "0:05.23" (分:秒.毫秒) / "12:34:56" (时:分:秒) / "2-03:04:05" (天-时:分:秒)
local function parse_cputime(s)
  local days, rest = s:match('^(%d+)%-(.+)$')
  local total_days = 0
  if days then
    total_days = tonumber(days) or 0
    s = rest
  end

  local parts = {}
  for p in s:gmatch('[^:]+') do table.insert(parts, p) end

  local seconds = 0
  local n = #parts
  if n == 1 then
    seconds = tonumber(parts[1]) or 0
  elseif n == 2 then
    seconds = (tonumber(parts[1]) or 0) * 60 + (tonumber(parts[2]) or 0)
  elseif n == 3 then
    seconds = (tonumber(parts[1]) or 0) * 3600 + (tonumber(parts[2]) or 0) * 60 + (tonumber(parts[3]) or 0)
  end

  return total_days * 86400 + seconds
end

local function fmt_cputime(sec)
  sec = math.floor(sec + 0.5)
  local h = math.floor(sec / 3600)
  local m = math.floor((sec % 3600) / 60)
  local s = sec % 60
  if h > 0 then
    return string.format('%d:%02d:%02d', h, m, s)
  end
  return string.format('%d:%02d', m, s)
end

-- 用 ps 查一批 pid 的 rss(kb) / 累计cpu时间 / 完整命令行
-- 注意：ps 一次查多个 pid 比逐个调用省开销，所以传逗号分隔的 pid 列表
local function ps_batch(pids)
  if #pids == 0 then return {} end
  local pid_list = {}
  for _, p in ipairs(pids) do table.insert(pid_list, tostring(p)) end

  -- -o 字段顺序: pid, ppid, rss(KB), time(累计cpu时间), comm(短名), command(完整命令行)
  -- 注意：不用 ps 自带的 %cpu 列——那是"进程存活以来的平均值"，长驻的 LSP server
  -- 跑几个小时之后这个数字基本不会再变化，没法反映"现在"是不是在爆 CPU。
  local cmd = { 'ps', '-o', 'pid=,ppid=,rss=,time=,comm=', '-p', table.concat(pid_list, ',') }
  local result = vim.system(cmd, { text = true }):wait()
  local rows = {}
  if result.code ~= 0 or not result.stdout then return rows end

  for line in result.stdout:gmatch('[^\r\n]+') do
    local pid, ppid, rss, time_s, comm = line:match('^%s*(%d+)%s+(%d+)%s+(%d+)%s+(%S+)%s+(.*)$')
    if pid then
      table.insert(rows, {
        pid = tonumber(pid),
        ppid = tonumber(ppid),
        rss_kb = tonumber(rss),
        cputime_sec = parse_cputime(time_s),
        comm = vim.trim(comm),
      })
    end
  end
  return rows
end

-- 把 LSP client 关联到它 spawn 出来的 pid（能关联上就在后面加个 [lsp: xxx] 标签）
local function lsp_pid_labels()
  local labels = {}
  local ok, clients = pcall(vim.lsp.get_clients)
  if not ok then return labels end
  for _, client in ipairs(clients) do
    -- 0.12+ 的 rpc client 用 vim.system 起进程，pid 挂在 rpc.transport.sysobj 上
    local rpc = client.rpc
    local pid = rpc and rpc.transport and rpc.transport.sysobj and rpc.transport.sysobj.pid
    if pid then
      labels[pid] = client.name
    end
  end
  return labels
end

-- 用两次采样的累计cpu时间差分，算出"过去这段时间"的真实 CPU 占用率。
-- 第一次见到某个 pid 时没有基线，返回 nil（渲染层会显示成 '-'）。
local function compute_live_cpu_pct(row, now_ms)
  local prev = state.last_samples[row.pid]
  state.last_samples[row.pid] = { cputime_sec = row.cputime_sec, sampled_at = now_ms }

  if not prev then return nil end

  local delta_wall_sec = (now_ms - prev.sampled_at) / 1000
  if delta_wall_sec <= 0 then return nil end

  local delta_cpu_sec = row.cputime_sec - prev.cputime_sec
  -- pid 被系统回收复用给了别的进程时，累计时间可能比上次还小，直接当成"无基线"处理
  if delta_cpu_sec < 0 then return nil end

  return (delta_cpu_sec / delta_wall_sec) * 100
end

local function collect_rows()
  local self_pid = vim.fn.getpid()
  local pids = collect_descendants(self_pid)
  local rows = ps_batch(pids)
  local labels = lsp_pid_labels()
  local now_ms = vim.uv.now()

  local seen_pids = {}
  for _, row in ipairs(rows) do
    row.label = labels[row.pid]
    row.live_cpu_pct = compute_live_cpu_pct(row, now_ms)
    seen_pids[row.pid] = true
    state.dead_rows[row.pid] = nil -- pid 复活了（或者被系统回收复用），不算"挂了"
  end

  -- 清掉已经退出的进程的采样基线，避免这张表无限涨
  for pid in pairs(state.last_samples) do
    if not seen_pids[pid] then state.last_samples[pid] = nil end
  end

  -- 上一轮渲染过的全量行（活的+死的）里，这次 ps 查不到、又还没标记过的，
  -- 就是"刚挂"的：标记 dead=true，一直留着（子进程本来就不多，不做过期清理）
  for _, row in ipairs(state.prev_all_rows or {}) do
    if not seen_pids[row.pid] and not state.dead_rows[row.pid] then
      row.dead = true
      state.dead_rows[row.pid] = row
    end
  end

  local merged = {}
  for _, row in ipairs(rows) do table.insert(merged, row) end
  for _, row in pairs(state.dead_rows) do table.insert(merged, row) end

  local metric = SORT_KEYS[state.sort_by].metric
  table.sort(merged, function(a, b) return (metric(a) or -1) > (metric(b) or -1) end)

  state.prev_all_rows = merged
  return merged
end

local function fmt_mb(kb)
  return string.format('%.1f', kb / 1024)
end

-- 用当前排序字段的值 / 本次采样里的最大值，画一个等宽进度条，
-- 直观对比"谁是大头"，比裸数字好扫一眼。
local function fmt_bar(value, max_value)
  if not value or max_value <= 0 then
    return string.rep('░', BAR_WIDTH)
  end
  local filled = math.floor((value / max_value) * BAR_WIDTH + 0.5)
  filled = math.max(0, math.min(BAR_WIDTH, filled))
  return string.rep('█', filled) .. string.rep('░', BAR_WIDTH - filled)
end

-- 定宽表格：每列固定宽度，超长截断加省略号，数字列右对齐，避免任何一列把
-- 后面的列挤歪。
local COLUMNS = {
  { name = 'PID',     width = 7,  align = 'r' },
  { name = 'PPID',    width = 7,  align = 'r' },
  { name = 'CPU%',    width = 8,  align = 'r' },
  { name = 'CPUTIME', width = 10, align = 'r' },
  { name = 'MEM(MB)', width = 10, align = 'r' },
  { name = 'LSP',     width = 12, align = 'l' },
  { name = '对比',    width = BAR_WIDTH, align = 'l' },
  -- CMD 关键信息（可执行文件名）通常在路径末尾，超长时从头部截断保留尾部更有用
  { name = 'CMD',     width = 40, align = 'l', trunc = 'head' },
}

local function fit(s, width, align, trunc)
  s = tostring(s)
  local w = vim.fn.strdisplaywidth(s)
  if w > width then
    if trunc == 'head' then
      local total = vim.fn.strchars(s)
      s = '…' .. vim.fn.strcharpart(s, total - (width - 1), width - 1)
    else
      s = vim.fn.strcharpart(s, 0, width - 1) .. '…'
    end
    w = vim.fn.strdisplaywidth(s)
  end
  local pad = string.rep(' ', width - w)
  return (align == 'r') and (pad .. s) or (s .. pad)
end

local function border(left, mid, right)
  local segs = {}
  for _, col in ipairs(COLUMNS) do
    segs[#segs + 1] = string.rep('─', col.width + 2)
  end
  return left .. table.concat(segs, mid) .. right
end

local function row_line(cells)
  local parts = {}
  for i, col in ipairs(COLUMNS) do
    parts[#parts + 1] = ' ' .. fit(cells[i], col.width, col.align, col.trunc) .. ' '
  end
  return '│' .. table.concat(parts, '│') .. '│'
end

-- 给一行里"每个 │ 分隔符之间"的内容分别打一个 extmark，跳过所有 │（包括
-- 表格外边框和列与列之间的分隔线），这样边框颜色不受影响，只有单元格内容变色
local function highlight_row_cells(bufnr, ns, line_idx, line_str, hl_group)
  local border_positions = {}
  local search_from = 1
  while true do
    local s = line_str:find('│', search_from, true)
    if not s then break end
    border_positions[#border_positions + 1] = s
    search_from = s + 3 -- '│' 的 UTF-8 编码占 3 字节
  end
  for i = 1, #border_positions - 1 do
    local start_col = border_positions[i] + 2 -- 0-indexed，跳过这个 │
    local end_col = border_positions[i + 1] - 1 -- 0-indexed，止于下一个 │ 之前
    if end_col > start_col then
      vim.api.nvim_buf_set_extmark(bufnr, ns, line_idx, start_col, {
        end_col = end_col,
        hl_group = hl_group,
        priority = 200,
      })
    end
  end
end

local function render()
  if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then return end

  local rows = collect_rows()
  local metric = SORT_KEYS[state.sort_by].metric
  local sorted_col = SORT_KEYS[state.sort_by].col

  local max_value = 0
  local dead_count = 0
  for _, row in ipairs(rows) do
    if row.dead then
      dead_count = dead_count + 1
    else
      local v = metric(row) or 0
      if v > max_value then max_value = v end
    end
  end

  local names = {}
  for _, col in ipairs(COLUMNS) do
    names[#names + 1] = (col.name == sorted_col) and (col.name .. ' ↓') or col.name
  end

  local header = string.format(
    'nvim pid=%d  子进程数=%d  已退出=%d  排序=%s (r 刷新, t 切换排序, q 关闭)',
    vim.fn.getpid(), #rows - dead_count, dead_count, state.sort_by
  )
  local lines = { header, border('┌', '┬', '┐'), row_line(names), border('├', '┼', '┤') }
  local dead_line_idxs = {}

  for _, row in ipairs(rows) do
    if row.dead then
      local line_str = row_line({
        row.pid, row.ppid, '0.0', fmt_cputime(row.cputime_sec), fmt_mb(row.rss_kb),
        row.label or '-', '已退出', row.comm,
      })
      table.insert(lines, line_str)
      dead_line_idxs[#dead_line_idxs + 1] = { idx = #lines - 1, line = line_str } -- 0-indexed 行号 + 行内容
    else
      local cpu_str = row.live_cpu_pct and string.format('%.1f', row.live_cpu_pct) or '-'
      table.insert(lines, row_line({
        row.pid, row.ppid, cpu_str, fmt_cputime(row.cputime_sec), fmt_mb(row.rss_kb),
        row.label or '-', fmt_bar(metric(row), max_value), row.comm,
      }))
    end
  end

  table.insert(lines, border('└', '┴', '┘'))

  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(state.buf, NS, 0, -1)
  for _, entry in ipairs(dead_line_idxs) do
    highlight_row_cells(state.buf, NS, entry.idx, entry.line, 'ProcTopDead')
  end
end

local function stop_timer()
  if state.timer then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
  end
end

local function is_valid_tab()
  return state.tab and pcall(vim.api.nvim_tabpage_is_valid, state.tab) and vim.api.nvim_tabpage_is_valid(state.tab)
end

function M.close()
  stop_timer()
  if is_valid_tab() then
    vim.cmd('tabclose ' .. vim.api.nvim_tabpage_get_number(state.tab))
  end
  state.tab = nil
  state.buf = nil
end

local function open_new_tab()
  vim.cmd('tabnew')
  state.tab = vim.api.nvim_get_current_tabpage()
  state.buf = vim.api.nvim_get_current_buf()

  vim.bo[state.buf].buftype = 'nofile'
  vim.bo[state.buf].bufhidden = 'wipe'
  vim.bo[state.buf].swapfile = false
  vim.bo[state.buf].filetype = 'proctop'
  -- 只是给 tabline 一个像样的名字，重名（比如反复开关）就算了，无所谓
  pcall(vim.api.nvim_buf_set_name, state.buf, state.tabname)

  vim.keymap.set('n', 'q', M.close, { buffer = state.buf, nowait = true })
  vim.keymap.set('n', 'r', render, { buffer = state.buf, nowait = true })
  vim.keymap.set('n', 't', function()
    local idx = 1
    for i, key in ipairs(SORT_ORDER) do
      if key == state.sort_by then idx = i end
    end
    state.sort_by = SORT_ORDER[(idx % #SORT_ORDER) + 1]
    render()
  end, { buffer = state.buf, nowait = true })

  render()

  -- 每 2 秒自动刷新一次
  state.timer = vim.uv.new_timer()
  state.timer:start(2000, 2000, vim.schedule_wrap(render))

  vim.api.nvim_create_autocmd('TabClosed', {
    pattern = tostring(vim.api.nvim_tabpage_get_number(state.tab)),
    once = true,
    callback = function()
      stop_timer()
      state.tab = nil
      state.buf = nil
    end,
  })
end

--- 打开/关闭 proctop：不存在则新建 tab，已存在且在当前 tab 则关闭，
--- 已存在但在别的 tab 则跳过去。
function M.toggle()
  if is_valid_tab() then
    if vim.api.nvim_get_current_tabpage() == state.tab then
      M.close()
    else
      vim.api.nvim_set_current_tabpage(state.tab)
      render()
    end
    return
  end
  open_new_tab()
end

--- opts.tabname: 自定义 tabline 上显示的名字（默认 "ProcTop"）
function M.setup(opts)
  opts = opts or {}
  if opts.tabname then state.tabname = opts.tabname end

  vim.api.nvim_set_hl(0, 'ProcTopDead', { fg = '#b8860b', default = true })
  vim.api.nvim_create_autocmd('ColorScheme', {
    callback = function() vim.api.nvim_set_hl(0, 'ProcTopDead', { fg = '#b8860b', default = true }) end,
  })

  vim.api.nvim_create_user_command('ProcTop', M.toggle, {})
  map('n', '<D-p>', M.toggle, 'ProcTop 进程监控')
end

return M
