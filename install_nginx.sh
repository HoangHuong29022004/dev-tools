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

# Check if script is run with sudo
if [ "$EUID" -eq 0 ]; then
    print_color "red" "❌ Không nên chạy script này với sudo."
    print_color "blue" "Vui lòng chạy lại không có sudo: bash install_nginx.sh"
    exit 1
fi

# Check and install Homebrew if not installed
if ! command_exists brew; then
    print_color "blue" "📦 Đang cài đặt Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install Nginx
print_color "blue" "📦 Đang cài đặt Nginx..."
brew install nginx || {
    print_color "red" "❌ Lỗi cài đặt Nginx"
    exit 1
}

# Create necessary directories
print_color "blue" "⚙️ Tạo cấu trúc thư mục..."
mkdir -p /opt/homebrew/etc/nginx/{sites-available,sites-enabled,ssl}
mkdir -p /opt/homebrew/var/{www,log/nginx}
mkdir -p /opt/homebrew/var/run/nginx/{client_body_temp,proxy_temp,fastcgi_temp,uwsgi_temp,scgi_temp}
chown -R $(whoami):admin /opt/homebrew/var/www
chown -R $(whoami):admin /opt/homebrew/var/log/nginx
chmod -R 755 /opt/homebrew/var/{log/nginx,run/nginx}

# Copy mime.types from Homebrew
print_color "blue" "📄 Copy file mime.types..."
NGINX_PREFIX=$(brew --prefix nginx)
MIME_TYPES_PATHS=(
    "$NGINX_PREFIX/share/nginx/mime.types"
    "/usr/local/etc/nginx/mime.types"
    "/etc/nginx/mime.types"
)

MIME_FOUND=0
for mime_path in "${MIME_TYPES_PATHS[@]}"; do
    if [ -f "$mime_path" ]; then
        cp "$mime_path" /opt/homebrew/etc/nginx/mime.types
        chown $(whoami):admin /opt/homebrew/etc/nginx/mime.types
        chmod 644 /opt/homebrew/etc/nginx/mime.types
        MIME_FOUND=1
        break
    fi
done

if [ $MIME_FOUND -eq 0 ]; then
    print_color "blue" "Tạo file mime.types mới..."
    tee /opt/homebrew/etc/nginx/mime.types << 'EOL'
types {
    text/html                                        html htm shtml;
    text/css                                         css;
    text/xml                                         xml;
    image/gif                                        gif;
    image/jpeg                                       jpeg jpg;
    application/javascript                           js;
    application/atom+xml                             atom;
    application/rss+xml                             rss;

    text/plain                                       txt;
    text/vnd.wap.wml                                wml;
    application/json                                 json;

    image/png                                        png;
    image/tiff                                       tif tiff;
    image/vnd.wap.wbmp                              wbmp;
    image/x-icon                                     ico;
    image/x-jng                                      jng;
    image/x-ms-bmp                                   bmp;
    image/svg+xml                                    svg svgz;
    image/webp                                       webp;

    application/font-woff                            woff;
    application/java-archive                         jar war ear;
    application/mac-binhex40                         hqx;
    application/msword                               doc;
    application/pdf                                  pdf;
    application/postscript                           ps eps ai;
    application/rtf                                  rtf;
    application/vnd.apple.mpegurl                    m3u8;
    application/vnd.ms-excel                         xls;
    application/vnd.ms-fontobject                    eot;
    application/vnd.ms-powerpoint                    ppt;
    application/vnd.wap.wmlc                         wmlc;
    application/vnd.google-earth.kml+xml             kml;
    application/vnd.google-earth.kmz                 kmz;
    application/x-7z-compressed                      7z;
    application/x-cocoa                              cco;
    application/x-java-archive-diff                  jardiff;
    application/x-java-jnlp-file                     jnlp;
    application/x-makeself                           run;
    application/x-perl                               pl pm;
    application/x-pilot                              prc pdb;
    application/x-rar-compressed                     rar;
    application/x-redhat-package-manager             rpm;
    application/x-sea                                sea;
    application/x-shockwave-flash                    swf;
    application/x-stuffit                            sit;
    application/x-tcl                                tcl tk;
    application/x-x509-ca-cert                       der pem crt;
    application/x-xpinstall                          xpi;
    application/xhtml+xml                            xhtml;
    application/xspf+xml                             xspf;
    application/zip                                  zip;

    application/octet-stream                         bin exe dll;
    application/octet-stream                         deb;
    application/octet-stream                         dmg;
    application/octet-stream                         iso img;
    application/octet-stream                         msi msp msm;

    audio/midi                                       mid midi kar;
    audio/mpeg                                       mp3;
    audio/ogg                                        ogg;
    audio/x-m4a                                      m4a;
    audio/x-realaudio                               ra;

    video/3gpp                                      3gpp 3gp;
    video/mp2t                                      ts;
    video/mp4                                       mp4;
    video/mpeg                                      mpeg mpg;
    video/quicktime                                 mov;
    video/webm                                      webm;
    video/x-flv                                     flv;
    video/x-m4v                                     m4v;
    video/x-mng                                     mng;
    video/x-ms-asf                                  asx asf;
    video/x-ms-wmv                                  wmv;
    video/x-msvideo                                 avi;
}
EOL
    chown $(whoami):admin /opt/homebrew/etc/nginx/mime.types
    chmod 644 /opt/homebrew/etc/nginx/mime.types
fi

# Create fastcgi_params file
print_color "blue" "📄 Tạo file fastcgi_params..."
tee /opt/homebrew/etc/nginx/fastcgi_params << 'EOL'
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

# Set proper permissions for fastcgi_params
chmod 644 /opt/homebrew/etc/nginx/fastcgi_params
chown $(whoami):admin /opt/homebrew/etc/nginx/fastcgi_params

# Ensure Nginx is stopped before configuration
brew services stop nginx 2>/dev/null

# Create main Nginx configuration
print_color "blue" "⚙️ Tạo file cấu hình chính..."
tee /opt/homebrew/etc/nginx/nginx.conf << 'EOL'
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
tee /opt/homebrew/etc/nginx/sites-available/default << 'EOL'
server {
    listen 8080;
    server_name localhost;
    root /opt/homebrew/var/www;
    index index.php index.html index.htm;

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

# Set proper permissions for Nginx directories
print_color "blue" "🔒 Thiết lập quyền truy cập..."
chown -R $(whoami):admin /opt/homebrew/etc/nginx
chmod -R 755 /opt/homebrew/etc/nginx
chmod 644 /opt/homebrew/etc/nginx/nginx.conf
chmod 644 /opt/homebrew/etc/nginx/sites-available/default

# Create symbolic link to enable default site
print_color "blue" "🔗 Kích hoạt virtual host mặc định..."
ln -sf /opt/homebrew/etc/nginx/sites-available/default /opt/homebrew/etc/nginx/sites-enabled/

# Create test files
print_color "blue" "📄 Tạo file test..."
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