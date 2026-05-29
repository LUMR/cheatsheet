# Zsh 安装配置与增强

从安装 zsh 到配置自动补全提示，打造类似 PowerShell PSReadLine 的终端体验。

## 安装 Zsh

```bash
# Debian / Ubuntu
sudo apt install zsh

# macOS（自带，如需更新）
brew install zsh

# Fedora / RHEL
sudo dnf install zsh

# Arch
sudo pacman -S zsh
```

## 设为默认 Shell

```bash
chsh -s $(which zsh)
```

注销后重新登录即生效。可用 `echo $SHELL` 确认当前 shell。

## 首次启动

首次打开 zsh 会进入配置向导，可选：

| 选项 | 说明 |
|------|------|
| `0` | 退出，使用空白配置（推荐，后续手动配置） |
| `1` | 继续向导，逐步设置历史记录、补全等 |
| `2` | 用默认配置填充 `~/.zshrc` |

如果选了 `0`，后续手动创建 `~/.zshrc` 即可：

```bash
touch ~/.zshrc
```

## 常用配置项（~/.zshrc）

```bash
# 历史记录
HISTFILE=~/.zsh_history
HISTSIZE=10000          # 内存中保留的历史条数
SAVEHIST=10000          # 磁盘保存的历史条数
setopt SHARE_HISTORY    # 多终端共享历史
setopt HIST_IGNORE_DUPS # 去除连续重复

# 补全行为
setopt AUTO_CD          # 输入目录名直接 cd
setopt CORRECT          # 命令拼写纠正

# 补全系统初始化
autoload -Uz compinit && compinit
```

## 别名示例

```bash
alias ll='ls -alFh'
alias gs='git status'
alias gl='git log --oneline -20'
```

## 插件管理（可选：oh-my-zsh）

如果喜欢图形化管理插件，可安装 oh-my-zsh：

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

> 本文后续使用系统包直接安装插件，无需 oh-my-zsh。

## 三件套

| 插件 | 作用 | 触发方式 |
|------|------|---------|
| **zsh-autosuggestions** | 根据历史记录自动提示命令 | 输入时自动弹出灰色建议，按 `→` 接受 |
| **zsh-completions** | 额外的命令参数补全定义 | 按 `Tab` 触发，列出合法参数/子命令/选项 |
| **zsh-syntax-highlighting** | 实时语法高亮 | 输入时自动着色，命令错误立刻变红 |

## 安装

```bash
sudo apt install zsh-autosuggestions zsh-completions zsh-syntax-highlighting
```

## 配置 ~/.zshrc

在 `~/.zshrc` 末尾按以下顺序添加（**syntax-highlighting 必须最后加载**）：

```bash
# zsh 增强
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-completions/zsh-completions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

```bash
source ~/.zshrc
```

## 效果说明

### autosuggestions（历史建议）

输入时自动根据历史记录显示灰色建议文字，按 `→` 接受建议。

### completions（参数补全）

提供更多命令的 Tab 补全规则：

```bash
docker run --<Tab>        # 列出 --detach, --env, --volume, --publish 等选项
systemctl <Tab>           # 补全 start/stop/restart/status/enable 等子命令
npm <Tab>                 # 补全 install/run/build/test 等子命令
```

### syntax-highlighting（语法高亮）

| 颜色 | 含义 |
|------|------|
| 绿色 | 命令存在、路径正确 |
| 红色 | 命令不存在、路径错误 |
| 黄色 | 字符串、参数 |
| 青色 | 条件语句、循环等关键字 |

示例：

```bash
gut status    # 红色 → 命令不存在，还没按回车就知道打错了
git status    # 绿色 → 命令正确
cat /etc/passwd    # 路径有下划线 → 文件存在
cat /etc/passwddd  # 红色 → 文件不存在
```

## 当前系统配置参考

基于 Oh My Zsh 的实际 `~/.zshrc` 配置，开箱即用：

```bash
# Oh My Zsh 基础设置
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"          # Powerline 风格主题，需要 Powerline 字体
DEFAULT_USER="lumr"           # 隐藏用户名@主机名前缀（仅显示目录）
plugins=(git)                 # 启用的插件

source $ZSH/oh-my-zsh.sh

# Go
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# Zsh 增强（syntax-highlighting 必须最后）
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# 自定义别名
source ~/.bash_aliases

# nvm（Node.js 版本管理）
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
```

> **提示：** 主题 `agnoster` 需要 [Powerline 字体](https://github.com/powerline/fonts)，否则提示符会显示乱码。WSL 终端推荐在设置中指定 `Meslo LG S for Powerline` 字体。

## 可选增强：fzf（模糊搜索）

```bash
sudo apt install fzf
```

在 `~/.zshrc` 中添加：

```bash
source /usr/share/doc/fzf/examples/key-bindings.zsh
source /usr/share/doc/fzf/examples/completion.zsh
```

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+R` | 模糊搜索历史命令 |
| `Ctrl+T` | 模糊搜索文件 |
| `Alt+C` | 模糊切换目录 |

## 可选增强：ble.sh（Bash 替代方案）

如果更想留在 bash，可以用 ble.sh 实现类似效果：

```bash
git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git
make -C ble.sh install PREFIX=~/.local

# 在 ~/.bashrc 中添加
[[ -f ~/.local/share/blesh/ble.sh ]] && source ~/.local/share/blesh/ble.sh
```
