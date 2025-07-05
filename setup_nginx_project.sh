#!/bin/bash

# Colors
NORMAL="\\033[0;39m"
GREEN="\\033[1;32m"
RED="\\033[1;31m"
BLUE="\\033[1;34m"
ORANGE="\\033[1;33m"

# Function to check if command executed successfully
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NORMAL}"
    else
        echo -e "${RED}✗ $1${NORMAL}"
        return 1
    fi
}

echo -e "${BLUE}=== Tạo Virtual Host ===${NORMAL}"

# Set default PHP version
DEFAULT_PHP="8.2"
PHP_VERSION=$DEFAULT_PHP

# Show available PHP versions and allow change
echo -e "${BLUE}Phiên bản PHP hiện có:${NORMAL}"
ls /opt/homebrew/opt/php@* 2>/dev/null | grep -o 'php@[0-9.]*' | cut -d@ -f2 | sort
echo -e "${GREEN}Mặc định sử dụng PHP $DEFAULT_PHP${NORMAL}"
read -p "Bạn có muốn đổi phiên bản PHP không? (y/N): " change_php

if [ "$change_php" = "y" ] || [ "$change_php" = "Y" ]; then
    read -p "Nhập phiên bản PHP (vd: 8.3): " PHP_VERSION
fi

# Validate PHP version
if [ ! -d "/opt/homebrew/opt/php@$PHP_VERSION" ]; then
    echo -e "${RED}Không tìm thấy PHP phiên bản $PHP_VERSION!${NORMAL}"
    exit 1
fi

# Get domain name and validate
read -p "Nhập tên miền (vd: project.test): " DOMAIN
# Remove special characters and convert to lowercase
DOMAIN=$(echo "$DOMAIN" | tr -cd '[:alnum:].-' | tr '[:upper:]' '[:lower:]')

if [ -z "$DOMAIN" ]; then
    echo -e "${RED}Tên miền không được để trống!${NORMAL}"
    exit 1
fi

# Validate domain name format
if ! echo "$DOMAIN" | grep -qE '^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)*$'; then
    echo -e "${RED}Tên miền không hợp lệ! Chỉ được phép dùng chữ cái, số, dấu gạch ngang và dấu chấm.${NORMAL}"
    echo -e "${RED}Tên miền không được bắt đầu hoặc kết thúc bằng dấu gạch ngang.${NORMAL}"
    exit 1
fi

echo -e "${BLUE}Sử dụng tên miền: ${GREEN}$DOMAIN${NORMAL}"

# Create project directory
echo -e "${BLUE}Tạo thư mục dự án...${NORMAL}"
PROJECT_DIR="/opt/homebrew/var/www/$DOMAIN"
sudo mkdir -p "$PROJECT_DIR/public"
sudo chown -R $(whoami):admin "$PROJECT_DIR"
sudo chmod -R 755 "$PROJECT_DIR"
check_status "Đã tạo thư mục dự án và phân quyền" || exit 1

# Create index.php
echo -e "${BLUE}Tạo file index.php...${NORMAL}"
cat > "$PROJECT_DIR/public/index.php" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to $DOMAIN</title>
    <style>
        body { 
            font-family: Arial, sans-serif;
            margin: 40px;
            text-align: center;
            background-color: #f5f5f5;
        }
        .container {
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            max-width: 600px;
            margin: 0 auto;
        }
        h1 { 
            color: #333;
            margin-bottom: 20px;
        }
        .info {
            color: #666;
            line-height: 1.6;
        }
        .success {
            color: #4CAF50;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to $DOMAIN</h1>
        <div class="info">
            <p class="success">✨ Project created successfully!</p>
            <p>PHP Version: <?php echo PHP_VERSION; ?></p>
            <p>Server Time: <?php echo date('Y-m-d H:i:s'); ?></p>
        </div>
    </div>
</body>
</html>
EOF
check_status "Đã tạo file index.php" || exit 1

# Create SSL directory if not exists
echo -e "${BLUE}Tạo thư mục SSL...${NORMAL}"
SSL_DIR="/opt/homebrew/etc/nginx/ssl"
sudo mkdir -p "$SSL_DIR"
sudo chown $(whoami):admin "$SSL_DIR"
check_status "Đã tạo thư mục SSL" || exit 1

# Generate SSL certificate
echo -e "${BLUE}Tạo SSL certificate...${NORMAL}"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$SSL_DIR/$DOMAIN.key" \
    -out "$SSL_DIR/$DOMAIN.crt" \
    -subj "/CN=$DOMAIN" \
    -addext "subjectAltName=DNS:$DOMAIN"
check_status "Đã tạo SSL certificate" || exit 1

# Set proper permissions for SSL files
sudo chmod 644 "$SSL_DIR/$DOMAIN.key"
sudo chmod 644 "$SSL_DIR/$DOMAIN.crt"
sudo chown $(whoami):admin "$SSL_DIR/$DOMAIN.key"
sudo chown $(whoami):admin "$SSL_DIR/$DOMAIN.crt"

# Create Nginx configuration
echo -e "${BLUE}Tạo cấu hình Nginx...${NORMAL}"
NGINX_AVAILABLE="/opt/homebrew/etc/nginx/sites-available"
NGINX_ENABLED="/opt/homebrew/etc/nginx/sites-enabled"

# Ensure directories exist with correct permissions
sudo mkdir -p "$NGINX_AVAILABLE" "$NGINX_ENABLED"
sudo chown -R $(whoami):admin "$NGINX_AVAILABLE" "$NGINX_ENABLED"

# Create fastcgi_params if not exists
if [ ! -f "/opt/homebrew/etc/nginx/fastcgi_params" ]; then
    echo -e "${BLUE}Tạo file fastcgi_params...${NORMAL}"
    sudo tee /opt/homebrew/etc/nginx/fastcgi_params << 'EOL'
fastcgi_param  QUERY_STRING       $query_string;
fastcgi_param  REQUEST_METHOD     $request_method;
fastcgi_param  CONTENT_TYPE       $content_type;
fastcgi_param  CONTENT_LENGTH     $content_length;

fastcgi_param  SCRIPT_NAME        $fastcgi_script_name;
fastcgi_param  REQUEST_URI        $request_uri;
fastcgi_param  DOCUMENT_URI       $document_uri;
fastcgi_param  DOCUMENT_ROOT      $document_root;
fastcgi_param  SERVER_PROTOCOL    $server_protocol;
fastcgi_param  REQUEST_SCHEME     $scheme;
fastcgi_param  HTTPS             $https if_not_empty;

fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
fastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;

fastcgi_param  REMOTE_ADDR        $remote_addr;
fastcgi_param  REMOTE_PORT        $remote_port;
fastcgi_param  SERVER_ADDR        $server_addr;
fastcgi_param  SERVER_PORT        $server_port;
fastcgi_param  SERVER_NAME        $server_name;

fastcgi_param  REDIRECT_STATUS    200;
EOL
    sudo chmod 644 /opt/homebrew/etc/nginx/fastcgi_params
    sudo chown $(whoami):admin /opt/homebrew/etc/nginx/fastcgi_params
    check_status "Đã tạo file fastcgi_params" || exit 1
fi

# Create temporary file
TMP_CONFIG="/tmp/nginx_$DOMAIN"
cat > "$TMP_CONFIG" << EOF
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl;
    http2 on;
    server_name $DOMAIN;
    root $PROJECT_DIR/public;

    # SSL Configuration
    ssl_certificate     $SSL_DIR/$DOMAIN.crt;
    ssl_certificate_key $SSL_DIR/$DOMAIN.key;
    
    # SSL Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    
    index index.php index.html;
    charset utf-8;

    # Logs
    access_log /opt/homebrew/var/log/nginx/$DOMAIN-access.log combined;
    error_log /opt/homebrew/var/log/nginx/$DOMAIN-error.log warn;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_index index.php;
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
        fastcgi_read_timeout 600;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }

    # Browser Caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|eot|ttf|woff|woff2)$ {
        expires max;
        add_header Cache-Control "public, no-transform";
    }
}
EOF

# Move config file to sites-available with sudo
sudo mv "$TMP_CONFIG" "$NGINX_AVAILABLE/$DOMAIN"
sudo chmod 644 "$NGINX_AVAILABLE/$DOMAIN"
check_status "Đã tạo cấu hình Nginx" || exit 1

# Create symbolic link
echo -e "${BLUE}Tạo symbolic link...${NORMAL}"
ln -sf "$NGINX_AVAILABLE/$DOMAIN" "$NGINX_ENABLED/"
check_status "Đã tạo symbolic link" || exit 1

# Update hosts file
echo -e "${BLUE}Cập nhật file hosts...${NORMAL}"
if ! grep -q "$DOMAIN" /etc/hosts; then
    echo "127.0.0.1       $DOMAIN" | sudo tee -a /etc/hosts > /dev/null
    check_status "Đã thêm domain vào hosts file" || exit 1
else
    echo -e "${ORANGE}Domain đã tồn tại trong hosts file${NORMAL}"
fi

# Test Nginx configuration and restart
echo -e "${BLUE}Kiểm tra và khởi động lại Nginx...${NORMAL}"
nginx -t && brew services restart nginx
check_status "Đã khởi động lại Nginx" || exit 1

# Start PHP-FPM if not running
echo -e "${BLUE}Kiểm tra và khởi động PHP-FPM...${NORMAL}"
brew services start php@$PHP_VERSION
check_status "Đã khởi động PHP-FPM" || exit 1

echo -e "\n${GREEN}=== Cài đặt hoàn tất! ===${NORMAL}"
echo -e "Website: ${ORANGE}https://$DOMAIN${NORMAL}"
echo -e "Thư mục: ${ORANGE}$PROJECT_DIR${NORMAL}"
echo -e "SSL Certificate: ${ORANGE}$SSL_DIR/$DOMAIN.crt${NORMAL}"
echo -e "Nginx Config: ${ORANGE}$NGINX_AVAILABLE/$DOMAIN${NORMAL}"

# Mở thư mục trong Finder
echo -e "\n${BLUE}Mở thư mục dự án trong Finder...${NORMAL}"
open "$PROJECT_DIR"

echo -e "\n${BLUE}Lưu ý:${NORMAL}"
echo -e "1. Nếu trình duyệt cảnh báo về certificate, hãy thêm certificate vào Keychain"
echo -e "2. Để thêm certificate vào Keychain:"
echo -e "   ${ORANGE}sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $SSL_DIR/$DOMAIN.crt${NORMAL}"
echo -e "3. Xóa cache DNS nếu cần:"
echo -e "   ${ORANGE}sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder${NORMAL}"
echo -e "\n${BLUE}Các lệnh hữu ích:${NORMAL}"
echo -e "- Mở thư mục dự án: ${ORANGE}open $PROJECT_DIR${NORMAL}"
echo -e "- Mở thư mục cấu hình Nginx: ${ORANGE}open /opt/homebrew/etc/nginx${NORMAL}"
echo -e "- Mở thư mục SSL: ${ORANGE}open $SSL_DIR${NORMAL}\n" 