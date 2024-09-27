-- ~/.config/nvim/snippets/markdown.lua
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt
local f = ls.function_node

-- 获取系统当前日期和时间，格式为 YYYY-MM-DD
local function get_current_date()
	return os.date("%Y-%m-%d")
end

-- 获取当前文件名
local function get_filename()
	return vim.fn.expand("%:t")
end

return {
	-- Markdown 链接片段 [text](url)
	s("link", fmt(
		[[
[{}]({})
        ]],
		{ i(1, "text"), i(2, "url") }
	)),

	-- Markdown 图片片段 ![alt text](image_url)
	s("img", fmt(
		[[
![{}]({})
        ]],
		{ i(1, "alt text"), i(2, "image_url") }
	)),

	-- Markdown 代码块片段 ```language
	s("code", fmt(
		[[
```{}
{}
```
        ]],
		{ i(1, "language"), i(0) }
	)),

	-- Markdown 标题片段 # Title
	s("h1", fmt(
		[[
# {}
        ]],
		{ i(1, "Title") }
	)),

	-- Markdown 引用片段 > quote
	s("quote", fmt(
		[[
> {}
        ]],
		{ i(1, "quote") }
	)),

	-- Markdown 日期片段
	s("date", fmt(
		[[
Date: {}
        ]],
		{ f(get_current_date, {}) }
	)),

	-- Markdown 文件头部片段
	s("mdheader", fmt(
		[[
# {}
**Filename**: {}
**Date**: {}
**Description**: {}

{}
        ]],
		{ i(1, "Title"), f(get_filename, {}), f(get_current_date, {}), i(2, "Description"), i(0) }
	)),
}
