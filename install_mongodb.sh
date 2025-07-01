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

# Install MongoDB Community Edition
print_color "blue" "📦 Đang cài đặt MongoDB Community Edition..."
brew tap mongodb/brew
brew install mongodb-community

# Create MongoDB directories and set permissions
print_color "blue" "⚙️ Tạo thư mục và phân quyền..."
sudo mkdir -p /opt/homebrew/var/mongodb
sudo mkdir -p /opt/homebrew/var/log/mongodb
sudo chown -R $(whoami) /opt/homebrew/var/mongodb
sudo chown -R $(whoami) /opt/homebrew/var/log/mongodb

# Create MongoDB configuration
print_color "blue" "⚙️ Tạo file cấu hình MongoDB..."
cat > /opt/homebrew/etc/mongod.conf << 'EOL'
# mongod.conf

# for documentation of all options, see:
# http://docs.mongodb.org/manual/reference/configuration-options/

# Nơi lưu trữ dữ liệu
storage:
  dbPath: /opt/homebrew/var/mongodb
  journal:
    enabled: true

# Cấu hình engine và bộ nhớ đệm
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1

# Nơi ghi log
systemLog:
  destination: file
  logAppend: true
  path: /opt/homebrew/var/log/mongodb/mongo.log

# Cấu hình mạng
net:
  port: 27017
  bindIp: 127.0.0.1

# Cấu hình bảo mật
security:
  authorization: disabled

# Cấu hình hiệu suất
operationProfiling:
  mode: slowOp
  slowOpThresholdMs: 100
EOL

# Start MongoDB service
print_color "blue" "🚀 Khởi động MongoDB..."
brew services start mongodb-community

# Install MongoDB Compass
print_color "blue" "📦 Đang cài đặt MongoDB Compass..."
brew install --cask mongodb-compass

# Wait for MongoDB to start
print_color "blue" "⏳ Đợi MongoDB khởi động..."
sleep 5

# Test MongoDB connection
print_color "blue" "🔍 Kiểm tra kết nối MongoDB..."
if mongosh --eval "db.version()" &>/dev/null; then
    print_color "green" "✅ Kết nối MongoDB thành công!"
else
    print_color "red" "❌ Không thể kết nối đến MongoDB. Vui lòng kiểm tra lại."
fi

# Display installation results
print_color "green" "✨ Cài đặt MongoDB hoàn tất!"
echo "Phiên bản MongoDB: $(mongod --version | grep 'db version' | cut -d ' ' -f 3)"

print_color "green" "
🎉 MongoDB đã được cài đặt thành công!

📝 Cấu trúc thư mục:
- Thư mục dữ liệu: /opt/homebrew/var/mongodb
- File cấu hình: /opt/homebrew/etc/mongod.conf
- File log: /opt/homebrew/var/log/mongodb/mongo.log

⚙️ Các lệnh thường dùng:
- Khởi động MongoDB: brew services start mongodb-community
- Dừng MongoDB: brew services stop mongodb-community
- Khởi động lại: brew services restart mongodb-community
- Kiểm tra trạng thái: brew services list
- Kết nối MongoDB shell: mongosh

🔧 Công cụ đã cài đặt:
- MongoDB Community Server
- MongoDB Shell (mongosh)
- MongoDB Compass (GUI)

💡 Kết nối MongoDB:
1. Command Line:
   - Mở Terminal
   - Gõ lệnh: mongosh
   - Mặc định: mongodb://localhost:27017

2. MongoDB Compass:
   - Mở MongoDB Compass từ Applications
   - URL kết nối: mongodb://localhost:27017

🔒 Bảo mật:
- Authorization hiện đang tắt
- Chỉ cho phép kết nối từ localhost (127.0.0.1)
- Để bật xác thực, chỉnh sửa mongod.conf và đặt security.authorization: enabled

📊 Giám sát:
- Operation Profiling được cấu hình cho các truy vấn chậm (>100ms)
- Kiểm tra log tại: /opt/homebrew/var/log/mongodb/mongo.log

💾 Sao lưu:
- Sử dụng mongodump để sao lưu
- Sử dụng mongorestore để phục hồi
" 