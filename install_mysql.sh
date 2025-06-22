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

# Install MySQL
print_color "blue" "📦 Đang cài đặt MySQL..."
brew install mysql

# Start MySQL service
print_color "blue" "🚀 Khởi động dịch vụ MySQL..."
brew services start mysql

# Secure MySQL installation
print_color "blue" "🔐 Thiết lập bảo mật cho MySQL..."
print_color "green" "
Vui lòng thực hiện các bước bảo mật sau:
1. Đặt mật khẩu root
2. Xóa người dùng ẩn danh
3. Vô hiệu hóa đăng nhập root từ xa
4. Xóa cơ sở dữ liệu test
5. Tải lại bảng phân quyền
"
mysql_secure_installation

# Create MySQL configuration
print_color "blue" "⚙️ Tạo cấu hình MySQL..."
mysql_conf_dir="/opt/homebrew/etc/my.cnf.d"
sudo mkdir -p "$mysql_conf_dir"

cat > "/opt/homebrew/etc/my.cnf" << 'EOL'
[mysqld]
# General
default-time-zone = '+07:00'
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# Performance
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# Connections
max_connections = 151
max_user_connections = 145

# Logging
slow_query_log = 1
long_query_time = 2
slow_query_log_file = /opt/homebrew/var/mysql/slow_query.log

[client]
default-character-set = utf8mb4

[mysql]
default-character-set = utf8mb4
EOL

# Restart MySQL to apply configuration
brew services restart mysql

# Install MySQL GUI tools
print_color "blue" "📦 Đang cài đặt công cụ đồ họa MySQL..."
brew install --cask mysqlworkbench

# Display installation results
print_color "green" "✨ Cài đặt MySQL hoàn tất!"
echo "Phiên bản MySQL: $(mysql --version)"

print_color "green" "
🎉 MySQL đã được cài đặt thành công!

📝 Cấu hình:
- File cấu hình: /opt/homebrew/etc/my.cnf
- Thư mục dữ liệu: /opt/homebrew/var/mysql
- Múi giờ: Việt Nam (GMT+7)
- Bảng mã ký tự: utf8mb4
- Số kết nối tối đa: 151

🔧 Công cụ đã cài đặt:
- MySQL Server
- MySQL Workbench (Giao diện đồ họa)

⚙️ Các lệnh thường dùng:
- Khởi động MySQL: brew services start mysql
- Dừng MySQL: brew services stop mysql
- Khởi động lại MySQL: brew services restart mysql
- Kết nối MySQL: mysql -u root -p
- Kiểm tra trạng thái: brew services list

💡 Cách kết nối MySQL:
1. Mở Terminal
2. Gõ lệnh: mysql -u root -p
3. Nhập mật khẩu root

📊 Truy cập giao diện đồ họa:
- Mở MySQL Workbench từ Applications
- Thông tin kết nối:
  * Địa chỉ: 127.0.0.1
  * Cổng: 3306
  * Tài khoản: root
  * Mật khẩu: [mật khẩu root của bạn]
" 