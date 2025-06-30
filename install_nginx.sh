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

# Install Nginx
print_color "blue" "📦 Đang cài đặt Nginx..."
brew install nginx

# Create necessary directories
print_color "blue" "⚙️ Tạo cấu trúc thư mục..."
sudo mkdir -p /opt/homebrew/etc/nginx/sites-available
sudo mkdir -p /opt/homebrew/etc/nginx/sites-enabled
sudo mkdir -p /opt/homebrew/var/www
sudo mkdir -p /opt/homebrew/etc/nginx/ssl
sudo chown -R $(whoami) /opt/homebrew/var/www

# Create main Nginx configuration
print_color "blue" "⚙️ Tạo file cấu hình chính..."
cat > /opt/homebrew/etc/nginx/nginx.conf << 'EOL'
worker_processes auto;
worker_rlimit_nofile 65535;

events {
    worker_connections 1024;
    multi_accept on;
    use kqueue;
}

http {
    include mime.types;
    default_type application/octet-stream;

    # Logging
    access_log /opt/homebrew/var/log/nginx/access.log combined buffer=512k flush=1m;
    error_log /opt/homebrew/var/log/nginx/error.log warn;

    # Optimizations
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/json application/javascript application/xml+rss application/atom+xml image/svg+xml;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Load virtual hosts
    include /opt/homebrew/etc/nginx/sites-enabled/*;
}
EOL

# Create default virtual host
print_color "blue" "⚙️ Tạo virtual host mặc định..."
cat > /opt/homebrew/etc/nginx/sites-available/default << 'EOL'
server {
    listen 8080;
    listen 443 ssl;
    http2 on;
    server_name localhost;
    root /opt/homebrew/var/www;
    index index.php index.html index.htm;

    # SSL Configuration
    ssl_certificate     /opt/homebrew/etc/nginx/ssl/localhost.crt;
    ssl_certificate_key /opt/homebrew/etc/nginx/ssl/localhost.key;
    
    # SSL Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;

    charset utf-8;
    client_max_body_size 100M;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    # PHP-FPM Configuration
    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_intercept_errors on;
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
        fastcgi_read_timeout 600;
    }

    # Security
    location ~ /\.(?!well-known).* {
        deny all;
    }

    # Enable browser caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|eot|ttf|woff|woff2)$ {
        expires max;
        add_header Cache-Control public;
        access_log off;
    }

    # Logging
    error_log /opt/homebrew/var/log/nginx/default-error.log;
    access_log /opt/homebrew/var/log/nginx/default-access.log combined;
}
EOL

# Create symbolic link to enable default site
print_color "blue" "🔗 Kích hoạt virtual host mặc định..."
ln -sf /opt/homebrew/etc/nginx/sites-available/default /opt/homebrew/etc/nginx/sites-enabled/

# Create SSL directory and certificate
print_color "blue" "🔒 Tạo SSL certificate cho localhost..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /opt/homebrew/etc/nginx/ssl/localhost.key \
    -out /opt/homebrew/etc/nginx/ssl/localhost.crt \
    -subj "/CN=localhost" \
    -addext "subjectAltName=DNS:localhost"

# Create test files
print_color "blue" "�� Tạo file test..."
echo "<!DOCTYPE html><html><head><title>Welcome to Nginx!</title></head><body><h1>Welcome to Nginx!</h1></body></html>" > /opt/homebrew/var/www/index.html
echo "<?php phpinfo(); ?>" > /opt/homebrew/var/www/info.php

# Start Nginx service
print_color "blue" "🚀 Khởi động Nginx..."
brew services start nginx

# Test Nginx configuration
print_color "blue" "🔍 Kiểm tra cấu hình..."
nginx -t

# Display installation results
print_color "green" "✨ Cài đặt Nginx hoàn tất!"
echo "Phiên bản Nginx: $(nginx -v 2>&1)"

print_color "green" "
🎉 Nginx đã được cài đặt thành công!

📝 Cấu trúc thư mục:
- Thư mục gốc web: /opt/homebrew/var/www
- Cấu hình chính: /opt/homebrew/etc/nginx/nginx.conf
- Virtual hosts: /opt/homebrew/etc/nginx/sites-available
- Sites đang hoạt động: /opt/homebrew/etc/nginx/sites-enabled
- Logs: /opt/homebrew/var/log/nginx

🌐 Truy cập website:
- Web mặc định: http://localhost:8080
- PHP Info: http://localhost:8080/info.php

⚙️ Các lệnh thường dùng:
- Khởi động: brew services start nginx
- Dừng: brew services stop nginx
- Khởi động lại: brew services restart nginx
- Kiểm tra cấu hình: nginx -t
- Tải lại cấu hình: nginx -s reload

💡 Tạo virtual host mới:
1. Tạo file trong sites-available
2. Tạo symbolic link trong sites-enabled
3. Tải lại Nginx: nginx -s reload

🔒 Bảo mật:
- Đã bật các header bảo mật cơ bản
- Chặn truy cập file ẩn
- Tối ưu hóa cho PHP-FPM
- Cấu hình GZIP và cache
" 