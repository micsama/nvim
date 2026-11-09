-- 网络出口：首次使用默认 7890，之后记住上次选择。
return {
	exits = {
		{ id = "7890", name = "HTTP 7890", proxy = "http://127.0.0.1:7890" },
		{ id = "1082", name = "HTTP 1082", proxy = "http://127.0.0.1:1082" },
		-- 直连：curl 用 --proxy "" 忽略代理环境变量，家里路由器 HomeProxy 透明代理时选这个。
		{ id = "direct", name = "直连", proxy = "" },
		-- 路由器的显式 SOCKS 代理：按实际监听地址和端口填写后取消注释。
		-- 选中后会写进 http(s)_proxy，curl / git 支持 socks5h://，个别工具不支持。
		-- { id = "router", name = "路由器", proxy = "socks5h://192.168.1.1:5330" },
	},
	url = "https://ipinfo.io/country",
	interval_s = 120,
	connect_timeout_s = 3,
	timeout_s = 8,
}
