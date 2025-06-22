#!/bin/bash

# Function to display text in color
print_color() {
    local color=$1
    local text=$2
    case $color in
        "green") echo -e "\033[0;32m${text}\033[0m" ;;
        "blue")  echo -e "\033[0;34m${text}\033[0m" ;;
        "red")   echo -e "\033[0;31m${text}\033[0m" ;;
        "yellow") echo -e "\033[0;33m${text}\033[0m" ;;
    esac
}

# Kiểm tra xem có tham số version được truyền vào không
if [ -z "$1" ]; then
    print_color "red" "❌ Vui lòng nhập phiên bản PHP (Ví dụ: 7.4, 8.0, 8.1, 8.2)"
    print_color "yellow" "Cách sử dụng: ./switch_php.sh <version>"
    print_color "yellow" "Ví dụ: ./switch_php.sh 8.1"
    exit 1
fi

# Lấy phiên bản PHP từ tham số
PHP_VERSION=$1

# Xác định formula PHP
if [ "$PHP_VERSION" = "8.4" ]; then
    PHP_FORMULA="php"
else
    PHP_FORMULA="php@$PHP_VERSION"
fi

# Kiểm tra xem formula có tồn tại không
if ! brew info "$PHP_FORMULA" &> /dev/null; then
    print_color "red" "❌ Không tìm thấy phiên bản PHP $PHP_VERSION"
    print_color "yellow" "Các phiên bản PHP có sẵn:"
    brew search php@
    exit 1
fi

# Kiểm tra xem phiên bản PHP đã được cài đặt chưa
if ! brew list | grep -q "^$PHP_FORMULA\$"; then
    print_color "blue" "📦 Đang cài đặt PHP $PHP_VERSION..."
    brew install "$PHP_FORMULA"
fi

# Dừng tất cả các service PHP đang chạy
print_color "blue" "🔄 Dừng các service PHP..."
brew services list | grep php | awk '{print $1}' | while read service; do
    brew services stop "$service" 2>/dev/null
done

# Unlink tất cả các phiên bản PHP
print_color "blue" "🔄 Đang unlink các phiên bản PHP..."
brew unlink php php@8.2 php@8.1 php@8.0 php@7.4 2>/dev/null

# Link phiên bản PHP mới với overwrite
print_color "blue" "🔗 Đang link PHP $PHP_VERSION..."
if [ "$PHP_VERSION" = "8.4" ]; then
    # Xử lý đặc biệt cho PHP 8.4 (phiên bản mặc định)
    brew unlink php 2>/dev/null
    brew link --force --overwrite php
else
    brew link --force --overwrite "$PHP_FORMULA"
fi

# Khởi động service PHP mới
print_color "blue" "🚀 Khởi động service PHP..."
brew services start "$PHP_FORMULA"

# Thêm PHP vào PATH cho phiên làm việc hiện tại
if [ "$PHP_VERSION" = "8.4" ]; then
    export PATH="/opt/homebrew/opt/php/bin:$PATH"
    export PATH="/opt/homebrew/opt/php/sbin:$PATH"
else
    export PATH="/opt/homebrew/opt/$PHP_FORMULA/bin:$PATH"
    export PATH="/opt/homebrew/opt/$PHP_FORMULA/sbin:$PATH"
fi

# Kiểm tra phiên bản PHP hiện tại
CURRENT_VERSION=$(php -v | grep -Eo 'PHP [0-9]+\.[0-9]+' | cut -d' ' -f2)

if [ "$CURRENT_VERSION" = "$PHP_VERSION" ]; then
    print_color "green" "✅ Đã chuyển sang PHP $PHP_VERSION thành công!"
    print_color "blue" "📝 Thông tin phiên bản PHP hiện tại:"
    php -v
    
    # Hiển thị đường dẫn PATH
    print_color "blue" "📝 Đường dẫn PHP hiện tại:"
    which php
else
    print_color "red" "❌ Có lỗi xảy ra khi chuyển đổi phiên bản PHP"
    print_color "yellow" "Vui lòng thử lại hoặc kiểm tra lỗi"
fi

# Hiển thị hướng dẫn cho Fish shell
print_color "yellow" "
💡 Lưu ý:
- Để thêm PHP vào PATH trong Fish shell:
  fish_add_path /opt/homebrew/opt/$PHP_FORMULA/bin
  fish_add_path /opt/homebrew/opt/$PHP_FORMULA/sbin

- Để khởi động PHP-FPM tự động: brew services start $PHP_FORMULA
- Để dừng PHP-FPM: brew services stop $PHP_FORMULA
- Để xem trạng thái: brew services list
" 