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

# Function to show PHP-FPM status
show_status() {
    print_color "blue" "📊 Trạng thái PHP-FPM Services"
    print_color "blue" "================================"
    echo ""
    
    local total_installed=0
    local total_running=0
    
    for version in 7.4 8.0 8.1 8.2 8.3; do
        if check_php_version $version; then
            total_installed=$((total_installed + 1))
            local port=$(get_php_fpm_port $version)
            local status=$(brew services list | grep "php@$version" | awk '{print $2}')
            
            if [ "$status" = "started" ]; then
                total_running=$((total_running + 1))
                print_color "green" "✓ PHP $version - Port $port - Đang chạy"
            else
                print_color "red" "✗ PHP $version - Port $port - Không chạy"
            fi
        fi
    done
    
    echo ""
    print_color "purple" "📈 Tổng quan:"
    print_color "green" "  - Đã cài đặt: $total_installed phiên bản"
    print_color "green" "  - Đang chạy: $total_running phiên bản"
    
    if [ $total_running -gt 0 ]; then
        echo ""
        print_color "blue" "🔍 Kiểm tra kết nối:"
        for version in 7.4 8.0 8.1 8.2 8.3; do
            if check_php_version $version; then
                local port=$(get_php_fpm_port $version)
                if brew services list | grep -q "php@$version.*started"; then
                    if nc -z localhost $port 2>/dev/null; then
                        print_color "green" "  ✓ Port $port (PHP $version) - Kết nối OK"
                    else
                        print_color "red" "  ✗ Port $port (PHP $version) - Không thể kết nối"
                    fi
                fi
            fi
        done
    fi
}

# Function to start PHP-FPM service
start_php_fpm() {
    local version=$1
    if ! check_php_version $version; then
        print_color "red" "❌ PHP $version chưa được cài đặt!"
        return 1
    fi
    
    local port=$(get_php_fpm_port $version)
    print_color "blue" "🚀 Đang khởi động PHP-FPM $version trên port $port..."
    
    # Check if service is already running
    if brew services list | grep -q "php@$version.*started"; then
        print_color "orange" "⚠️ PHP-FPM $version đã đang chạy!"
        return 0
    fi
    
    # Start service
    brew services start "php@$version"
    
    if [ $? -eq 0 ]; then
        print_color "green" "✅ Đã khởi động PHP-FPM $version thành công!"
        
        # Wait a moment and check connection
        sleep 2
        if nc -z localhost $port 2>/dev/null; then
            print_color "green" "✅ Port $port đã sẵn sàng nhận kết nối!"
        else
            print_color "orange" "⚠️ Port $port chưa sẵn sàng, vui lòng đợi thêm..."
        fi
    else
        print_color "red" "❌ Không thể khởi động PHP-FPM $version!"
        return 1
    fi
}

# Function to stop PHP-FPM service
stop_php_fpm() {
    local version=$1
    if ! check_php_version $version; then
        print_color "red" "❌ PHP $version chưa được cài đặt!"
        return 1
    fi
    
    print_color "blue" "🛑 Đang dừng PHP-FPM $version..."
    
    # Check if service is running
    if ! brew services list | grep -q "php@$version.*started"; then
        print_color "orange" "⚠️ PHP-FPM $version không đang chạy!"
        return 0
    fi
    
    # Stop service
    brew services stop "php@$version"
    
    if [ $? -eq 0 ]; then
        print_color "green" "✅ Đã dừng PHP-FPM $version thành công!"
    else
        print_color "red" "❌ Không thể dừng PHP-FPM $version!"
        return 1
    fi
}

# Function to restart PHP-FPM service
restart_php_fpm() {
    local version=$1
    if ! check_php_version $version; then
        print_color "red" "❌ PHP $version chưa được cài đặt!"
        return 1
    fi
    
    local port=$(get_php_fpm_port $version)
    print_color "blue" "🔄 Đang khởi động lại PHP-FPM $version trên port $port..."
    
    # Restart service
    brew services restart "php@$version"
    
    if [ $? -eq 0 ]; then
        print_color "green" "✅ Đã khởi động lại PHP-FPM $version thành công!"
        
        # Wait a moment and check connection
        sleep 2
        if nc -z localhost $port 2>/dev/null; then
            print_color "green" "✅ Port $port đã sẵn sàng nhận kết nối!"
        else
            print_color "orange" "⚠️ Port $port chưa sẵn sàng, vui lòng đợi thêm..."
        fi
    else
        print_color "red" "❌ Không thể khởi động lại PHP-FPM $version!"
        return 1
    fi
}

# Function to start all PHP-FPM services
start_all_php_fpm() {
    print_color "blue" "🚀 Khởi động tất cả PHP-FPM services..."
    echo ""
    
    local started_count=0
    local total_count=0
    
    for version in 7.4 8.0 8.1 8.2 8.3; do
        if check_php_version $version; then
            total_count=$((total_count + 1))
            if start_php_fpm $version; then
                started_count=$((started_count + 1))
            fi
            echo ""
        fi
    done
    
    echo ""
    print_color "green" "📊 Kết quả: Đã khởi động $started_count/$total_count PHP-FPM services!"
}

# Function to stop all PHP-FPM services
stop_all_php_fpm() {
    print_color "blue" "🛑 Dừng tất cả PHP-FPM services..."
    echo ""
    
    local stopped_count=0
    local total_count=0
    
    for version in 7.4 8.0 8.1 8.2 8.3; do
        if check_php_version $version; then
            total_count=$((total_count + 1))
            if stop_php_fpm $version; then
                stopped_count=$((stopped_count + 1))
            fi
            echo ""
        fi
    done
    
    echo ""
    print_color "green" "📊 Kết quả: Đã dừng $stopped_count/$total_count PHP-FPM services!"
}

# Function to restart all PHP-FPM services
restart_all_php_fpm() {
    print_color "blue" "🔄 Khởi động lại tất cả PHP-FPM services..."
    echo ""
    
    local restarted_count=0
    local total_count=0
    
    for version in 7.4 8.0 8.1 8.2 8.3; do
        if check_php_version $version; then
            total_count=$((total_count + 1))
            if restart_php_fpm $version; then
                restarted_count=$((restarted_count + 1))
            fi
            echo ""
        fi
    done
    
    echo ""
    print_color "green" "📊 Kết quả: Đã khởi động lại $restarted_count/$total_count PHP-FPM services!"
}

# Function to show PHP-FPM logs
show_logs() {
    local version=$1
    if ! check_php_version $version; then
        print_color "red" "❌ PHP $version chưa được cài đặt!"
        return 1
    fi
    
    local log_file="/opt/homebrew/var/log/php-fpm-$version.log"
    
    if [ ! -f "$log_file" ]; then
        print_color "red" "❌ File log không tồn tại: $log_file"
        return 1
    fi
    
    print_color "blue" "📋 Log của PHP-FPM $version:"
    print_color "blue" "================================"
    echo ""
    
    if [ -s "$log_file" ]; then
        tail -20 "$log_file"
    else
        print_color "orange" "File log trống hoặc không có nội dung."
    fi
}

# Function to show PHP-FPM configuration
show_config() {
    local version=$1
    if ! check_php_version $version; then
        print_color "red" "❌ PHP $version chưa được cài đặt!"
        return 1
    fi
    
    local config_dir="/opt/homebrew/etc/php/$version"
    local fpm_conf="$config_dir/php-fpm.conf"
    local pool_conf="$config_dir/php-fpm.d/www.conf"
    
    print_color "blue" "⚙️ Cấu hình PHP-FPM $version:"
    print_color "blue" "================================="
    echo ""
    
    if [ -f "$fpm_conf" ]; then
        print_color "green" "📄 File cấu hình chính: $fpm_conf"
        echo "Nội dung:"
        cat "$fpm_conf"
        echo ""
    else
        print_color "red" "❌ File cấu hình chính không tồn tại!"
    fi
    
    if [ -f "$pool_conf" ]; then
        print_color "green" "📄 File cấu hình pool: $pool_conf"
        echo "Nội dung:"
        cat "$pool_conf"
    else
        print_color "red" "❌ File cấu hình pool không tồn tại!"
    fi
}

# Function to test PHP-FPM connection
test_connection() {
    local version=$1
    if ! check_php_version $version; then
        print_color "red" "❌ PHP $version chưa được cài đặt!"
        return 1
    fi
    
    local port=$(get_php_fpm_port $version)
    print_color "blue" "🔍 Kiểm tra kết nối PHP-FPM $version trên port $port..."
    
    # Check if service is running
    if ! brew services list | grep -q "php@$version.*started"; then
        print_color "red" "❌ PHP-FPM $version không đang chạy!"
        return 1
    fi
    
    # Test port connection
    if nc -z localhost $port 2>/dev/null; then
        print_color "green" "✅ Port $port đang lắng nghe!"
        
        # Test with PHP-FPM ping
        local test_file="/tmp/php-fpm-test-$version.php"
        cat > "$test_file" << 'EOF'
<?php
echo "PHP-FPM Test - PHP " . PHP_VERSION . "\n";
echo "Server: " . $_SERVER['SERVER_SOFTWARE'] . "\n";
echo "Time: " . date('Y-m-d H:i:s') . "\n";
?>
EOF
        
        print_color "blue" "🧪 Thực hiện test PHP script..."
        php "$test_file"
        rm -f "$test_file"
        
    else
        print_color "red" "❌ Port $port không thể kết nối!"
        return 1
    fi
}

# Function to show menu
show_menu() {
    clear
    print_color "blue" "🐘 PHP-FPM Management Tool"
    print_color "blue" "=========================="
    echo ""
    print_color "green" "1. Hiển thị trạng thái tất cả services"
    print_color "green" "2. Khởi động PHP-FPM cụ thể"
    print_color "green" "3. Dừng PHP-FPM cụ thể"
    print_color "green" "4. Khởi động lại PHP-FPM cụ thể"
    print_color "green" "5. Khởi động tất cả PHP-FPM services"
    print_color "green" "6. Dừng tất cả PHP-FPM services"
    print_color "green" "7. Khởi động lại tất cả PHP-FPM services"
    print_color "green" "8. Xem log của PHP-FPM"
    print_color "green" "9. Xem cấu hình PHP-FPM"
    print_color "green" "10. Test kết nối PHP-FPM"
    print_color "green" "11. Thoát"
    echo ""
}

# Function to select PHP version
select_php_version() {
    local action=$1
    print_color "blue" "Chọn phiên bản PHP để $action:"
    echo ""
    
    local available_versions=()
    for version in 7.4 8.0 8.1 8.2 8.3; do
        if check_php_version $version; then
            available_versions+=($version)
            print_color "green" "  $version) PHP $version"
        fi
    done
    
    if [ ${#available_versions[@]} -eq 0 ]; then
        print_color "red" "❌ Không có phiên bản PHP nào được cài đặt!"
        return 1
    fi
    
    echo ""
    read -p "Nhập lựa chọn: " choice
    
    if [[ " ${available_versions[@]} " =~ " ${choice} " ]]; then
        return 0
    else
        print_color "red" "❌ Lựa chọn không hợp lệ!"
        return 1
    fi
}

# Main loop
main() {
    while true; do
        show_menu
        read -p "Chọn tùy chọn (1-11): " choice
        
        case $choice in
            1) 
                show_status
                ;;
            2) 
                if select_php_version "khởi động"; then
                    start_php_fpm $choice
                fi
                ;;
            3) 
                if select_php_version "dừng"; then
                    stop_php_fpm $choice
                fi
                ;;
            4) 
                if select_php_version "khởi động lại"; then
                    restart_php_fpm $choice
                fi
                ;;
            5) 
                start_all_php_fpm
                ;;
            6) 
                stop_all_php_fpm
                ;;
            7) 
                restart_all_php_fpm
                ;;
            8) 
                if select_php_version "xem log"; then
                    show_logs $choice
                fi
                ;;
            9) 
                if select_php_version "xem cấu hình"; then
                    show_config $choice
                fi
                ;;
            10) 
                if select_php_version "test kết nối"; then
                    test_connection $choice
                fi
                ;;
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
}

# Check if script is run with sudo
if [ "$EUID" -eq 0 ]; then
    print_color "red" "❌ Không nên chạy script này với sudo."
    print_color "blue" "Vui lòng chạy lại không có sudo: bash manage_php_fpm.sh"
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
