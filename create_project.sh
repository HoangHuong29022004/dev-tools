#!/bin/bash

# Colors
GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
NORMAL="\033[0;39m"

echo -e "${BLUE}🚀 Project Creator - Tạo Project Nhanh & Dễ${NORMAL}"
echo "============================================="
echo ""

# Function để kill nginx an toàn
kill_nginx_safe() {
    echo -e "${YELLOW}🔧 Dọn dẹp nginx cũ...${NORMAL}"
    
    # Kill tất cả nginx processes
    sudo pkill -9 -f nginx 2>/dev/null || true
    sleep 2
    
    # Kiểm tra còn nginx không
    if pgrep -f nginx > /dev/null; then
        echo -e "${RED}❌ Vẫn còn nginx! Thử kill manual...${NORMAL}"
        sudo kill -9 $(pgrep -f nginx) 2>/dev/null || true
        sleep 2
    fi
    
    echo -e "${GREEN}✅ Đã dọn dẹp nginx!${NORMAL}"
}

# Function để start nginx đơn giản
start_nginx_simple() {
    echo -e "${BLUE}🚀 Start nginx...${NORMAL}"
    
    # Start nginx trực tiếp thay vì qua brew services
    sudo nginx -c /opt/homebrew/etc/nginx/nginx.conf
    
    sleep 2
    
    if pgrep -f "nginx.*master" > /dev/null; then
        echo -e "${GREEN}✅ Nginx đã start!${NORMAL}"
        return 0
    else
        echo -e "${RED}❌ Nginx không start được!${NORMAL}"
        return 1
    fi
}

# Nhập thông tin project
read -p "Tên project (vd: my-project): " project_name
project_name=$(echo "$project_name" | tr -cd '[:alnum:].-' | tr '[:upper:]' '[:lower:]')

if [ -z "$project_name" ]; then
    echo -e "${RED}❌ Tên project không được để trống!${NORMAL}"
    exit 1
fi

domain="${project_name}.test"
echo -e "${GREEN}✅ Domain: $domain${NORMAL}"

# Chọn PHP version
echo ""
echo -e "${BLUE}Chọn PHP version:${NORMAL}"
echo "1) PHP 7.4 (Port 9074)"
echo "2) PHP 8.0 (Port 9080)"
echo "3) PHP 8.1 (Port 9081)"
echo "4) PHP 8.2 (Port 9082) - Khuyến nghị"
echo "5) PHP 8.3 (Port 9083)"
echo "6) PHP 8.4 (Port 9084)"
read -p "Lựa chọn (1-6): " php_choice

case $php_choice in
    1) php_version="7.4"; php_port="9074" ;;
    2) php_version="8.0"; php_port="9080" ;;
    3) php_version="8.1"; php_port="9081" ;;
    4) php_version="8.2"; php_port="9082" ;;
    5) php_version="8.3"; php_port="9083" ;;
    6) php_version="8.4"; php_port="9084" ;;
    *) php_version="8.2"; php_port="9082" ;;
esac

echo -e "${GREEN}✅ PHP: $php_version (Port: $php_port)${NORMAL}"

# Dọn dẹp nginx cũ
kill_nginx_safe

# Tạo thư mục project
project_path="/opt/homebrew/var/www/$project_name"
echo -e "${BLUE}📁 Tạo thư mục project...${NORMAL}"
sudo mkdir -p "$project_path/public"
sudo chown -R $(whoami):admin "$project_path"
sudo chmod -R 755 "$project_path"

# Tạo file index.php đẹp
echo -e "${BLUE}📝 Tạo file index.php...${NORMAL}"
cat > "$project_path/public/index.php" << EOF
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🚀 $domain - PHP $php_version</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
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
            width: 90%;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
            text-align: center;
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
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }
        .info-card {
            background: rgba(255, 255, 255, 0.2);
            padding: 15px;
            border-radius: 10px;
            backdrop-filter: blur(5px);
        }
        .info-card h3 {
            color: #ffd700;
            margin-bottom: 10px;
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
        <h1>🎉 Welcome to $domain</h1>
        
        <div class="success">
            <h3>✨ Setup thành công!</h3>
            <p>PHP <?php echo PHP_VERSION; ?> đang hoạt động hoàn hảo!</p>
        </div>
        
        <div class="info-grid">
            <div class="info-card">
                <h3>🌐 Domain</h3>
                <p><?php echo \$_SERVER['HTTP_HOST'] ?? 'unknown'; ?></p>
            </div>
            
            <div class="info-card">
                <h3>🐘 PHP Version</h3>
                <p><?php echo PHP_VERSION; ?></p>
            </div>
            
            <div class="info-card">
                <h3>🕐 Server Time</h3>
                <p><?php echo date('Y-m-d H:i:s'); ?></p>
            </div>
            
            <div class="info-card">
                <h3>📁 Project Path</h3>
                <p><?php echo basename(__DIR__); ?></p>
            </div>
        </div>
        
        <div class="footer">
            <p>🚀 Powered by Nginx + PHP-FPM</p>
            <p>✅ Không còn lỗi SSL hay xung đột!</p>
        </div>
    </div>
</body>
</html>
EOF

# Tạo SSL certificate
echo -e "${BLUE}🔒 Tạo SSL certificate...${NORMAL}"
ssl_dir="/opt/homebrew/etc/nginx/ssl"
sudo mkdir -p "$ssl_dir"
sudo chown $(whoami):admin "$ssl_dir"

cd "$ssl_dir"

# Kiểm tra xem certificate đã tồn tại chưa
if [ -f "$domain.crt" ]; then
    echo -e "${YELLOW}⚠️  Certificate đã tồn tại, tạo mới...${NORMAL}"
    rm -f "$domain.crt" "$domain.key" "$domain+2.pem" "$domain+2-key.pem"
fi

mkcert "$domain" localhost 127.0.0.1
cp "$domain+2.pem" "$domain.crt"
cp "$domain+2-key.pem" "$domain.key"
sudo chmod 644 "$domain.key" "$domain.crt"
sudo chown $(whoami):admin "$domain.key" "$domain.crt"
cd - > /dev/null

echo -e "${GREEN}✅ SSL certificate đã tạo!${NORMAL}"

# Tạo nginx config
echo -e "${BLUE}⚙️  Tạo nginx config...${NORMAL}"
nginx_conf="/opt/homebrew/etc/nginx/sites-available/$domain"

# Xóa config cũ nếu có
if [ -f "$nginx_conf" ]; then
    rm -f "$nginx_conf"
fi

cat > "$nginx_conf" << EOF
server {
    listen 80;
    server_name $domain;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl;
    http2 on;
    server_name $domain;
    root $project_path/public;
    
    ssl_certificate     $ssl_dir/$domain.crt;
    ssl_certificate_key $ssl_dir/$domain.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    
    index index.php index.html;
    charset utf-8;
    client_max_body_size 100M;
    
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    access_log /opt/homebrew/var/log/nginx/$domain-access.log combined;
    error_log /opt/homebrew/var/log/nginx/$domain-error.log warn;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }
    
    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:$php_port;
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
}
EOF

# Tạo symlink
echo -e "${BLUE}🔗 Tạo symlink...${NORMAL}"
sudo ln -sf "$nginx_conf" "/opt/homebrew/etc/nginx/sites-enabled/$domain"

# Thêm vào hosts file
echo -e "${BLUE}📝 Thêm vào hosts file...${NORMAL}"
if ! grep -q "$domain" /etc/hosts; then
    echo "127.0.0.1       $domain" | sudo tee -a /etc/hosts > /dev/null
fi

# Sửa quyền
sudo chown -R $(whoami):admin /opt/homebrew/etc/nginx
sudo chmod -R 755 /opt/homebrew/etc/nginx

# Test nginx config
echo -e "${BLUE}🔧 Test nginx config...${NORMAL}"
if nginx -t; then
    echo -e "${GREEN}✅ Nginx config OK!${NORMAL}"
    
    # Start nginx
    if start_nginx_simple; then
        echo ""
        echo -e "${GREEN}🎉🎉🎉 SETUP HOÀN TẤT! 🎉🎉🎉${NORMAL}"
        echo ""
        echo -e "${BLUE}🌐 Website: https://$domain${NORMAL}"
        echo -e "${BLUE}📁 Thư mục: $project_path${NORMAL}"
        echo -e "${BLUE}🐘 PHP: $php_version (Port: $php_port)${NORMAL}"
        echo -e "${BLUE}🔒 SSL: Locally-trusted (mkcert)${NORMAL}"
        echo ""
        echo -e "${GREEN}💡 Test ngay:${NORMAL}"
        echo -e "${GREEN}   curl -I https://$domain${NORMAL}"
        echo -e "${GREEN}   hoặc mở browser: https://$domain${NORMAL}"
        echo ""
        echo -e "${YELLOW}✨ Không còn lỗi SSL hay xung đột!${NORMAL}"
    else
        echo -e "${RED}❌ Nginx không start được!${NORMAL}"
        echo -e "${BLUE}💡 Kiểm tra logs: tail -f /opt/homebrew/var/log/nginx/error.log${NORMAL}"
    fi
else
    echo -e "${RED}❌ Nginx config có lỗi!${NORMAL}"
    echo -e "${BLUE}💡 Kiểm tra: nginx -t${NORMAL}"
fi