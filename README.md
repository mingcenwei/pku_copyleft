# PKU Copyleft

从北京大学版权保护系统下载论文的小工具。

本软件是自由软件，代码属于公有领域，作者不提供任何担保或保障。使用者需要为使用本软件承担可能的一切责任；因为使用本软件而产生的任何后果，由使用者承担。

## 依赖安装

- 必须安装的依赖：[`fish`](https://github.com/fish-shell/fish-shell)、[`curl`](https://github.com/curl/curl)、[`jq`](https://github.com/stedolan/jq)、[`pup`](https://github.com/ericchiang/pup)、[`img2pdf`](https://github.com/josch/img2pdf)。
- 可选依赖：[`parallel`](https://www.gnu.org/software/parallel/)（用于提升下载速度）、[`ocrmypdf`](https://github.com/ocrmypdf/OCRmyPDF)（用于对下载的PDF文档进行图片文字识别；对中文支持较差）。

### Arch Linux

```shell
sudo pacman --sync --refresh --sysupgrade && sudo pacman --sync fish curl jq img2pdf parallel
```

[`pup`](https://aur.archlinux.org/packages/pup)（或 [`pup-git`](https://aur.archlinux.org/packages/pup-git)、[`pup-bin`](https://aur.archlinux.org/packages/pup-bin)）、[`ocrmypdf`](https://aur.archlinux.org/packages/ocrmypdf) 需要从 [AUR](https://aur.archlinux.org/) 安装。

### Ubuntu

```shell
sudo apt update && sudo apt install fish curl jq img2pdf parallel ocrmypdf
```

[`pup`](https://github.com/ericchiang/pup) 需要手动安装。

### Termux

```shell
apt update && apt install fish curl jq pup parallel
```

[`img2pdf`](https://github.com/josch/img2pdf)、[`ocrmypdf`](https://github.com/ocrmypdf/OCRmyPDF) 需要手动安装。

### macOS

使用 [Homebrew](https://brew.sh/) 安装：

```shell
brew install fish curl jq pup parallel ocrmypdf
```

[`img2pdf`](https://github.com/josch/img2pdf) 需要手动安装。

## 使用方法

1. 连接北京大学校园网，或者使用[北京大学 VPN](https://its.pku.edu.cn/service_1_vpn.jsp)。
2. 进入[北京大学学位论文数据库](https://thesis.lib.pku.edu.cn/)，搜索你想要的论文。
3. 点击搜索出来的学位论文题名，进入“查看论文信息”页面，点击右上角的“查看全文”。
4. 将会弹出网址形如 "http://162.105.134.201/pdfindex.jsp?fid=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" 的页面，在该页面可以查看论文。记录下此页面网址中 `fid=` 后面的 `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`。
5. 在浏览器中按 `F12` 打开开发者工具，选择 _storage_ 标签页，选择 _Cookies_，然后找到 _Name_ 列为 `JSESSIONID` 的一行，记录下该行的 _Value_ 列的值 `YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY`。
6. 打开命令行工具，进入 `pku_copyleft.fish` 所在文件夹，如后输入以下命令即可将论文的 PDF 下载到该文件夹。

```shell
./pku_copyleft.fish --cookie 'YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY' --fid 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
```

## 自由软件

本软件是自由软件，代码属于公有领域。请参见 [`Unlicense.txt`](./Unlicense.txt)。
