#!/bin/bash

# Colors
NORMAL="\\033[0;39m"
GREEN="\\033[1;32m"
RED="\\033[1;31m"
BLUE="\\033[1;34m"
ORANGE="\\033[1;33m"
YELLOW="\\033[1;33m"

# Function to display text in color
print_color() {
    local color=$1
    local text=$2
    case $color in
        "green") echo -e "${GREEN}${text}${NORMAL}" ;;
        "red") echo -e "${RED}${text}${NORMAL}" ;;
        "blue") echo -e "${BLUE}${text}${NORMAL}" ;;
        "orange") echo -e "${ORANGE}${text}${NORMAL}" ;;
        "yellow") echo -e "${YELLOW}${text}${NORMAL}" ;;
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
setup_php_fpm_version() {
    local version=$1
    local port=$(get_php_fpm_port $version)
    
    print_color "blue" "🔧 Đang cấu hình PHP-FPM $version trên port $port..."
    
    # Tạo thư mục cấu hình PHP-FPM
    local php_conf_dir="/opt/homebrew/etc/php/$version"
    local php_fpm_conf="$php_conf_dir/php-fpm.d/www.conf"
    
    # Tạo thư mục nếu chưa có
    sudo mkdir -p "$php_conf_dir/php-fpm.d"
    sudo chown -R $(whoami):admin "$php_conf_dir"
    
    # Backup file cấu hình cũ nếu có
    if [ -f "$php_fpm_conf" ]; then
        cp "$php_fpm_conf" "$php_fpm_conf.backup"
        print_color "yellow" "   Đã backup file cấu hình cũ"
    fi
    
    # Tạo cấu hình PHP-FPM mới
    cat > "$php_fpm_conf" << EOF
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

php_admin_value[error_log] = /opt/homebrew/var/log/php-fpm-$version.log
php_admin_flag[log_errors] = on
php_admin_value[memory_limit] = 256M
php_admin_value[max_execution_time] = 300
php_admin_value[upload_max_filesize] = 100M
php_admin_value[post_max_size] = 100M

security.limit_extensions = .php
EOF
    
    # Tạo file log
    sudo touch "/opt/homebrew/var/log/php-fpm-$version.log"
    sudo chown $(whoami):admin "/opt/homebrew/var/log/php-fpm-$version.log"
    
    # Thiết lập quyền cho file cấu hình
    sudo chmod 644 "$php_fpm_conf"
    sudo chown $(whoami):admin "$php_fpm_conf"
    
    # Khởi động PHP-FPM service
    print_color "blue" "   Khởi động PHP-FPM $version..."
    brew services start "php@$version"
    
    if [ $? -eq 0 ]; then
        print_color "green" "   ✅ PHP-FPM $version đã được cấu hình và khởi động trên port $port"
    else
        print_color "red" "   ❌ Không thể khởi động PHP-FPM $version"
        return 1
    fi
}

# Function to show PHP-FPM status
show_php_fpm_status() {
    local version=$1
    local port=$(get_php_fpm_port $version)
    
    if brew services list | grep -q "php@$version.*started"; then
        print_color "green" "   ✅ PHP $version: Đang chạy (Port: $port)"
    else
        print_color "red" "   ❌ PHP $version: Không chạy (Port: $port)"
    fi
}

# Function to test PHP-FPM connection
test_php_fpm_connection() {
    local version=$1
    local port=$(get_php_fpm_port $version)
    
    print_color "blue" "🔍 Kiểm tra kết nối PHP-FPM $version trên port $port..."
    
    # Tạo file test tạm thời
    local test_file="/tmp/test_php_$version.php"
    cat > "$test_file" << 'EOF'
<?php
echo "PHP Version: " . PHP_VERSION . "\n";
echo "PHP-FPM Status: OK\n";
echo "Server Time: " . date('Y-m-d H:i:s') . "\n";
echo "Memory Limit: " . ini_get('memory_limit') . "\n";
echo "Max Execution Time: " . ini_get('max_execution_time') . "\n";
?>
EOF
    
    # Test kết nối qua cgi-fcgi
    if command -v cgi-fcgi &> /dev/null; then
        local response=$(cgi-fcgi -bind -connect 127.0.0.1:$port "$test_file" 2>/dev/null)
        if [ $? -eq 0 ] && echo "$response" | grep -q "PHP Version"; then
            print_color "green" "   ✅ Kết nối PHP-FPM $version thành công!"
            echo "$response" | head -5
        else
            print_color "red" "   ❌ Không thể kết nối PHP-FPM $version"
        fi
    else
        print_color "yellow" "   ⚠️  cgi-fcgi không có sẵn, bỏ qua test kết nối"
    fi
    
    # Xóa file test
    rm -f "$test_file"
}

# Function to setup all PHP versions
setup_all_php_versions() {
    print_color "blue" "🚀 Bắt đầu cài đặt PHP-FPM cho tất cả phiên bản..."
    echo ""
    
    local success_count=0
    local total_count=0
    
    for version in 7.4 8.0 8.1 8.2 8.3; do
        if check_php_version $version; then
            total_count=$((total_count + 1))
            print_color "blue" "=== PHP $version ==="
            
            if setup_php_fpm_version $version; then
                success_count=$((success_count + 1))
                
                # Test kết nối
                test_php_fpm_connection $version
            fi
            
            echo ""
        fi
    done
    
    print_color "green" "🎉 Hoàn tất cài đặt PHP-FPM!"
    print_color "blue" "📊 Kết quả: $success_count/$total_count phiên bản thành công"
}

# Function to show current status
show_current_status() {
    print_color "blue" "📊 Trạng thái hiện tại của PHP-FPM:"
    echo ""
    
    local running_count=0
    local total_count=0
    
    for version in 7.4 8.0 8.1 8.2 8.3; do
        if check_php_version $version; then
            total_count=$((total_count + 1))
            local port=$(get_php_fpm_port $version)
            
            if brew services list | grep -q "php@$version.*started"; then
                print_color "green" "✅ PHP $version: Đang chạy (Port: $port)"
                running_count=$((running_count + 1))
            else
                print_color "red" "❌ PHP $version: Không chạy (Port: $port)"
            fi
        fi
    done
    
    echo ""
    print_color "blue" "Tổng cộng: $running_count/$total_count PHP-FPM đang chạy"
}

# Function to restart all PHP-FPM services
restart_all_php_fpm() {
    print_color "blue" "🔄 Đang restart tất cả PHP-FPM services..."
    echo ""
    
    for version in 7.4 8.0 8.1 8.2 8.3; do
        if check_php_version $version; then
            print_color "blue" "Restart PHP $version..."
            brew services restart "php@$version" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                print_color "green" "   ✅ PHP $version: Đã restart"
            else
                print_color "yellow" "   ⚠️  PHP $version: Không thể restart"
            fi
        fi
    done
    
    print_color "green" "✅ Đã restart tất cả PHP-FPM services!"
}

# Function to show help
show_help() {
    print_color "blue" "
=== 🚀 PHP-FPM Multi-Version Setup ===

Tool này sẽ cài đặt và cấu hình PHP-FPM cho tất cả 
các phiên bản PHP, mỗi PHP-FPM chạy trên port riêng biệt.

📋 Cách sử dụng: ./setup_php_fpm_all.sh <command>

Commands:
   setup                   - Cài đặt PHP-FPM cho tất cả phiên bản
   status                  - Hiển thị trạng thái hiện tại
   restart                 - Restart tất cả PHP-FPM services
   test                    - Test kết nối tất cả PHP-FPM
   help                    - Hiển thị hướng dẫn này

💡 Port mapping:
   PHP 7.4 → Port 9074
   PHP 8.0 → Port 9080
   PHP 8.1 → Port 9081
   PHP 8.2 → Port 9082
   PHP 8.3 → Port 9083

🔧 Ví dụ:
   ./setup_php_fpm_all.sh setup
   ./setup_php_fpm_all.sh status
   ./setup_php_fpm_all.sh restart
"
}

# Function to test all PHP-FPM connections
test_all_php_fpm() {
    print_color "blue" "🔍 Test kết nối tất cả PHP-FPM..."
    echo ""
    
    for version in 7.4 8.0 8.1 8.2 8.3; do
        if check_php_version $version; then
            test_php_fpm_connection $version
            echo ""
        fi
    done
}

# Main function
main() {
    local command=$1
    
    case $command in
        "setup")
            setup_all_php_versions
            ;;
        "status")
            show_current_status
            ;;
        "restart")
            restart_all_php_fpm
            ;;
        "test")
            test_all_php_fpm
            ;;
        "help"|"--help"|"-h"|"")
            show_help
            ;;
        *)
            print_color "red" "❌ Command không hợp lệ: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
