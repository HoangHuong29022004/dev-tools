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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
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

print_color "blue" "🚀 Nginx Multi-PHP Quick Setup"
print_color "blue" "==============================="
echo ""

# Check if script is run with sudo
if [ "$EUID" -eq 0 ]; then
    print_color "red" "❌ Không nên chạy script này với sudo."
    print_color "blue" "Vui lòng chạy lại không có sudo: bash quick_setup.sh"
    exit 1
fi

# Check Homebrew
if ! command_exists brew; then
    print_color "red" "❌ Homebrew chưa được cài đặt!"
    print_color "blue" "Vui lòng cài đặt Homebrew trước:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

print_color "green" "✅ Homebrew đã được cài đặt"

# Check Nginx
if ! command_exists nginx; then
    print_color "orange" "⚠️ Nginx chưa được cài đặt!"
    read -p "Bạn có muốn cài đặt Nginx không? (y/N): " install_nginx
    
    if [ "$install_nginx" = "y" ] || [ "$install_nginx" = "Y" ]; then
        print_color "blue" "📦 Đang cài đặt Nginx..."
        bash install_nginx.sh
    else
        print_color "red" "❌ Không thể tiếp tục mà không có Nginx!"
        exit 1
    fi
else
    print_color "green" "✅ Nginx đã được cài đặt"
fi

# Check PHP versions
print_color "blue" "🔍 Kiểm tra các phiên bản PHP..."
echo ""

php_versions=()
for version in 7.4 8.0 8.1 8.2 8.3; do
    if check_php_version $version; then
        php_versions+=($version)
        print_color "green" "  ✓ PHP $version đã cài đặt"
    else
        print_color "red" "  ✗ PHP $version chưa cài đặt"
    fi
done

echo ""

if [ ${#php_versions[@]} -eq 0 ]; then
    print_color "red" "❌ Không có phiên bản PHP nào được cài đặt!"
    print_color "blue" "Vui lòng cài đặt ít nhất một phiên bản PHP:"
    echo "  brew install php@7.4"
    echo "  brew install php@8.2"
    exit 1
fi

print_color "green" "✅ Đã tìm thấy ${#php_versions[@]} phiên bản PHP"

# Check if Nginx is running
if brew services list | grep -q "nginx.*started"; then
    print_color "green" "✅ Nginx đang chạy"
else
    print_color "orange" "⚠️ Nginx không chạy, đang khởi động..."
    brew services start nginx
fi

# Check PHP-FPM services
print_color "blue" "🔍 Kiểm tra PHP-FPM services..."
echo ""

running_php=0
for version in "${php_versions[@]}"; do
    if brew services list | grep -q "php@$version.*started"; then
        print_color "green" "  ✓ PHP-FPM $version đang chạy"
        running_php=$((running_php + 1))
    else
        print_color "orange" "  ⚠️ PHP-FPM $version không chạy"
    fi
done

echo ""

if [ "$running_php" -eq 0 ]; then
    print_color "orange" "⚠️ Không có PHP-FPM nào đang chạy!"
    read -p "Bạn có muốn khởi động tất cả PHP-FPM services không? (y/N): " start_php_fpm
    
    if [ "$start_php_fpm" = "y" ] || [ "$start_php_fpm" = "Y" ]; then
        print_color "blue" "🚀 Khởi động tất cả PHP-FPM services..."
        bash manage_php_fpm.sh
        # Exit manage_php_fpm.sh and continue
        echo ""
        print_color "green" "✅ Đã khởi động PHP-FPM services"
    fi
fi

# Check Nginx configuration
print_color "blue" "🔍 Kiểm tra cấu hình Nginx..."
if nginx -t; then
    print_color "green" "✅ Cấu hình Nginx hợp lệ"
else
    print_color "red" "❌ Cấu hình Nginx có lỗi!"
    print_color "blue" "Vui lòng kiểm tra và sửa lỗi trước khi tiếp tục"
    exit 1
fi

# Show current status
print_color "blue" "📊 Trạng thái hiện tại:"
echo ""

# Show Nginx status
if brew services list | grep -q "nginx.*started"; then
    print_color "green" "  ✓ Nginx: Đang chạy"
else
    print_color "red" "  ✗ Nginx: Không chạy"
fi

# Show PHP-FPM status
for version in "${php_versions[@]}"; do
    if brew services list | grep -q "php@$version.*started"; then
        print_color "green" "  ✓ PHP-FPM $version: Đang chạy"
    else
        print_color "red" "  ✗ PHP-FPM $version: Không chạy"
    fi
done

# Show active sites
echo ""
if [ -d "/opt/homebrew/etc/nginx/sites-enabled" ]; then
    active_sites=$(ls /opt/homebrew/etc/nginx/sites-enabled/ 2>/dev/null | wc -l)
    if [ $active_sites -gt 0 ]; then
        print_color "blue" "🌍 Active sites: $active_sites"
        for site in /opt/homebrew/etc/nginx/sites-enabled/*; do
            if [ -f "$site" ]; then
                domain=$(basename "$site")
                php_version=$(grep "fastcgi_pass" "$site" | grep -o "127.0.0.1:[0-9]*" | cut -d: -f2)
                php_ver_name=""
                case $php_version in
                    "9074") php_ver_name="7.4" ;;
                    "9080") php_ver_name="8.0" ;;
                    "9081") php_ver_name="8.1" ;;
                    "9082") php_ver_name="8.2" ;;
                    "9083") php_ver_name="8.3" ;;
                    *) php_ver_name="Unknown" ;;
                esac
                print_color "green" "  - $domain (PHP $php_ver_name)"
            fi
        done
    else
        print_color "orange" "🌍 Chưa có active sites nào"
    fi
fi

echo ""
print_color "green" "🎉 Setup hoàn tất!"
echo ""

# Show next steps
print_color "blue" "📋 Bước tiếp theo:"
print_color "green" "1. Tạo dự án mới: bash setup_nginx_multi_php.sh"
print_color "green" "2. Quản lý PHP-FPM: bash manage_php_fpm.sh"
print_color "green" "3. Xem hướng dẫn chi tiết: cat README_NGINX_MULTI_PHP.md"
echo ""

# Ask if user wants to create a project now
read -p "Bạn có muốn tạo dự án đầu tiên ngay bây giờ không? (y/N): " create_project

if [ "$create_project" = "y" ] || [ "$create_project" = "Y" ]; then
    print_color "blue" "🚀 Khởi động tool tạo dự án..."
    bash setup_nginx_multi_php.sh
else
    print_color "blue" "💡 Để tạo dự án sau, chạy: bash setup_nginx_multi_php.sh"
fi

echo ""
print_color "purple" "🔗 Các lệnh hữu ích:"
print_color "green" "  - Tạo dự án: bash setup_nginx_multi_php.sh"
print_color "green" "  - Quản lý PHP-FPM: bash manage_php_fpm.sh"
print_color "green" "  - Kiểm tra services: brew services list"
print_color "green" "  - Test Nginx: nginx -t"
print_color "green" "  - Restart Nginx: brew services restart nginx"
echo ""
print_color "green" "🎯 Chúc bạn sử dụng tool hiệu quả!"
