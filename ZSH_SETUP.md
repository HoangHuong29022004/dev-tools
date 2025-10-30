# 🐚 Zsh Setup Guide - Hướng dẫn cài đặt Zsh

## 📋 Tổng quan

Zsh (Z Shell) là shell mạnh mẽ và linh hoạt hơn Bash, với nhiều tính năng tự động hoàn thành, syntax highlighting, và ecosystem plugin phong phú. Đặc biệt phù hợp cho Laravel/PHP development.

## 🚀 Cài đặt Zsh + Oh My Zsh

### Bước 1: Cài Zsh
```bash
brew install zsh
```

### Bước 2: Cài Oh My Zsh
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
```

### Bước 3: Cài plugins nâng cao
```bash
brew install zsh-autosuggestions zsh-syntax-highlighting fzf starship
```

### Bước 4: Setup FZF
```bash
$(brew --prefix)/opt/fzf/install --all
```

### Bước 5: Thêm Zsh vào hệ thống
```bash
echo '/opt/homebrew/bin/zsh' | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/zsh
```

## ⚙️ Cấu hình Starship Prompt

Tạo file `~/.config/starship.toml`:

```toml
# Starship Configuration - Clean & Simple

# Disable Python version
[python]
disabled = true

# Show full directory path
[directory]
style = "cyan"
truncation_length = 0
truncate_to_repo = false

# Git branch
[git_branch]
symbol = "🌱 "
style = "green"

# Git status
[git_status]
style = "red"
format = "([\\[$all_status$ahead_behind\\]]($style) )"

# Character prompt
[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"

# Disable unnecessary modules
[package]
disabled = true

[nodejs]
disabled = true

[rust]
disabled = true

[golang]
disabled = true

[java]
disabled = true

[ruby]
disabled = true

[php]
disabled = true

[elixir]
disabled = true

[elm]
disabled = true

[zig]
disabled = true

[ocaml]
disabled = true

[haskell]
disabled = true

[swift]
disabled = true

[scala]
disabled = true

[kotlin]
disabled = true

[dart]
disabled = true

[cmake]
disabled = true

[meson]
disabled = true

[nim]
disabled = true

[perl]
disabled = true

[conda]
disabled = true

[memory_usage]
disabled = true

[env_var]
disabled = true

[aws]
disabled = true

[gcloud]
disabled = true

[azure]
disabled = true

[kubernetes]
disabled = true

[docker_context]
disabled = true

[terraform]
disabled = true

[openstack]
disabled = true

[cmd_duration]
disabled = true

[time]
disabled = true

[username]
disabled = true

[hostname]
disabled = true

[shlvl]
disabled = true

[shell]
disabled = true

[status]
disabled = true

[line_break]
disabled = true

[fill]
disabled = true

[os]
disabled = true

[container]
disabled = true

[spack]
disabled = true

[singularity]
disabled = true

[vcsh]
disabled = true

[hg_branch]
disabled = true

[battery]
disabled = true

[dotnet]
disabled = true

[erlang]
disabled = true

[gradle]
disabled = true

[julia]
disabled = true

[lua]
disabled = true

[nix_shell]
disabled = true

[opa]
disabled = true

[pulumi]
disabled = true

[purescript]
disabled = true

[r]
disabled = true

[red]
disabled = true

[vagrant]
disabled = true
```

## 🔧 Cấu hình .zshrc

File `~/.zshrc` sẽ chứa:

```bash
# Oh My Zsh Configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # Disable Oh My Zsh theme, using Starship instead

# Plugins
plugins=(
  git
  docker
  composer
  npm
  brew
  macos
  colored-man-pages
  command-not-found
)

source $ZSH/oh-my-zsh.sh

# ===========================================
# ENHANCED PLUGINS
# ===========================================

# Auto-suggestions (Fish-like)
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Syntax highlighting
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# FZF integration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Starship prompt (beautiful and fast)
eval "$(starship init zsh)"

# ===========================================
# CUSTOM CONFIGURATION
# ===========================================

# Environment Variables
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export EDITOR="nano"

# Node.js
export PATH="node_modules/.bin:$PATH"

# PHP/Composer
export PATH="$HOME/.composer/vendor/bin:$PATH"

# ===========================================
# ALIASES
# ===========================================

# Laravel
alias art="php artisan"
alias sail="./vendor/bin/sail"
alias serve="php -S localhost:8000"

# Project creation shortcuts
alias mk="python3 ~/dev-tools/mkproject.py"
alias mkcode="python3 ~/dev-tools/mkproject.py"
alias mktest="python3 ~/dev-tools/mkproject.py"

# Git
alias g="git"
alias gst="git status"
alias gaa="git add ."
alias gcm='git commit -m'
alias gco="git checkout"
alias gpl="git pull"
alias gps="git push"

# VS Code và Cursor
alias code="/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code"
alias cursor="/Applications/Cursor.app/Contents/Resources/app/bin/code"

# Docker
alias d="docker"
alias dc="docker-compose"
alias dps="docker ps"

# npm/yarn
alias ni="npm install"
alias nr="npm run"
alias dev="npm run dev"
alias build="npm run build"
alias yi="yarn install"
alias yd="yarn dev"

# Laravel Commands
alias porcl="php artisan route:clear && php artisan config:clear && php artisan cache:clear && php artisan view:clear && php artisan optimize"
alias pcl="php artisan cache:clear && php artisan view:clear"
alias prl="php artisan route:list"
alias pcc="php artisan cache:clear"
alias pvc="php artisan view:clear"
alias po="php artisan optimize"

# ===========================================
# FUNCTIONS
# ===========================================

# Function chuyển đổi PHP version (FAST VERSION)
switch-php() {
    if [[ $# -eq 0 ]]; then
        echo "❌ Vui lòng nhập phiên bản PHP. Ví dụ: switch-php 7.4"
        return 1
    fi

    local phpver=$1
    local php_formula="php@$phpver"

    if [[ ! -d "/opt/homebrew/opt/$php_formula" ]]; then
        echo "❌ PHP $phpver chưa được cài. Cài bằng: brew install $php_formula"
        return 1
    fi

    echo "⚡ Chuyển sang PHP $phpver..."

    # Chỉ unlink PHP hiện tại và link PHP mới (không touch services)
    brew unlink php >/dev/null 2>&1
    brew unlink $php_formula >/dev/null 2>&1
    brew link --force --overwrite $php_formula >/dev/null

    # Cập nhật PATH ngay lập tức
    export PATH="/opt/homebrew/opt/$php_formula/bin:/opt/homebrew/opt/$php_formula/sbin:$PATH"

    echo "✅ PHP $phpver"
    php -v | head -1
}

# Function cài đặt PHP mới
install-php() {
    local phpver=${1:-"7.4"}
    local php_formula="php@$phpver"

    # Cài đặt PHP
    echo "📦 Đang cài đặt PHP $phpver..."
    brew install $php_formula

    # Chuyển sang PHP version mới
    switch-php $phpver

    echo "🎉 PHP $phpver đã được cài đặt thành công!"
}

# Function chạy composer với PHP version cụ thể
composer-with-php() {
    if [[ $# -lt 2 ]]; then
        echo "❌ Cú pháp: composer-with-php <php_version> <composer_command>"
        echo "Ví dụ: composer-with-php 8.2 install"
        echo "Ví dụ: composer-with-php 7.4 update"
        return 1
    fi

    local phpver=$1
    shift
    local composer_cmd="$@"
    local php_formula="php@$phpver"

    if [[ ! -d "/opt/homebrew/opt/$php_formula" ]]; then
        echo "❌ PHP $phpver chưa được cài. Cài bằng: install-php $phpver"
        return 1
    fi

    echo "🔧 Chạy composer với PHP $phpver..."
    echo "📝 Lệnh: composer $composer_cmd"
    
    # Chạy composer với PHP version cụ thể
    /opt/homebrew/opt/$php_formula/bin/php /opt/homebrew/bin/composer $composer_cmd
}

# Function chạy composer với PHP version tự động từ .php-version file
composer-auto() {
    local composer_cmd="$@"
    
    # Kiểm tra file .php-version trong thư mục hiện tại
    if [[ -f ".php-version" ]]; then
        local phpver=$(cat .php-version | tr -d '[:space:]')
        echo "🔍 Tìm thấy .php-version: PHP $phpver"
        composer-with-php $phpver $composer_cmd
    else
        echo "❌ Không tìm thấy file .php-version"
        echo "💡 Tạo file .php-version với nội dung phiên bản PHP (ví dụ: 8.2)"
        echo "📝 Hoặc sử dụng: composer-with-php <version> <command>"
        return 1
    fi
}

# ===========================================
# ALIASES FOR FUNCTIONS
# ===========================================

# Alias ngắn gọn cho composer với PHP version
alias c8.2="composer-with-php 8.2"
alias c8.1="composer-with-php 8.1"
alias c8.0="composer-with-php 8.0"
alias c7.4="composer-with-php 7.4"
alias c7.3="composer-with-php 7.3"

# Alias cho composer tự động
alias ca="composer-auto"

# Project management shortcuts
alias pm="python3 ~/dev-tools/manage.py"
alias projects="python3 ~/dev-tools/manage.py"

# Alias cho PHP versions
alias php74='switch-php 7.4'
alias php80='switch-php 8.0'
alias php81='switch-php 8.1'
alias php82='switch-php 8.2'
alias php83='switch-php 8.3'
alias php84='switch-php 8.4'

# ===========================================
# ADDITIONAL ZSH CONFIGURATIONS
# ===========================================

# History
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Options
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

# Auto-completion
autoload -U compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Case insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Auto-correction
setopt CORRECT

# Auto CD
setopt AUTO_CD

# ===========================================
# WELCOME MESSAGE
# ===========================================

echo "🐚 Welcome to Zsh! (Migrated from Fish)"
echo "💡 Available commands: switch-php, install-php, composer-with-php, composer-auto"
echo "🚀 Your Fish config has been successfully migrated!"
```

## 🎯 Tính năng chính

### ⚡ PHP Version Switching
```bash
switch-php 8.2    # Chuyển sang PHP 8.2
php84             # Alias ngắn gọn
```

### 🎨 Composer với PHP version cụ thể
```bash
composer-with-php 8.2 install
c8.2 install      # Alias ngắn gọn
```

### 🔍 Auto-suggestions
- Gõ command sẽ có gợi ý từ history
- Giống Fish shell

### 🎨 Syntax Highlighting
- Command đúng/sai có màu khác nhau
- Dễ nhận biết lỗi syntax

### 🔍 FZF Integration
- `Ctrl+T` - Tìm file
- `Ctrl+R` - Tìm trong history
- `Ctrl+Alt+C` - CD vào thư mục

### 🚀 Project Management
- `mk project-name [php-version] [.test|.code]` - Tạo project nhanh
- `pm` - Quản lý projects (xem, mở, xóa)
- `projects` - Xem danh sách projects

### 🌟 Starship Prompt
- Đẹp và nhanh
- Hiển thị git status
- Full path directory
- Không hiển thị Python version

## 🚀 Restart Shell

Sau khi cài đặt xong:
```bash
exec zsh
```

Hoặc mở terminal mới.

## 📝 So sánh với Fish

| Tính năng | Fish | Zsh + Oh My Zsh |
|-----------|------|-----------------|
| Tương thích Bash | ❌ | ✅ |
| Ecosystem | Ít | Khổng lồ |
| Auto-suggestions | ✅ | ✅ |
| Syntax highlighting | ✅ | ✅ |
| PHP switching | ✅ | ✅ |
| Composer integration | ✅ | ✅ |
| Server compatibility | ❌ | ✅ |

## 🎉 Kết quả

Prompt sẽ hiển thị:
```bash
/opt/homebrew/var/www/project-name on 🌱 main [✘] ❯
```

- Full path directory
- Git branch và status
- Clean, không có Python version
- Nhanh và responsive

## 🔧 Troubleshooting

### Lỗi "command not found"
```bash
source ~/.zshrc
```

### Lỗi Starship config
```bash
starship config --help
```

### Reset về Fish
```bash
chsh -s /opt/homebrew/bin/fish
```

---

**🎯 Zsh + Oh My Zsh + Starship = Perfect combo cho Laravel development!**
