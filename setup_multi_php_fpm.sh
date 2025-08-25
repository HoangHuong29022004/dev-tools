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
daemonize = yes

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
    
    print_color "green" "✅ Đã cấu hình PHP-FPM $version"
}

# Function to start PHP-FPM manually
start_php_fpm() {
    local version=$1
    local port=$(get_php_fpm_port $version)
    
    print_color "blue" "🚀 Khởi động PHP-FPM $version trên port $port..."
    
    # Stop brew service if running
    brew services stop "php@$version" 2>/dev/null
    
    # Start PHP-FPM manually
    local php_conf_dir="/opt/homebrew/etc/php/$version"
    if [ -f "$php_conf_dir/php-fpm.conf" ]; then
        # Kill existing process if any
        sudo pkill -f "php-fpm.*$version" 2>/dev/null
        
        # Start new process
        sudo /opt/homebrew/opt/php@$version/sbin/php-fpm --fpm-config "$php_conf_dir/php-fpm.conf"
        
        # Wait for startup
        sleep 3
        
        # Check if running
        if pgrep -f "php-fpm.*$version" > /dev/null; then
            print_color "green" "✅ PHP-FPM $version đã khởi động trên port $port"
            
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
    else
        print_color "red" "❌ Không tìm thấy config PHP-FPM $version"
        return 1
    fi
}

# Function to stop PHP-FPM
stop_php_fpm() {
    local version=$1
    
    print_color "blue" "⏹️ Dừng PHP-FPM $version..."
    
    # Kill process
    sudo pkill -f "php-fpm.*$version" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        print_color "green" "✅ Đã dừng PHP-FPM $version"
    else
        print_color "orange" "⚠️ PHP-FPM $version không chạy hoặc đã dừng"
    fi
}

# Function to restart PHP-FPM
restart_php_fpm() {
    local version=$1
    
    print_color "blue" "🔄 Khởi động lại PHP-FPM $version..."
    stop_php_fpm $version
    sleep 2
    start_php_fpm $version
}

# Function to show status
show_status() {
    print_color "blue" "📊 Trạng thái PHP-FPM:"
    echo ""
    
    for version in 7.4 8.0 8.1 8.2 8.3; do
        if [ -d "/opt/homebrew/opt/php@$version" ]; then
            local port=$(get_php_fpm_port $version)
            local process_count=$(pgrep -f "php-fpm.*$version" | wc -l)
            local port_status=""
            
            if nc -z localhost $port 2>/dev/null; then
                port_status="✅ Lắng nghe"
            else
                port_status="❌ Không lắng nghe"
            fi
            
            if [ $process_count -gt 0 ]; then
                print_color "green" "  PHP $version: 🟢 Chạy ($process_count process) - Port $port $port_status"
            else
                print_color "red" "  PHP $version: 🔴 Dừng - Port $port $port_status"
            fi
        fi
    done
    echo ""
}

# Function to setup all PHP versions
setup_all_php() {
    print_color "blue" "🚀 Setup tất cả PHP versions..."
    echo ""
    
    for version in 7.4 8.0 8.1 8.2 8.3; do
        if [ -d "/opt/homebrew/opt/php@$version" ]; then
            print_color "purple" "📦 Setup PHP $version..."
            setup_php_fpm $version
            echo ""
        fi
    done
    
    print_color "green" "✅ Hoàn tất setup tất cả PHP versions!"
}

# Function to start all PHP versions
start_all_php() {
    print_color "blue" "🚀 Khởi động tất cả PHP versions..."
    echo ""
    
    for version in 7.4 8.0 8.1 8.2 8.3; do
        if [ -d "/opt/homebrew/opt/php@$version" ]; then
            print_color "purple" "🚀 Khởi động PHP $version..."
            start_php_fpm $version
            echo ""
        fi
    done
    
    print_color "green" "✅ Hoàn tất khởi động tất cả PHP versions!"
}

# Function to stop all PHP versions
stop_all_php() {
    print_color "blue" "⏹️ Dừng tất cả PHP versions..."
    echo ""
    
    for version in 7.4 8.0 8.1 8.2 8.3; do
        if [ -d "/opt/homebrew/opt/php@$version" ]; then
            print_color "purple" "⏹️ Dừng PHP $version..."
            stop_php_fpm $version
            echo ""
        fi
    done
    
    print_color "green" "✅ Hoàn tất dừng tất cả PHP versions!"
}

# Function to setup Nginx with unified config
setup_nginx_unified() {
    print_color "blue" "🌐 Setup Nginx với cấu hình thống nhất..."
    
    # Create unified Nginx config
    local nginx_conf="/opt/homebrew/etc/nginx/sites-available/multi-domains.conf"
    
    if [ -f "$nginx_conf" ]; then
        print_color "green" "✅ File cấu hình thống nhất đã tồn tại"
    else
        print_color "red" "❌ File cấu hình thống nhất không tồn tại!"
        print_color "blue" "Vui lòng chạy setup_nginx_multi_php.sh trước"
        return 1
    fi
    
    # Remove all existing symbolic links
    sudo rm -f /opt/homebrew/etc/nginx/sites-enabled/*
    
    # Create single symbolic link to unified config
    sudo ln -sf "$nginx_conf" /opt/homebrew/etc/nginx/sites-enabled/multi-domains.conf
    
    # Fix permissions
    sudo chown -R $(whoami):admin /opt/homebrew/etc/nginx
    sudo chmod -R 755 /opt/homebrew/etc/nginx
    
    print_color "green" "✅ Đã setup Nginx với cấu hình thống nhất!"
}

# Function to restart Nginx
restart_nginx() {
    print_color "blue" "🔄 Khởi động lại Nginx..."
    
    # Test configuration
    if nginx -t; then
        # Restart Nginx
        brew services restart nginx
        print_color "green" "✅ Đã khởi động lại Nginx!"
    else
        print_color "red" "❌ Cấu hình Nginx có lỗi!"
        return 1
    fi
}

# Main menu
show_menu() {
    echo ""
    echo "🐘 Multi-PHP-FPM Setup Tool (Unified Config)"
    echo "============================================="
    echo ""
    echo "1. Setup tất cả PHP versions"
    echo "2. Khởi động tất cả PHP versions"
    echo "3. Dừng tất cả PHP versions"
    echo "4. Khởi động lại tất cả PHP versions"
    echo "5. Khởi động PHP version cụ thể"
    echo "6. Dừng PHP version cụ thể"
    echo "7. Khởi động lại PHP version cụ thể"
    echo "8. Setup Nginx với cấu hình thống nhất"
    echo "9. Khởi động lại Nginx"
    echo "10. Hiển thị trạng thái"
    echo "11. Thoát"
    echo ""
}

# Main execution
case "${1:-menu}" in
    "setup")
        setup_all_php
        ;;
    "start")
        start_all_php
        ;;
    "stop")
        stop_all_php
        ;;
    "restart")
        stop_all_php
        sleep 2
        start_all_php
        ;;
    "nginx")
        setup_nginx_unified
        restart_nginx
        ;;
    "restart-nginx")
        restart_nginx
        ;;
    "status")
        show_status
        ;;
    "menu")
        while true; do
            show_menu
            read -p "Chọn tùy chọn (1-11): " choice
            
            case $choice in
                1) setup_all_php ;;
                2) start_all_php ;;
                3) stop_all_php ;;
                4) 
                    stop_all_php
                    sleep 2
                    start_all_php
                    ;;
                5)
                    read -p "Nhập PHP version (7.4, 8.0, 8.1, 8.2, 8.3): " version
                    start_php_fpm $version
                    ;;
                6)
                    read -p "Nhập PHP version (7.4, 8.0, 8.1, 8.2, 8.3): " version
                    stop_php_fpm $version
                    ;;
                7)
                    read -p "Nhập PHP version (7.4, 8.0, 8.1, 8.2, 8.3): " version
                    restart_php_fpm $version
                    ;;
                8) setup_nginx_unified ;;
                9) restart_nginx ;;
                10) show_status ;;
                11) 
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
        ;;
    *)
        echo "Cách sử dụng:"
        echo "  bash setup_multi_php_fpm.sh setup         # Setup tất cả PHP"
        echo "  bash setup_multi_php_fpm.sh start         # Khởi động tất cả PHP"
        echo "  bash setup_multi_php_fpm.sh stop          # Dừng tất cả PHP"
        echo "  bash setup_multi_php_fpm.sh restart       # Khởi động lại tất cả PHP"
        echo "  bash setup_multi_php_fpm.sh nginx         # Setup Nginx với cấu hình thống nhất"
        echo "  bash setup_multi_php_fpm.sh restart-nginx # Khởi động lại Nginx"
        echo "  bash setup_multi_php_fpm.sh status        # Hiển thị trạng thái"
        echo "  bash setup_multi_php_fpm.sh menu          # Menu tương tác"
        ;;
esac
