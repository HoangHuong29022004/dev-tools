#!/usr/bin/env fish

# Kiểm tra và cài đặt Homebrew nếu chưa có
if not type -q brew
    echo "📦 Đang cài đặt Homebrew..."
    /bin/bash -c "(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
end

# Gọi function install-php từ config.fish
if test (count $argv) -eq 0
    install-php
else
    install-php $argv[1]
end