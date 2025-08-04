#!/usr/bin/env fish

# Kiểm tra tham số
if test (count $argv) -eq 0
    echo "❌ Vui lòng nhập phiên bản PHP. Ví dụ: ./switch_php.sh 7.4"
    exit 1
end

# Gọi function switch-php từ config.fish
switch-php $argv[1]