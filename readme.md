# nvim config for dzmfg
## asd

## Key map

# sdsa

## asdsa
客户端-服务器通信

Neovim 0.7将neovim-remote的一些功能引入核心编辑器中。您现在可以使用nvim --remote在已运行的Neovim实例中打开文件。一个例子：

# In one shell session
nvim --listen /tmp/nvim.sock

# In another shell session, opens foo.txt in the first Nvim instance
nvim --server /tmp/nvim.sock --remote foo.txt
新远程功能的一个用例是能够从主Neovim实例中的嵌入式终端模拟器中打开文件，而不是创建在Neovim本身中运行的嵌入式Neovim实例。


lsp 的新功能 hint 、codeline  代码折叠 等

