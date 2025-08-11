#!/bin/bash

# Colors
NORMAL="\\033[0;39m"
GREEN="\\033[1;32m"
RED="\\033[1;31m"
BLUE="\\033[1;34m"
ORANGE="\\033[1;33m"
PURPLE="\\033[1;35m"

# Function to display text in color
print_color() {
    local color=$1
    local text=$2
    case $color in
        "green") echo -e "${GREEN}${text}${NORMAL}" ;;
        "red") echo -e "${RED}${text}${NORMAL}" ;;
        "blue") echo -e "${BLUE}${text}${NORMAL}" ;;
        "orange") echo -e "${ORANGE}${text}${NORMAL}" ;;
        "purple") echo -e "${PURPLE}${text}${NORMAL}" ;;
    esac
}

# Function to check if command executed successfully
check_status() {
    if [ $? -eq 0 ]; then
        print_color "green" "✓ $1"
    else
        print_color "red" "✗ $1"
        return 1
    fi
}

# Function to check if PHP version is installed
check_php_version() {
    local version=$1
    if [ -d "/opt/homebrew/opt/php@$version" ]; then
        return 0
    else
        return 1
    fi
}

# Function to fix system permissions
fix_system_permissions() {
    print_color "blue" "🔧 Sửa quyền hệ thống..."
    
    # Fix www directory permissions
    if [ -d "/opt/homebrew/var/www" ]; then
        sudo chown -R $(whoami):admin /opt/homebrew/var/www
        sudo chmod -R 755 /opt/homebrew/var/www
        print_color "green" "   ✅ Đã sửa quyền /opt/homebrew/var/www"
    fi
    
    # Fix nginx directories permissions
    if [ -d "/opt/homebrew/etc/nginx" ]; then
        sudo chown -R $(whoami):admin /opt/homebrew/etc/nginx
        sudo chmod -R 755 /opt/homebrew/etc/nginx
        print_color "green" "   ✅ Đã sửa quyền /opt/homebrew/etc/nginx"
    fi
    
    # Fix log directories permissions
    if [ -d "/opt/homebrew/var/log" ]; then
        sudo chown -R $(whoami):admin /opt/homebrew/var/log
        sudo chmod -R 755 /opt/homebrew/var/log
        print_color "green" "   ✅ Đã sửa quyền /opt/homebrew/var/log"
    fi
    
    # Fix run directory permissions
    if [ -d "/opt/homebrew/var/run" ]; then
        sudo chown -R $(whoami):admin /opt/homebrew/var/run
        sudo chmod -R 755 /opt/homebrew/var/run
        print_color "green" "   ✅ Đã sửa quyền /opt/homebrew/var/run"
    fi
    
    print_color "green" "✅ Hoàn tất sửa quyền hệ thống!"
}

# Function to fix nginx user directive
fix_nginx_user_directive() {
    print_color "blue" "🔧 Sửa cấu hình Nginx user directive..."
    
    local nginx_conf="/opt/homebrew/etc/nginx/nginx.conf"
    
    if [ -f "$nginx_conf" ]; then
        # Check if user directive exists and fix it
        if grep -q "^user " "$nginx_conf"; then
            # Remove user directive to avoid warning
            sudo sed -i '' '/^user /d' "$nginx_conf"
            print_color "green" "   ✅ Đã xóa user directive để tránh warning"
        fi
        
        # Ensure proper permissions
        sudo chown "$(whoami):admin" "$nginx_conf"
        sudo chmod 644 "$nginx_conf"
        print_color "green" "   ✅ Đã sửa quyền nginx.conf"
        
        print_color "green" "✅ Hoàn tất sửa cấu hình Nginx!"
    else
        print_color "red" "❌ Không tìm thấy nginx.conf!"
    fi
}

# Function to remove existing domain
remove_existing_domain() {
    local domain=$1
    local project_name=$(echo "$domain" | sed 's/\.code$//')
    
    print_color "orange" "⚠️ Domain $domain đã tồn tại!"
    print_color "blue" "🔍 Thông tin domain cũ:"
    
    # Show existing domain info
    if [ -f "/opt/homebrew/etc/nginx/sites-available/$domain" ]; then
        local php_version=$(grep "fastcgi_pass" "/opt/homebrew/etc/nginx/sites-available/$domain" | grep -o "127.0.0.1:[0-9]*" | cut -d: -f2)
        local php_ver_name=""
        case $php_version in
            "9074") php_ver_name="7.4" ;;
            "9080") php_ver_name="8.0" ;;
            "9081") php_ver_name="8.1" ;;
            "9082") php_ver_name="8.2" ;;
            "9083") php_ver_name="8.3" ;;
            *) php_ver_name="Unknown" ;;
        esac
        
        print_color "yellow" "   PHP Version: $php_ver_name (Port: $php_version)"
    fi
    
    if [ -d "/opt/homebrew/var/www/$project_name" ]; then
        print_color "yellow" "   Thư mục: /opt/homebrew/var/www/$project_name"
    fi
    
    echo ""
    read -p "Bạn có muốn xóa domain cũ và tạo lại không? (y/N): " confirm_remove
    
    if [ "$confirm_remove" = "y" ] || [ "$confirm_remove" = "Y" ]; then
        print_color "blue" "🗑️ Đang xóa domain cũ: $domain..."
        
        # Remove from Nginx
        sudo rm -f "/opt/homebrew/etc/nginx/sites-enabled/$domain"
        sudo rm -f "/opt/homebrew/etc/nginx/sites-available/$domain"
        print_color "green" "   ✅ Đã xóa cấu hình Nginx"
        
        # Remove SSL certificates
        sudo rm -f "/opt/homebrew/etc/nginx/ssl/$domain.crt"
        sudo rm -f "/opt/homebrew/etc/nginx/ssl/$domain.key"
        print_color "green" "   ✅ Đã xóa SSL certificates"
        
        # Remove project directory
        if [ -d "/opt/homebrew/var/www/$project_name" ]; then
            sudo rm -rf "/opt/homebrew/var/www/$project_name"
            print_color "green" "   ✅ Đã xóa thư mục dự án"
        fi
        
        # Remove from hosts file
        sudo sed -i '' "/$domain/d" /etc/hosts
        print_color "green" "   ✅ Đã xóa khỏi hosts file"
        
        # Remove log files
        sudo rm -f "/opt/homebrew/var/log/nginx/$domain-access.log"
        sudo rm -f "/opt/homebrew/var/log/nginx/$domain-error.log"
        print_color "green" "   ✅ Đã xóa log files"
        
        print_color "green" "✅ Đã xóa domain $domain thành công!"
        return 0
    else
        print_color "blue" "❌ Đã hủy tạo dự án"
        return 1
    fi
}

# Function to get PHP-FPM port
get_php_fpm_port() {
    local version=$1
    case $version in
        "7.4") echo "9074" ;;
        "8.0") echo "9080" ;;
        "8.1") echo "9081" ;;
        "8.2") echo "9082" ;;
        "8.3") echo "9083" ;;
        *) echo "9000" ;;
    esac
}

# Function to setup PHP-FPM for specific version
setup_php_fpm() {
    local version=$1
    local port=$(get_php_fpm_port $version)
    
    print_color "blue" "🔧 Đang cấu hình PHP-FPM $version trên port $port..."
    
    # Create PHP-FPM configuration directory
    local php_conf_dir="/opt/homebrew/etc/php/$version"
    sudo mkdir -p "$php_conf_dir/php-fpm.d"
    
    # Create PHP-FPM pool configuration
    sudo tee "$php_conf_dir/php-fpm.d/www.conf" > /dev/null << EOF
[www]
user = $(whoami)
group = admin
listen = 127.0.0.1:$port
listen.owner = $(whoami)
listen.group = admin
listen.mode = 0660

pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.max_requests = 500

security.limit_extensions = .php

php_admin_value[error_log] = /opt/homebrew/var/log/php-fpm-$version.log
php_admin_flag[log_errors] = on
php_admin_value[memory_limit] = 256M
php_admin_value[max_execution_time] = 300
php_admin_value[upload_max_filesize] = 100M
php_admin_value[post_max_size] = 100M

; Tắt deprecated warnings cho PHP 7.4
php_admin_value[error_reporting] = E_ALL & ~E_DEPRECATED & ~E_STRICT
php_admin_value[display_errors] = Off
EOF

    # Create PHP-FPM configuration
    sudo tee "$php_conf_dir/php-fpm.conf" > /dev/null << EOF
[global]
pid = /opt/homebrew/var/run/php-fpm-$version.pid
error_log = /opt/homebrew/var/log/php-fpm-$version.log
daemonize = no

include = $php_conf_dir/php-fpm.d/*.conf
EOF

    # Create log directory
    sudo mkdir -p /opt/homebrew/var/log
    sudo touch "/opt/homebrew/var/log/php-fpm-$version.log"
    sudo chown $(whoami):admin "/opt/homebrew/var/log/php-fpm-$version.log"
    
    # Create run directory
    sudo mkdir -p /opt/homebrew/var/run
    sudo chown $(whoami):admin /opt/homebrew/var/run
    
    # Set full permissions
    sudo chmod -R 755 "$php_conf_dir"
    sudo chown -R $(whoami):admin "$php_conf_dir"
    
    # Start PHP-FPM service
    brew services start "php@$version"
    
    # Wait for service to start
    sleep 3
    
    # Check if service is running
    if brew services list | grep -q "php@$version.*started"; then
        print_color "green" "✅ Đã khởi động PHP-FPM $version trên port $port"
        
        # Test port connection
        if nc -z localhost $port 2>/dev/null; then
            print_color "green" "✅ Port $port đã sẵn sàng nhận kết nối!"
        else
            print_color "orange" "⚠️ Port $port chưa sẵn sàng, vui lòng đợi thêm..."
        fi
    else
        print_color "red" "❌ Không thể khởi động PHP-FPM $version"
        return 1
    fi
}

# Function to create project
create_project() {
    local domain=$1
    local php_version=$2
    local project_path=$3
    
    print_color "purple" "🚀 Đang tạo dự án: $domain (PHP $php_version)"
    
    # Create project directory with full permissions
    print_color "blue" "   📁 Tạo thư mục dự án..."
    sudo mkdir -p "$project_path/public"
    
    # Set ownership and permissions - use current user
    local current_user=$(whoami)
    print_color "blue" "   🔐 Cấp quyền đầy đủ cho user: $current_user..."
    sudo chown -R "$current_user:admin" "$project_path"
    sudo chmod -R 755 "$project_path"
    
    # Create index.php file
    print_color "blue" "   📝 Tạo file index.php..."
    sudo tee "$project_path/public/index.php" > /dev/null << 'EOF'
<?php
$domain = $_SERVER['HTTP_HOST'] ?? 'unknown';
$php_version = PHP_VERSION;
$server_time = date('Y-m-d H:i:s');
?>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo htmlspecialchars($domain); ?> - PHP <?php echo $php_version; ?></title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
        .info { background: #ecf0f1; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .success { color: #27ae60; font-weight: bold; }
        .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #bdc3c7; color: #7f8c8d; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 <?php echo htmlspecialchars($domain); ?></h1>
        
        <div class="info">
            <h2>✅ Dự án đã hoạt động thành công!</h2>
            <p><strong>Domain:</strong> <?php echo htmlspecialchars($domain); ?></p>
            <p><strong>PHP Version:</strong> <?php echo $php_version; ?></p>
            <p><strong>Server Time:</strong> <?php echo $server_time; ?></p>
            <p><strong>Document Root:</strong> <?php echo $_SERVER['DOCUMENT_ROOT'] ?? 'N/A'; ?></p>
        </div>
        
        <div class="info">
            <h3>🔧 Thông tin hệ thống:</h3>
            <p><strong>Server Software:</strong> <?php echo $_SERVER['SERVER_SOFTWARE'] ?? 'N/A'; ?></p>
            <p><strong>Server Protocol:</strong> <?php echo $_SERVER['SERVER_PROTOCOL'] ?? 'N/A'; ?></p>
            <p><strong>Request Method:</strong> <?php echo $_SERVER['REQUEST_METHOD'] ?? 'N/A'; ?></p>
        </div>
        
        <div class="footer">
            <p>🎯 Được tạo bởi Nginx Multi-PHP Setup Tool</p>
            <p>📁 Thư mục: <?php echo __DIR__; ?></p>
        </div>
    </div>
</body>
</html>
EOF
    
    # Set correct permissions for index.php
    sudo chmod 644 "$project_path/public/index.php"
    sudo chown "$current_user:admin" "$project_path/public/index.php"
    
    # Verify permissions
    print_color "blue" "   ✅ Kiểm tra quyền..."
    if [ -r "$project_path/public" ] && [ -r "$project_path/public/index.php" ]; then
        print_color "green" "   ✅ Quyền thư mục OK"
        print_color "green" "   ✅ File index.php đã tạo thành công"
    else
        print_color "red" "   ❌ Lỗi quyền thư mục!"
        print_color "red" "   🔍 Kiểm tra chi tiết:"
        ls -la "$project_path/public/" 2>/dev/null || echo "Không thể truy cập thư mục"
        return 1
    fi
    
    # Create index.php with PHP version info
    cat > "$project_path/public/index.php" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>🚀 $domain - PHP $php_version</title>
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
        .php-version {
            background: rgba(33, 150, 243, 0.3);
            border: 2px solid #2196F3;
        }
        .server-info {
            background: rgba(156, 39, 176, 0.3);
            border: 2px solid #9C27B0;
        }
        .demo-info {
            background: rgba(255, 193, 7, 0.3);
            border: 2px solid #FFC107;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Welcome to $domain</h1>
        
        <div class="success">
            <h3>✨ PHP $php_version Setup thành công!</h3>
            <p>Bạn đã thoát khỏi trang "Welcome to Nginx!" mặc định!</p>
        </div>
        
        <div class="info-grid">
            <div class="info-card php-version">
                <h3>🐘 PHP Version</h3>
                <p><?php echo PHP_VERSION; ?></p>
            </div>
            
            <div class="info-card server-info">
                <h3>🕐 Server Time</h3>
                <p><?php echo date('Y-m-d H:i:s'); ?></p>
            </div>
            
            <div class="info-card demo-info">
                <h3>🌐 Domain</h3>
                <p>$domain</p>
            </div>
            
            <div class="info-card">
                <h3>📁 Project Path</h3>
                <p><?php echo __DIR__; ?></p>
            </div>
        </div>
        
        <div style="margin-top: 30px; text-align: center; opacity: 0.8;">
            <p>🚀 Powered by Nginx + PHP-FPM $php_version (Port $(get_php_fpm_port $php_version))</p>
            <p>✅ Không còn "Welcome to Nginx!" mặc định nữa!</p>
        </div>
    </div>
</body>
</html>
EOF

    # Create SSL certificate with full permissions
    print_color "blue" "   🔒 Tạo SSL certificate..."
    local ssl_dir="/opt/homebrew/etc/nginx/ssl"
    sudo mkdir -p "$ssl_dir"
    sudo chown $(whoami):admin "$ssl_dir"
    sudo chmod 755 "$ssl_dir"
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$ssl_dir/$domain.key" \
        -out "$ssl_dir/$domain.crt" \
        -subj "/CN=$domain" \
        -addext "subjectAltName=DNS:$domain"
    
    # Set SSL file permissions
    sudo chmod 644 "$ssl_dir/$domain.key" "$ssl_dir/$domain.crt"
    sudo chown $(whoami):admin "$ssl_dir/$domain.key" "$ssl_dir/$domain.crt"
    
    # Verify SSL files
    if [ -f "$ssl_dir/$domain.key" ] && [ -f "$ssl_dir/$domain.crt" ]; then
        print_color "green" "   ✅ SSL certificate đã tạo thành công"
    else
        print_color "red" "   ❌ Lỗi tạo SSL certificate!"
        return 1
    fi
    
    # Create Nginx configuration with full permissions
    print_color "blue" "   🌐 Tạo cấu hình Nginx..."
    local nginx_available="/opt/homebrew/etc/nginx/sites-available"
    local nginx_enabled="/opt/homebrew/etc/nginx/sites-enabled"
    sudo mkdir -p "$nginx_available" "$nginx_enabled"
    sudo chown -R $(whoami):admin "$nginx_available" "$nginx_enabled"
    sudo chmod -R 755 "$nginx_available" "$nginx_enabled"
    
    local php_port=$(get_php_fpm_port $php_version)
    
    cat > "$nginx_available/$domain" << EOF
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
    
    # SSL Configuration
    ssl_certificate     $ssl_dir/$domain.crt;
    ssl_certificate_key $ssl_dir/$domain.key;
    
    # SSL Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    
    index index.php index.html;
    charset utf-8;
    client_max_body_size 100M;
    
    # Logs
    access_log /opt/homebrew/var/log/nginx/$domain-access.log combined;
    error_log /opt/homebrew/var/log/nginx/$domain-error.log warn;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }
    
    # PHP-FPM Configuration for PHP $php_version on port $php_port
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
    
    # Browser Caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|eot|ttf|woff|woff2)$ {
        expires max;
        add_header Cache-Control "public, no-transform";
    }
}
EOF

    # Create symbolic link
    print_color "blue" "   🔗 Tạo symbolic link..."
    ln -sf "$nginx_available/$domain" "$nginx_enabled/"
    
    # Update hosts file
    print_color "blue" "   📝 Cập nhật hosts file..."
    if ! grep -q "$domain" /etc/hosts; then
        echo "127.0.0.1       $domain" | sudo tee -a /etc/hosts > /dev/null
        print_color "green" "   ✅ Đã thêm vào /etc/hosts"
    else
        print_color "yellow" "   ⚠️ Domain đã có trong /etc/hosts"
    fi
    
    # Final permission check
    print_color "blue" "   🔍 Kiểm tra cuối cùng..."
    if [ -f "$nginx_available/$domain" ] && [ -L "$nginx_enabled/$domain" ]; then
        print_color "green" "   ✅ Cấu hình Nginx OK"
    else
        print_color "red" "   ❌ Lỗi cấu hình Nginx!"
        return 1
    fi
    
    check_status "Đã tạo dự án $domain với PHP $php_version"
}

# Function to show current status
show_status() {
    print_color "blue" "📊 Trạng thái hiện tại:"
    echo ""
    
    # Show PHP-FPM services
    print_color "purple" "🐘 PHP-FPM Services:"
    brew services list | grep php@ || echo "Không có PHP-FPM nào đang chạy"
    echo ""
    
    # Show Nginx status
    print_color "purple" "🌐 Nginx Status:"
    if brew services list | grep -q "nginx.*started"; then
        print_color "green" "✓ Nginx đang chạy"
    else
        print_color "red" "✗ Nginx không chạy"
    fi
    echo ""
    
    # Show active sites
    print_color "purple" "🌍 Active Sites:"
    if [ -d "/opt/homebrew/etc/nginx/sites-enabled" ]; then
        for site in /opt/homebrew/etc/nginx/sites-enabled/*; do
            if [ -f "$site" ]; then
                local domain=$(basename "$site")
                local php_version=$(grep "fastcgi_pass" "$site" | grep -o "127.0.0.1:[0-9]*" | cut -d: -f2)
                local php_ver_name=""
                case $php_version in
                    "9074") php_ver_name="7.4" ;;
                    "9080") php_ver_name="8.0" ;;
                    "9081") php_ver_name="8.1" ;;
                    "9082") php_ver_name="8.2" ;;
                    "9083") php_ver_name="8.3" ;;
                    *) php_ver_name="Unknown" ;;
                esac
                print_color "green" "  ✓ $domain (PHP $php_ver_name)"
            fi
        done
    fi
    echo ""
}

# Main menu
show_menu() {
    clear
    print_color "blue" "🚀 Nginx Multi-PHP Setup Tool"
    print_color "blue" "=================================="
    echo ""
    print_color "green" "1. Tạo dự án mới"
    print_color "green" "2. Hiển thị trạng thái"
    print_color "green" "3. Khởi động lại tất cả services"
    print_color "green" "4. Kiểm tra cấu hình Nginx"
    print_color "green" "5. Mở thư mục dự án"
    print_color "green" "6. Xóa dự án"
    print_color "green" "7. Sửa quyền hệ thống"
    print_color "green" "8. Sửa cấu hình Nginx"
    print_color "green" "9. Thoát"
    echo ""
}

# Function to create new project
create_new_project() {
    print_color "blue" "🚀 Tạo dự án mới"
    print_color "blue" "=================="
    echo ""
    
    # Show available PHP versions
    print_color "purple" "🐘 Các phiên bản PHP có sẵn:"
    local available_php=""
    for version in 7.4 8.0 8.1 8.2 8.3; do
        if check_php_version $version; then
            if [ -z "$available_php" ]; then
                available_php="$version"
            else
                available_php="$available_php, $version"
            fi
            print_color "green" "  ✓ PHP $version"
        fi
    done
    echo ""
    
    if [ -z "$available_php" ]; then
        print_color "red" "❌ Không có phiên bản PHP nào được cài đặt!"
        print_color "blue" "Vui lòng cài đặt PHP trước: brew install php@7.4"
        return
    fi
    
    # Get project details
    read -p "Nhập tên dự án (vd: haili-baohanh): " project_name
    project_name=$(echo "$project_name" | tr -cd '[:alnum:].-' | tr '[:upper:]' '[:lower:]')
    
    if [ -z "$project_name" ]; then
        print_color "red" "❌ Tên dự án không được để trống!"
        return
    fi
    
    # Validate project name format
    if ! echo "$project_name" | grep -qE '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'; then
        print_color "red" "❌ Tên dự án không hợp lệ! Chỉ được dùng chữ cái, số và dấu gạch ngang"
        return
    fi
    
    # Auto-generate domain with .code extension
    domain="${project_name}.code"
    print_color "green" "✅ Domain sẽ là: $domain"
    
    # Check if domain already exists
    if [ -f "/opt/homebrew/etc/nginx/sites-enabled/$domain" ]; then
        if ! remove_existing_domain "$domain"; then
            return
        fi
        print_color "green" "✅ Domain cũ đã được xóa, tiếp tục tạo mới..."
    fi
    
    # Select PHP version
    echo ""
    print_color "blue" "Chọn phiên bản PHP:"
    for version in 7.4 8.0 8.1 8.2 8.3; do
        if check_php_version $version; then
            print_color "green" "  $version) PHP $version"
        fi
    done
    
    read -p "Nhập lựa chọn: " php_choice
    
    if ! check_php_version $php_choice; then
        print_color "red" "❌ Phiên bản PHP $php_choice không hợp lệ!"
        return
    fi
    
    # Confirm project creation
    local project_path="/opt/homebrew/var/www/$project_name"
    echo ""
    print_color "blue" "📋 Thông tin dự án:"
    print_color "green" "  Tên dự án: $project_name"
    print_color "green" "  Domain: $domain"
    print_color "green" "  PHP Version: $php_choice"
    print_color "green" "  Đường dẫn: $project_path"
    print_color "green" "  URL: https://$domain"
    echo ""
    
    read -p "Bạn có muốn tạo dự án này không? (y/N): " confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        # Setup PHP-FPM if not already configured
        if ! brew services list | grep -q "php@$php_choice.*started"; then
            setup_php_fpm $php_choice
        fi
        
        # Create project
        create_project $domain $php_choice $project_path
        
        # Test Nginx configuration
        print_color "blue" "🔍 Kiểm tra cấu hình Nginx..."
        if nginx -t 2>&1 | grep -q "syntax is ok"; then
            print_color "green" "✅ Cấu hình Nginx hợp lệ"
            
            # Reload Nginx instead of restart
            print_color "blue" "🔄 Reload Nginx..."
            nginx -s reload 2>/dev/null
            if [ $? -eq 0 ]; then
                print_color "green" "✅ Đã reload Nginx thành công"
            else
                print_color "orange" "⚠️ Reload Nginx thất bại, thử restart..."
                brew services restart nginx
            fi
        else
            print_color "red" "❌ Cấu hình Nginx có lỗi!"
            nginx -t
            return 1
        fi
        
        echo ""
        print_color "green" "🎉 Dự án $project_name đã được tạo thành công!"
        print_color "blue" "🌐 Domain: $domain"
        print_color "blue" "🌐 Truy cập: https://$domain"
        print_color "blue" "📁 Thư mục: $project_path"
        
        # Open project in Finder
        read -p "Mở thư mục dự án trong Finder? (y/N): " open_finder
        if [ "$open_finder" = "y" ] || [ "$open_finder" = "Y" ]; then
            open "$project_path"
        fi
    fi
}

# Function to restart all services
restart_all_services() {
    print_color "blue" "🔄 Khởi động lại tất cả services..."
    
    # Restart all PHP-FPM services
    for version in 7.4 8.0 8.1 8.2 8.3; do
        if check_php_version $version; then
            brew services restart "php@$version" 2>/dev/null
        fi
    done
    
    # Restart Nginx
    brew services restart nginx
    
    print_color "green" "✅ Đã khởi động lại tất cả services!"
}

# Function to check Nginx configuration
check_nginx_config() {
    print_color "blue" "🔍 Kiểm tra cấu hình Nginx..."
    nginx -t
    
    if [ $? -eq 0 ]; then
        print_color "green" "✅ Cấu hình Nginx hợp lệ!"
    else
        print_color "red" "❌ Cấu hình Nginx có lỗi!"
    fi
}

# Function to open project directory
open_project_directory() {
    print_color "blue" "📁 Mở thư mục dự án"
    print_color "blue" "===================="
    echo ""
    
    if [ -d "/opt/homebrew/var/www" ]; then
        local projects=()
        for project in /opt/homebrew/var/www/*; do
            if [ -d "$project" ]; then
                projects+=("$(basename "$project")")
            fi
        done
        
        if [ ${#projects[@]} -eq 0 ]; then
            print_color "orange" "Không có dự án nào được tạo!"
            return
        fi
        
        print_color "purple" "Các dự án có sẵn:"
        for i in "${!projects[@]}"; do
            print_color "green" "  $((i+1))) ${projects[$i]}"
        done
        
        echo ""
        read -p "Chọn dự án (1-${#projects[@]}): " choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#projects[@]}" ]; then
            local selected_project="${projects[$((choice-1))]}"
            local project_path="/opt/homebrew/var/www/$selected_project"
            open "$project_path"
            print_color "green" "✅ Đã mở thư mục: $project_path"
        else
            print_color "red" "❌ Lựa chọn không hợp lệ!"
        fi
    else
        print_color "orange" "Thư mục dự án không tồn tại!"
    fi
}

# Function to delete project
delete_project() {
    print_color "blue" "🗑️ Xóa dự án"
    print_color "blue" "============="
    echo ""
    
    if [ -d "/opt/homebrew/var/www" ]; then
        local projects=()
        for project in /opt/homebrew/var/www/*; do
            if [ -d "$project" ]; then
                projects+=("$(basename "$project")")
            fi
        done
        
        if [ ${#projects[@]} -eq 0 ]; then
            print_color "orange" "Không có dự án nào để xóa!"
            return
        fi
        
        print_color "purple" "Các dự án có sẵn:"
        for i in "${!projects[@]}"; do
            print_color "green" "  $((i+1))) ${projects[$i]}"
        done
        
        echo ""
        read -p "Chọn dự án để xóa (1-${#projects[@]}): " choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#projects[@]}" ]; then
            local selected_project="${projects[$((choice-1))]}"
            
            echo ""
            print_color "red" "⚠️ Cảnh báo: Bạn sắp xóa dự án $selected_project!"
            print_color "red" "Tất cả dữ liệu sẽ bị mất vĩnh viễn!"
            echo ""
            
            read -p "Bạn có chắc chắn muốn xóa? (y/N): " confirm
            
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                # Remove from Nginx
                sudo rm -f "/opt/homebrew/etc/nginx/sites-enabled/$selected_project"
                sudo rm -f "/opt/homebrew/etc/nginx/sites-available/$selected_project"
                
                # Remove SSL certificates
                sudo rm -f "/opt/homebrew/etc/nginx/ssl/$selected_project.key"
                sudo rm -f "/opt/homebrew/etc/nginx/ssl/$selected_project.crt"
                
                # Remove project directory
                sudo rm -rf "/opt/homebrew/var/www/$selected_project"
                
                # Remove from hosts file
                sudo sed -i '' "/$selected_project/d" /etc/hosts
                
                # Restart Nginx
                nginx -t && brew services restart nginx
                
                print_color "green" "✅ Đã xóa dự án $selected_project thành công!"
            else
                print_color "blue" "Đã hủy xóa dự án."
            fi
        else
            print_color "red" "❌ Lựa chọn không hợp lệ!"
        fi
    else
        print_color "orange" "Thư mục dự án không tồn tại!"
    fi
}

# Main loop
main() {
    while true; do
        show_menu
        read -p "Chọn tùy chọn (1-9): " choice
        
        case $choice in
            1) create_new_project ;;
            2) show_status ;;
            3) restart_all_services ;;
            4) check_nginx_config ;;
            5) open_project_directory ;;
            6) delete_project ;;
            7) fix_system_permissions ;;
            8) fix_nginx_user_directive ;;
            9) 
                print_color "green" "👋 Tạm biệt!"
                exit 0
                ;;
            *) 
                print_color "red" "❌ Lựa chọn không hợp lệ!"
                ;;
        esac
        
        echo ""
        read -p "Nhấn Enter để tiếp tục..."
    done
}

# Check if script is run with sudo
if [ "$EUID" -eq 0 ]; then
    print_color "red" "❌ Không nên chạy script này với sudo."
    print_color "blue" "Vui lòng chạy lại không có sudo: bash setup_nginx_multi_php.sh"
    exit 1
fi

# Check if Nginx is installed
if ! command -v nginx &> /dev/null; then
    print_color "red" "❌ Nginx chưa được cài đặt!"
    print_color "blue" "Vui lòng chạy: bash install_nginx.sh"
    exit 1
fi

# Check if at least one PHP version is installed
php_installed=false
for version in 7.4 8.0 8.1 8.2 8.3; do
    if check_php_version $version; then
        php_installed=true
        break
    fi
done

if [ "$php_installed" = false ]; then
    print_color "red" "❌ Không có phiên bản PHP nào được cài đặt!"
    print_color "blue" "Vui lòng cài đặt PHP trước: brew install php@7.4"
    exit 1
fi

# Start main program
main
