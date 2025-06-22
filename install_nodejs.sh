#!/bin/bash

# Function to display text in color
print_color() {
    local color=$1
    local text=$2
    case $color in
        "green") echo -e "\033[0;32m${text}\033[0m" ;;
        "blue")  echo -e "\033[0;34m${text}\033[0m" ;;
        "red")   echo -e "\033[0;31m${text}\033[0m" ;;
    esac
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check and install Homebrew if not installed
if ! command_exists brew; then
    print_color "blue" "📦 Đang cài đặt Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Ask for Node.js version
print_color "blue" "Nhập phiên bản Node.js muốn cài đặt (ví dụ: 16, 18, 20, 22): "
read node_version

# Validate Node.js version
if [[ ! $node_version =~ ^[0-9]+$ ]]; then
    print_color "red" "❌ Định dạng phiên bản Node.js không hợp lệ. Vui lòng sử dụng định dạng như 16, 18, 20, hoặc 22"
    exit 1
fi

# Install Node.js
print_color "blue" "📦 Đang cài đặt Node.js $node_version..."
brew install node@$node_version

# Add Node.js to PATH
echo "export PATH=\"/opt/homebrew/opt/node@$node_version/bin:$PATH\"" >> ~/.zshrc

# Load Node.js into current PATH
export PATH="/opt/homebrew/opt/node@$node_version/bin:$PATH"

# Install common global packages
print_color "blue" "📦 Đang cài đặt các gói toàn cục phổ biến..."

global_packages=(
    "npm"
    "yarn"
    "pnpm"
    "typescript"
    "ts-node"
    "nodemon"
    "pm2"
    "@vue/cli"
    "@angular/cli"
    "create-react-app"
    "express-generator"
)

for package in "${global_packages[@]}"; do
    print_color "blue" "Đang cài đặt $package..."
    npm install -g $package
done

# Configure npm
print_color "blue" "⚙️ Đang cấu hình npm..."
npm config set init-author-name "$(whoami)"
npm config set init-license "MIT"

# Display installation results
print_color "green" "✨ Cài đặt Node.js hoàn tất!"
echo "Phiên bản Node.js: $(node -v)"
echo "Phiên bản NPM: $(npm -v)"
echo "Phiên bản Yarn: $(yarn -v)"
echo "Phiên bản PNPM: $(pnpm -v)"

print_color "green" "
🎉 Node.js $node_version đã được cài đặt thành công!

🔧 Các gói đã cài đặt toàn cục:
- Trình quản lý gói: npm, yarn, pnpm
- Công cụ TypeScript: typescript, ts-node
- Công cụ phát triển: nodemon, pm2
- CLI Framework: @vue/cli, @angular/cli, create-react-app, express-generator

💡 Để bắt đầu sử dụng Node.js:
1. Khởi động lại terminal hoặc chạy: source ~/.zshrc
2. Kiểm tra cài đặt bằng lệnh: node -v

⚙️ Các lệnh thường dùng:
- Tạo dự án Node.js mới: npm init
- Cài đặt gói: npm install [tên-gói]
- Chạy script: npm run [tên-script]
- Khởi động PM2: pm2 start [app.js]
- Giám sát tiến trình: pm2 monit
" 