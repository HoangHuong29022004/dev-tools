#!/bin/bash

# Colors
GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
NORMAL="\033[0;39m"

echo -e "${BLUE}🌐 Nginx Installer - Cài đặt Nginx${NORMAL}"
echo "====================================="
echo ""

# Function để cài đặt Nginx
install_nginx() {
    echo -e "${BLUE}📦 Cài đặt Nginx...${NORMAL}"
    
    # Cài đặt Nginx
    if brew install nginx; then
        echo -e "${GREEN}✅ Nginx đã cài đặt!${NORMAL}"
        
        # Tạo thư mục cần thiết
        echo -e "${BLUE}📁 Tạo thư mục...${NORMAL}"
        sudo mkdir -p /opt/homebrew/var/www
        sudo mkdir -p /opt/homebrew/var/log/nginx
        sudo mkdir -p /opt/homebrew/etc/nginx/sites-available
        sudo mkdir -p /opt/homebrew/etc/nginx/sites-enabled
        sudo mkdir -p /opt/homebrew/etc/nginx/ssl
        
        # Sửa quyền
        sudo chown -R $(whoami):admin /opt/homebrew/var/www
        sudo chown -R $(whoami):admin /opt/homebrew/var/log/nginx
        sudo chown -R $(whoami):admin /opt/homebrew/etc/nginx
        
        # Tạo nginx.conf
        echo -e "${BLUE}⚙️  Tạo nginx.conf...${NORMAL}"
        cat > /opt/homebrew/etc/nginx/nginx.conf << 'EOF'
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
EOF
        
        # Cài đặt mkcert
        echo -e "${BLUE}🔒 Cài đặt mkcert...${NORMAL}"
        if ! command -v mkcert &> /dev/null; then
            brew install mkcert
            mkcert -install
            echo -e "${GREEN}✅ mkcert đã cài đặt!${NORMAL}"
        else
            echo -e "${YELLOW}⚠️  mkcert đã cài đặt!${NORMAL}"
        fi
        
        # Tạo file index.html mặc định
        echo -e "${BLUE}📝 Tạo file index.html mặc định...${NORMAL}"
        cat > /opt/homebrew/var/www/index.html << 'EOF'
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🌐 Nginx đã sẵn sàng!</title>
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 40px;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 40px;
            max-width: 600px;
            text-align: center;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        }
        h1 { 
            font-size: 2.5em; 
            margin-bottom: 20px;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
        }
        .success {
            background: rgba(76, 175, 80, 0.3);
            border: 2px solid #4CAF50;
            padding: 20px;
            border-radius: 15px;
            margin: 20px 0;
        }
        .info {
            background: rgba(255, 255, 255, 0.2);
            padding: 20px;
            border-radius: 15px;
            margin: 20px 0;
            backdrop-filter: blur(5px);
        }
        .footer {
            margin-top: 30px;
            opacity: 0.8;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 Nginx đã sẵn sàng!</h1>
        
        <div class="success">
            <h3>✅ Cài đặt thành công!</h3>
            <p>Nginx đã được cài đặt và cấu hình hoàn tất!</p>
        </div>
        
        <div class="info">
            <h3>📋 Thông tin:</h3>
            <p><strong>Nginx Version:</strong> $(nginx -v 2>&1)</p>
            <p><strong>Config Path:</strong> /opt/homebrew/etc/nginx/nginx.conf</p>
            <p><strong>Web Root:</strong> /opt/homebrew/var/www</p>
            <p><strong>Logs:</strong> /opt/homebrew/var/log/nginx/</p>
        </div>
        
        <div class="footer">
            <p>🚀 Powered by Nginx</p>
            <p>💡 Sử dụng ./create_project.sh để tạo project mới</p>
        </div>
    </div>
</body>
</html>
EOF
        
        echo -e "${GREEN}✅ Nginx đã cài đặt và cấu hình hoàn tất!${NORMAL}"
        echo ""
        echo -e "${BLUE}📋 Thông tin:${NORMAL}"
        echo -e "${BLUE}   Config: /opt/homebrew/etc/nginx/nginx.conf${NORMAL}"
        echo -e "${BLUE}   Web Root: /opt/homebrew/var/www${NORMAL}"
        echo -e "${BLUE}   Logs: /opt/homebrew/var/log/nginx/${NORMAL}"
        echo ""
        echo -e "${GREEN}💡 Sử dụng ./create_project.sh để tạo project mới${NORMAL}"
        echo -e "${GREEN}💡 Sử dụng ./nginx_manager.sh để quản lý nginx${NORMAL}"
        
        return 0
    else
        echo -e "${RED}❌ Không thể cài đặt Nginx!${NORMAL}"
        return 1
    fi
}

# Function để kiểm tra Nginx đã cài
check_nginx() {
    if brew list nginx &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Main
if check_nginx; then
    echo -e "${YELLOW}⚠️  Nginx đã cài đặt!${NORMAL}"
    echo -e "${BLUE}💡 Sử dụng ./nginx_manager.sh để quản lý nginx${NORMAL}"
    echo -e "${BLUE}💡 Sử dụng ./create_project.sh để tạo project mới${NORMAL}"
else
    echo -e "${BLUE}🔍 Nginx chưa cài đặt, đang cài đặt...${NORMAL}"
    install_nginx
fi