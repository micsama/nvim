-- ~/.config/nvim/snippets/python.lua
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt
local f = ls.function_node

-- 获取系统当前日期和时间，格式为 YYYY-MM-DD HH:MM
local function get_current_datetime()
	return os.date("%Y-%m-%d %H:%M")
end

-- 获取当前文件名
local function get_filename()
	return vim.fn.expand("%:t")
end

return {
	-- 函数代码片段
	s("func", {
		t("def "), i(1, "function_name"), t("("), i(2, "args"), t({ "):", "\t" }),
		i(0) -- 光标最终停留位置
	}),

	-- if __name__ == "__main__" 代码片段
	s("ifmain", fmt(
		[[
if __name__ == "__main__":
    {}
        ]],
		{ i(0) }
	)),

	-- Python 文件头部代码片段
	s("py", fmt(
		[[
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Author: Xing J
# Date: {}
# Filename: {}
# Description: {}

{}
        ]],
		{ f(get_current_datetime, {}), f(get_filename, {}), i(1, "Description"), i(0) }
	)),

	-- 读取 JSON 文件并解析的代码片段
	s("rj", fmt(
		[[
with open({}, "r") as f:
    lines = [json.loads(line) for line in f]
for line in lines:
	{}
        ]],
		{ i(1, '"filename"'), i(0) }
	)),

	-- 将列表数据写入 JSON 文件的代码片段
	s("wj", fmt(
		[[
with open({}, "w") as f:
    f.writelines([json.dumps(item,ensure_ascii=False) + "\\n" for item in {}])

{}
        ]],
		{ i(1, '"filename"'), i(2, "data_list"), i(0) }
	)),
}
