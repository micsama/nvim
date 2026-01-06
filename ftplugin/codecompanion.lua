-- ~/.config/nvim/ftplugin/codecompanion.lua

-- 1. 监听插入模式下的字符输入
vim.api.nvim_create_autocmd('InsertCharPre', {
  buffer = 0, -- 仅对当前 CodeCompanion 缓冲区生效
  callback = function()
    -- 定义触发补全的关键符号
    local triggers = { ['#'] = true, ['@'] = true, ['\\'] = true }
    
    if triggers[vim.v.char] then
      -- 使用 schedule 确保字符先落盘（进入缓冲区），再触发补全
      vim.schedule(function()
        -- 模拟按下 <C-_> (在大多数终端中等同于 <C-/> 或触发 omnifunc)
        -- 如果你的环境 <C-_> 无效，可以换成更标准的 <C-x><C-o>
        local keys = vim.api.nvim_replace_termcodes('<C-x><C-o>', true, true, true)
        vim.api.nvim_feedkeys(keys, 'n', true)
      end)
    end
  end,
})

-- 2. 优化：输入 '/' 时也触发斜杠命令补全 (可选)
vim.api.nvim_create_autocmd('InsertCharPre', {
  buffer = 0,
  callback = function()
    if vim.v.char == '/' then
      vim.schedule(function()
        -- 检查是否是行首第一个字符，避免输入路径时频繁弹出
        local col = vim.fn.col('.')
        if col <= 2 then
          local keys = vim.api.nvim_replace_termcodes('<C-x><C-o>', true, true, true)
          vim.api.nvim_feedkeys(keys, 'n', true)
        end
      end)
    end
  end,
})
