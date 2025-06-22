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

# Ask for PHP version
print_color "blue" "Nhập phiên bản PHP muốn cài đặt (ví dụ: 8.2, 8.3): "
read php_version

# Validate PHP version
if [[ ! $php_version =~ ^[0-9]+\.[0-9]+$ ]]; then
    print_color "red" "❌ Định dạng phiên bản PHP không hợp lệ. Vui lòng sử dụng định dạng như 8.2 hoặc 8.3"
    exit 1
fi

# Install PHP
print_color "blue" "📦 Đang cài đặt PHP $php_version..."
brew install php@$php_version

# Add PHP to PATH
echo "export PATH=\"/opt/homebrew/opt/php@$php_version/bin:$PATH\"" >> ~/.zshrc
echo "export PATH=\"/opt/homebrew/opt/php@$php_version/sbin:$PATH\"" >> ~/.zshrc

# Load PHP into current PATH
export PATH="/opt/homebrew/opt/php@$php_version/bin:$PATH"
export PATH="/opt/homebrew/opt/php@$php_version/sbin:$PATH"

# Start PHP service
brew services start php@$php_version

# Install common PHP extensions
print_color "blue" "📦 Đang cài đặt các extension PHP..."

# Install PECL
print_color "blue" "Đang cài đặt PECL..."
curl -O https://pear.php.net/go-pear.phar
sudo php go-pear.phar
rm go-pear.phar

# Common extensions via PECL
extensions=(
    "xdebug"
    "redis"
    "imagick"
    "mongodb"
)

for ext in "${extensions[@]}"; do
    print_color "blue" "Đang cài đặt extension $ext..."
    pecl install $ext
done

# Install additional tools
print_color "blue" "📦 Đang cài đặt các công cụ bổ sung..."

# Install Composer
print_color "blue" "Đang cài đặt Composer..."
EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
    print_color "red" "❌ LỖI: Checksum của Composer không hợp lệ"
    rm composer-setup.php
else
    php composer-setup.php --quiet
    rm composer-setup.php
    sudo mv composer.phar /usr/local/bin/composer
fi

# Configure PHP
print_color "blue" "⚙️ Đang cấu hình PHP..."
php_ini_path=$(php --ini | grep "Loaded Configuration File" | sed -e "s|.*:\s*||")

# Backup original php.ini
sudo cp "$php_ini_path" "${php_ini_path}.backup"

# Update PHP configuration
sudo sed -i '' 's/memory_limit = .*/memory_limit = 512M/' "$php_ini_path"
sudo sed -i '' 's/max_execution_time = .*/max_execution_time = 300/' "$php_ini_path"
sudo sed -i '' 's/post_max_size = .*/post_max_size = 100M/' "$php_ini_path"
sudo sed -i '' 's/upload_max_filesize = .*/upload_max_filesize = 100M/' "$php_ini_path"

# Restart PHP service to apply changes
brew services restart php@$php_version

# Display installation results
print_color "green" "✨ Cài đặt PHP hoàn tất!"
echo "Phiên bản PHP: $(php -v | head -n 1)"
echo "Phiên bản Composer: $(composer --version)"
echo "Các extension PHP đã cài đặt:"
php -m

print_color "green" "
🎉 PHP $php_version đã được cài đặt thành công!

📝 Cấu hình:
- File cấu hình PHP: $php_ini_path
- File backup cấu hình gốc: ${php_ini_path}.backup
- PHP đang chạy như một service (tự động khởi động khi boot)

🔧 Các extension đã cài đặt:
- Xdebug (debug và profiling)
- Redis (bộ nhớ đệm)
- Imagick (xử lý ảnh)
- MongoDB (cơ sở dữ liệu NoSQL)

💡 Để bắt đầu sử dụng PHP:
1. Khởi động lại terminal hoặc chạy: source ~/.zshrc
2. Kiểm tra cài đặt bằng lệnh: php -v

⚙️ Các lệnh thường dùng:
- Khởi động PHP: brew services start php@$php_version
- Dừng PHP: brew services stop php@$php_version
- Khởi động lại PHP: brew services restart php@$php_version
" 