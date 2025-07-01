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
    print_color "red" "❌ Vui lòng nhập phiên bản Node.js (Ví dụ: 16, 18, 20, 22)"
    print_color "yellow" "Cách sử dụng: ./switch_node.sh <version>"
    print_color "yellow" "Ví dụ: ./switch_node.sh 20"
    
    print_color "blue" "Các phiên bản Node.js đã cài đặt:"
    brew list | grep "^node@" | cut -d "@" -f 2
    exit 1
fi

# Lấy phiên bản Node.js từ tham số
NODE_VERSION=$1

# Xác định formula Node.js
if [ "$NODE_VERSION" = "22" ]; then
    NODE_FORMULA="node@22"
    # Thêm tap cho node@22 nếu chưa có
    if ! brew tap | grep -q "nodejs/node"; then
        print_color "blue" "📦 Thêm nodejs/node tap..."
        brew tap nodejs/node
    fi
else
    NODE_FORMULA="node@$NODE_VERSION"
fi

# Kiểm tra xem formula có tồn tại không
if ! brew info "$NODE_FORMULA" &> /dev/null; then
    print_color "red" "❌ Không tìm thấy phiên bản Node.js $NODE_VERSION"
    print_color "yellow" "Các phiên bản Node.js có sẵn:"
    brew search node@ | grep "^node@"
    exit 1
fi

# Kiểm tra xem phiên bản Node.js đã được cài đặt chưa
if ! brew list | grep -q "^$NODE_FORMULA\$"; then
    print_color "blue" "📦 Đang cài đặt Node.js $NODE_VERSION..."
    brew install "$NODE_FORMULA"
fi

# Unlink tất cả các phiên bản Node.js
print_color "blue" "🔄 Đang unlink các phiên bản Node.js..."
brew unlink node node@22 node@20 node@18 node@16 2>/dev/null

# Link phiên bản Node.js mới
print_color "blue" "🔗 Đang link Node.js $NODE_VERSION..."
brew link --force --overwrite "$NODE_FORMULA"

# Thêm Node.js vào PATH cho phiên làm việc hiện tại
export PATH="/opt/homebrew/opt/$NODE_FORMULA/bin:$PATH"

# Kiểm tra phiên bản Node.js hiện tại
CURRENT_VERSION=$(node -v 2>/dev/null | cut -d "v" -f 2 | cut -d "." -f 1)

if [ -n "$CURRENT_VERSION" ] && [ "$CURRENT_VERSION" = "22" ]; then
    print_color "green" "✅ Đã chuyển sang Node.js $NODE_VERSION thành công!"
    print_color "blue" "📝 Thông tin phiên bản:"
    echo "Node.js: $(node -v)"
    echo "NPM: $(npm -v)"
    
    # Hiển thị đường dẫn PATH
    print_color "blue" "📝 Đường dẫn Node.js hiện tại:"
    which node
else
    print_color "red" "❌ Có lỗi xảy ra khi chuyển đổi phiên bản Node.js"
    print_color "yellow" "Vui lòng thử các bước sau:"
    echo "1. Xóa Node.js hiện tại: brew uninstall --ignore-dependencies node"
    echo "2. Cài đặt Node.js 22: brew install node@22"
    echo "3. Link Node.js 22: brew link --force --overwrite node@22"
fi

# Hiển thị hướng dẫn cho Fish shell
print_color "yellow" "
💡 Lưu ý:
- Để thêm Node.js vào PATH trong Fish shell:
  fish_add_path /opt/homebrew/opt/$NODE_FORMULA/bin

- Để cài đặt các gói toàn cục:
  npm install -g <package>

- Để xem các gói đã cài đặt toàn cục:
  npm list -g --depth=0

- Để xóa cache npm nếu gặp lỗi:
  npm cache clean --force

- Để kiểm tra môi trường Node.js:
  node -v && npm -v && which node
" 