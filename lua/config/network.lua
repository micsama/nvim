-- 网络出口：首次使用默认 7890，之后记住上次选择。
return {
	exits = {
		{ id = "7890", name = "HTTP 7890", proxy = "http://127.0.0.1:7890" },
		{ id = "1082", name = "HTTP 1082", proxy = "http://127.0.0.1:1082" },
		{ id = "direct", name = "直连", proxy = "" },
	},
	url = "https://ipinfo.io/country",
	interval_s = 120,
	connect_timeout_s = 3,
	timeout_s = 8,
}
