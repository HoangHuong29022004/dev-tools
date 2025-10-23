#!/bin/bash

GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
NORMAL="\033[0;39m"

echo -e "${BLUE}🚀 Project Creator${NORMAL}"
echo ""

# Setup directories một lần (gộp tất cả sudo)
setup_once() {
    echo -e "${YELLOW}⚙️  Setup directories (nhập sudo password)...${NORMAL}"
    sudo bash -c "
        mkdir -p /opt/homebrew/var/run/nginx/{client_body_temp,proxy_temp,fastcgi_temp} \
                 /opt/homebrew/var/log/nginx \
                 /opt/homebrew/etc/nginx/{sites-available,sites-enabled,ssl} \
                 /opt/homebrew/var/www &&
        chown -R $(whoami):admin /opt/homebrew/var/{log/nginx,www} /opt/homebrew/etc/nginx &&
        chmod -R 755 /opt/homebrew/var/{log/nginx,www} /opt/homebrew/etc/nginx &&
        chmod -R 777 /opt/homebrew/var/run/nginx &&
        pkill -9 -f nginx
    " 2>/dev/null
    sleep 1
}

start_nginx() {
    sudo nginx -c /opt/homebrew/etc/nginx/nginx.conf 2>/dev/null
    sleep 1
    pgrep -f "nginx.*master" > /dev/null && echo -e "${GREEN}✅ Nginx started${NORMAL}"
}

read -p "Tên project: " project_name
project_name=$(echo "$project_name" | tr -cd '[:alnum:].-' | tr '[:upper:]' '[:lower:]')
[ -z "$project_name" ] && { echo -e "${RED}❌ Tên trống!${NORMAL}"; exit 1; }

domain="${project_name}.test"
echo -e "${GREEN}✅ Domain: $domain${NORMAL}"

echo ""
echo "1) PHP 7.4 | 2) PHP 8.0 | 3) PHP 8.1"
echo "4) PHP 8.2 | 5) PHP 8.3 | 6) PHP 8.4"
read -p "Chọn (1-6, mặc định 4): " php_choice

case $php_choice in
    1) php_version="7.4"; php_port="9074" ;;
    2) php_version="8.0"; php_port="9080" ;;
    3) php_version="8.1"; php_port="9081" ;;
    4) php_version="8.2"; php_port="9082" ;;
    5) php_version="8.3"; php_port="9083" ;;
    6) php_version="8.4"; php_port="9084" ;;
    *) php_version="8.2"; php_port="9082" ;;
esac

echo -e "${GREEN}✅ PHP $php_version (Port $php_port)${NORMAL}"
echo ""

setup_once

project_path="/opt/homebrew/var/www/$project_name"
echo -e "${BLUE}📁 Tạo project...${NORMAL}"
mkdir -p "$project_path/public"
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

echo -e "${BLUE}🔒 SSL...${NORMAL}"
ssl_dir="/opt/homebrew/etc/nginx/ssl"
cd "$ssl_dir"
rm -f "$domain"* 2>/dev/null
mkcert "$domain" localhost 127.0.0.1 > /dev/null 2>&1
cp "$domain+2.pem" "$domain.crt"
cp "$domain+2-key.pem" "$domain.key"
cd - > /dev/null

echo -e "${BLUE}⚙️  Nginx config...${NORMAL}"
nginx_conf="/opt/homebrew/etc/nginx/sites-available/$domain"

cat > "$nginx_conf" << EOF
server {
    listen 80;
    server_name $domain;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domain;
    root $project_path/public;
    
    ssl_certificate     $ssl_dir/$domain.crt;
    ssl_certificate_key $ssl_dir/$domain.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    
    index index.php index.html;
    charset utf-8;
    client_max_body_size 100M;
    
    access_log /opt/homebrew/var/log/nginx/$domain-access.log;
    error_log /opt/homebrew/var/log/nginx/$domain-error.log;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }
    
    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:$php_port;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
    }
    
    location ~ /\. { deny all; }
}
EOF

ln -sf "$nginx_conf" "/opt/homebrew/etc/nginx/sites-enabled/$domain"

grep -q "$domain" /etc/hosts || echo "127.0.0.1 $domain" | sudo tee -a /etc/hosts > /dev/null

echo -e "${BLUE}🚀 Start nginx...${NORMAL}"
if nginx -t 2>/dev/null; then
    start_nginx
    echo ""
    echo -e "${GREEN}🎉 XONG!${NORMAL}"
    echo ""
    echo -e "${BLUE}🌐 https://$domain${NORMAL}"
    echo -e "${BLUE}📁 $project_path${NORMAL}"
    echo -e "${BLUE}🐘 PHP $php_version${NORMAL}"
    echo ""
else
    echo -e "${RED}❌ Nginx config lỗi!${NORMAL}"
fi