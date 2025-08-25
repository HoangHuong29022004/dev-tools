#!/bin/bash

# Colors
GREEN="\\033[1;32m"
RED="\\033[1;31m"
BLUE="\\033[1;34m"
NORMAL="\\033[0;39m"

echo -e "${BLUE}🚀 Nginx Multi-PHP Setup Tool${NORMAL}"
echo "================================"
echo ""

# Chọn thư mục dự án
read -p "Nhập tên dự án (vd: my-project): " project_name
project_name=$(echo "$project_name" | tr -cd '[:alnum:].-' | tr '[:upper:]' '[:lower:]')

if [ -z "$project_name" ]; then
    echo -e "${RED}❌ Tên dự án không được để trống!${NORMAL}"
    exit 1
fi

# Tạo domain
domain="${project_name}.code"
echo -e "${GREEN}✅ Domain: $domain${NORMAL}"

# Chọn PHP version
echo ""
echo "Chọn phiên bản PHP:"
echo "1) PHP 7.4"
echo "2) PHP 8.0" 
echo "3) PHP 8.1"
echo "4) PHP 8.2"
echo "5) PHP 8.3"
read -p "Nhập lựa chọn (1-5): " php_choice

case $php_choice in
    1) php_version="7.4"; php_port="9074" ;;
    2) php_version="8.0"; php_port="9080" ;;
    3) php_version="8.1"; php_port="9081" ;;
    4) php_version="8.2"; php_port="9082" ;;
    5) php_version="8.3"; php_port="9083" ;;
    *) echo -e "${RED}❌ Lựa chọn không hợp lệ!${NORMAL}"; exit 1 ;;
esac

echo -e "${GREEN}✅ PHP Version: $php_version (Port: $php_port)${NORMAL}"

# Tạo thư mục dự án
project_path="/opt/homebrew/var/www/$project_name"
sudo mkdir -p "$project_path/public"
sudo chown -R $(whoami):admin "$project_path"
sudo chmod -R 755 "$project_path"

# Tạo file index.php
cat > "$project_path/public/index.php" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>🚀 <?php echo $_SERVER['HTTP_HOST'] ?? 'unknown'; ?> - PHP <?php echo PHP_VERSION; ?></title>
    <meta charset="utf-8">
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 40px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: rgba(255, 255, 255, 0.1);
            padding: 40px;
            border-radius: 20px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        }
        h1 { 
            text-align: center;
            margin-bottom: 30px;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-top: 30px;
        }
        .info-card {
            background: rgba(255, 255, 255, 0.2);
            padding: 20px;
            border-radius: 15px;
            text-align: center;
            backdrop-filter: blur(5px);
        }
        .info-card h3 {
            margin: 0 0 10px 0;
            color: #ffd700;
        }
        .info-card p {
            margin: 0;
            font-size: 1.1em;
        }
        .success {
            background: rgba(76, 175, 80, 0.3);
            border: 2px solid #4CAF50;
            padding: 15px;
            border-radius: 10px;
            text-align: center;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Welcome to <?php echo $_SERVER['HTTP_HOST'] ?? 'unknown'; ?></h1>
        
        <div class="success">
            <h3>✨ PHP <?php echo PHP_VERSION; ?> Setup thành công!</h3>
            <p>Bạn đã thoát khỏi trang "Welcome to Nginx!" mặc định!</p>
        </div>
        
        <div class="info-grid">
            <div class="info-card">
                <h3>🐘 PHP Version</h3>
                <p><?php echo PHP_VERSION; ?></p>
            </div>
            
            <div class="info-card">
                <h3>🕐 Server Time</h3>
                <p><?php echo date('Y-m-d H:i:s'); ?></p>
            </div>
            
            <div class="info-card">
                <h3>🌐 Domain</h3>
                <p><?php echo $_SERVER['HTTP_HOST'] ?? 'unknown'; ?></p>
            </div>
            
            <div class="info-card">
                <h3>📁 Project Path</h3>
                <p><?php echo __DIR__; ?></p>
            </div>
        </div>
        
        <div style="margin-top: 30px; text-align: center; opacity: 0.8;">
            <p>🚀 Powered by Nginx + PHP-FPM</p>
            <p>✅ Không còn "Welcome to Nginx!" mặc định nữa!</p>
        </div>
    </div>
</body>
</html>
EOF

# Tạo SSL certificate bằng mkcert (locally-trusted)
ssl_dir="/opt/homebrew/etc/nginx/ssl"
sudo mkdir -p "$ssl_dir"
sudo chown $(whoami):admin "$ssl_dir"

echo -e "${BLUE}🔒 Tạo SSL certificate bằng mkcert (locally-trusted)...${NORMAL}"

# Cài đặt mkcert nếu chưa có
if ! command -v mkcert &> /dev/null; then
    echo -e "${BLUE}📦 Cài đặt mkcert...${NORMAL}"
    brew install mkcert
    mkcert -install
fi

cd "$ssl_dir"
mkcert "$domain" "*.$domain" localhost 127.0.0.1 ::1
cp "$domain+4.pem" "$domain.crt"
cp "$domain+4-key.pem" "$domain.key"
sudo chmod 644 "$domain.key" "$domain.crt"
sudo chown $(whoami):admin "$domain.key" "$domain.crt"
cd - > /dev/null

echo -e "${GREEN}✅ SSL certificate đã được tạo (locally-trusted)!${NORMAL}"

# Tạo cấu hình Nginx
nginx_conf="/opt/homebrew/etc/nginx/sites-available/$domain"
sudo mkdir -p /opt/homebrew/etc/nginx/sites-available
sudo mkdir -p /opt/homebrew/etc/nginx/sites-enabled

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

# Tạo symbolic link
sudo ln -sf "$nginx_conf" "/opt/homebrew/etc/nginx/sites-enabled/$domain"

# Thêm vào hosts file
if ! grep -q "$domain" /etc/hosts; then
    echo "127.0.0.1       $domain" | sudo tee -a /etc/hosts > /dev/null
fi

# Sửa quyền
sudo chown -R $(whoami):admin /opt/homebrew/etc/nginx
sudo chmod -R 755 /opt/homebrew/etc/nginx

# Kiểm tra và restart Nginx
if nginx -t; then
    brew services restart nginx
    echo -e "${GREEN}✅ Setup hoàn tất!${NORMAL}"
    echo -e "${BLUE}🌐 Domain: https://$domain${NORMAL}"
    echo -e "${BLUE}📁 Thư mục: $project_path${NORMAL}"
    echo -e "${BLUE}🔒 SSL: Locally-trusted certificate (mkcert)${NORMAL}"
    echo -e "${BLUE}💡 Không còn cảnh báo 'Your connection is not private'!${NORMAL}"
else
    echo -e "${RED}❌ Cấu hình Nginx có lỗi!${NORMAL}"
    exit 1
fi
