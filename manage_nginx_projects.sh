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

# Function to list all projects
list_projects() {
    print_color "blue" "📋 Danh sách các project đã tạo:"
    echo ""
    
    local sites_enabled="/opt/homebrew/etc/nginx/sites-enabled"
    local projects_found=0
    
    if [ -d "$sites_enabled" ]; then
        for config_file in "$sites_enabled"/*; do
            if [ -f "$config_file" ]; then
                local domain=$(basename "$config_file")
                local config_path="/opt/homebrew/etc/nginx/sites-available/$domain"
                
                if [ -f "$config_path" ]; then
                    # Lấy thông tin PHP version từ config
                    local php_version=$(grep -o "fastcgi_pass 127.0.0.1:[0-9]*" "$config_path" | cut -d: -f3)
                    local php_version_name=""
                    
                    case $php_version in
                        "9074") php_version_name="7.4" ;;
                        "9080") php_version_name="8.0" ;;
                        "9081") php_version_name="8.1" ;;
                        "9082") php_version_name="8.2" ;;
                        "9083") php_version_name="8.3" ;;
                        *) php_version_name="Unknown" ;;
                    esac
                    
                    local project_path=$(grep "root" "$config_path" | head -1 | awk '{print $2}' | sed 's/;$//')
                    
                    print_color "green" "🌐 $domain"
                    print_color "blue" "   📁 Path: $project_path"
                    print_color "yellow" "   ⚡ PHP: $php_version_name (Port: $php_version)"
                    print_color "orange" "   🔒 SSL: /opt/homebrew/etc/nginx/ssl/$domain.crt"
                    echo ""
                    
                    projects_found=$((projects_found + 1))
                fi
            fi
        done
    fi
    
    if [ $projects_found -eq 0 ]; then
        print_color "yellow" "Không có project nào được tạo."
    else
        print_color "green" "Tổng cộng: $projects_found project(s)"
    fi
}

# Function to show project details
show_project_details() {
    local domain=$1
    
    if [ -z "$domain" ]; then
        print_color "red" "❌ Vui lòng nhập tên miền!"
        return 1
    fi
    
    local config_path="/opt/homebrew/etc/nginx/sites-available/$domain"
    
    if [ ! -f "$config_path" ]; then
        print_color "red" "❌ Không tìm thấy project: $domain"
        return 1
    fi
    
    print_color "blue" "🔍 Chi tiết project: $domain"
    echo ""
    
    # Lấy thông tin từ config
    local php_version=$(grep -o "fastcgi_pass 127.0.0.1:[0-9]*" "$config_path" | cut -d: -f3)
    local php_version_name=""
    local project_path=$(grep "root" "$config_path" | head -1 | awk '{print $2}' | sed 's/;$//')
    
    case $php_version in
        "9074") php_version_name="7.4" ;;
        "9080") php_version_name="8.0" ;;
        "9081") php_version_name="8.1" ;;
        "9082") php_version_name="8.2" ;;
        "9083") php_version_name="8.3" ;;
        *) php_version_name="Unknown" ;;
    esac
    
    print_color "green" "📋 Thông tin cơ bản:"
    print_color "blue" "   🌐 Domain: $domain"
    print_color "blue" "   📁 Project Path: $project_path"
    print_color "blue" "   ⚡ PHP Version: $php_version_name"
    print_color "blue" "   🔌 PHP-FPM Port: $php_version"
    echo ""
    
    print_color "green" "📁 Cấu trúc thư mục:"
    if [ -d "$project_path" ]; then
        print_color "blue" "   Project Root: $project_path"
        print_color "blue" "   Public: $project_path/public"
        print_color "blue" "   Index: $project_path/public/index.php"
        print_color "blue" "   Info: $project_path/public/info.php"
    else
        print_color "red" "   ❌ Thư mục project không tồn tại!"
    fi
    echo ""
    
    print_color "green" "⚙️ Cấu hình:"
    print_color "blue" "   Nginx Config: $config_path"
    print_color "blue" "   SSL Certificate: /opt/homebrew/etc/nginx/ssl/$domain.crt"
    print_color "blue" "   SSL Key: /opt/homebrew/etc/nginx/ssl/$domain.key"
    echo ""
    
    print_color "green" "📊 Trạng thái:"
    # Kiểm tra Nginx
    if brew services list | grep -q "nginx.*started"; then
        print_color "green" "   ✅ Nginx: Đang chạy"
    else
        print_color "red" "   ❌ Nginx: Không chạy"
    fi
    
    # Kiểm tra PHP-FPM
    if brew services list | grep -q "php@$php_version_name.*started"; then
        print_color "green" "   ✅ PHP-FPM $php_version_name: Đang chạy"
    else
        print_color "red" "   ❌ PHP-FPM $php_version_name: Không chạy"
    fi
    
    # Kiểm tra hosts file
    if grep -q "$domain" /etc/hosts; then
        print_color "green" "   ✅ Hosts file: Đã cập nhật"
    else
        print_color "red" "   ❌ Hosts file: Chưa cập nhật"
    fi
    echo ""
    
    print_color "green" "🔗 Truy cập:"
    print_color "blue" "   🌐 Website: https://$domain"
    print_color "blue" "   📱 PHP Info: https://$domain/info.php"
}

# Function to delete project
delete_project() {
    local domain=$1
    
    if [ -z "$domain" ]; then
        print_color "red" "❌ Vui lòng nhập tên miền!"
        return 1
    fi
    
    local config_path="/opt/homebrew/etc/nginx/sites-available/$domain"
    
    if [ ! -f "$config_path" ]; then
        print_color "red" "❌ Không tìm thấy project: $domain"
        return 1
    fi
    
    print_color "red" "⚠️  Bạn có chắc chắn muốn xóa project: $domain?"
    read -p "Nhập 'yes' để xác nhận: " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_color "blue" "Hủy xóa project"
        return 0
    fi
    
    print_color "blue" "🗑️  Đang xóa project: $domain..."
    
    # Lấy thông tin project trước khi xóa
    local project_path=$(grep "root" "$config_path" | head -1 | awk '{print $2}' | sed 's/;$//')
    
    # Xóa symbolic link
    sudo rm -f "/opt/homebrew/etc/nginx/sites-enabled/$domain"
    check_status "Đã xóa symbolic link"
    
    # Xóa config file
    sudo rm -f "$config_path"
    check_status "Đã xóa file cấu hình"
    
    # Xóa SSL certificate
    sudo rm -f "/opt/homebrew/etc/nginx/ssl/$domain.crt"
    sudo rm -f "/opt/homebrew/etc/nginx/ssl/$domain.key"
    check_status "Đã xóa SSL certificate"
    
    # Xóa thư mục project
    if [ -d "$project_path" ]; then
        sudo rm -rf "$project_path"
        check_status "Đã xóa thư mục project"
    fi
    
    # Xóa khỏi hosts file
    sudo sed -i '' "/$domain/d" /etc/hosts
    check_status "Đã xóa khỏi hosts file"
    
    # Xóa log files
    sudo rm -f "/opt/homebrew/var/log/nginx/$domain-access.log"
    sudo rm -f "/opt/homebrew/var/log/nginx/$domain-error.log"
    check_status "Đã xóa log files"
    
    # Kiểm tra và restart Nginx
    print_color "blue" "🔍 Kiểm tra cấu hình Nginx..."
    if nginx -t; then
        print_color "green" "✓ Cấu hình Nginx hợp lệ"
        
        # Reload Nginx
        print_color "blue" "🔄 Reload Nginx..."
        nginx -s reload
        check_status "Đã reload Nginx"
    else
        print_color "red" "❌ Cấu hình Nginx có lỗi!"
        print_color "blue" "Vui lòng kiểm tra và sửa lỗi thủ công"
    fi
    
    print_color "green" "✅ Đã xóa project $domain thành công!"
}

# Function to restart services
restart_services() {
    print_color "blue" "🔄 Đang restart các services..."
    
    # Restart Nginx
    print_color "blue" "Restart Nginx..."
    brew services restart nginx
    check_status "Đã restart Nginx"
    
    # Restart tất cả PHP-FPM services
    print_color "blue" "Restart PHP-FPM services..."
    for version in 7.4 8.0 8.1 8.2 8.3; do
        if [ -d "/opt/homebrew/opt/php@$version" ]; then
            brew services restart "php@$version" 2>/dev/null
            if [ $? -eq 0 ]; then
                print_color "green" "   ✅ PHP $version: Đã restart"
            else
                print_color "yellow" "   ⚠️  PHP $version: Không thể restart"
            fi
        fi
    done
    
    print_color "green" "✅ Đã restart tất cả services!"
}

# Function to show services status
show_services_status() {
    print_color "blue" "📊 Trạng thái các services:"
    echo ""
    
    # Nginx status
    if brew services list | grep -q "nginx.*started"; then
        print_color "green" "✅ Nginx: Đang chạy"
    else
        print_color "red" "❌ Nginx: Không chạy"
    fi
    
    # PHP-FPM status
    print_color "blue" "PHP-FPM Services:"
    for version in 7.4 8.0 8.1 8.2 8.3; do
        if [ -d "/opt/homebrew/opt/php@$version" ]; then
            local port=$(get_php_fpm_port $version)
            if brew services list | grep -q "php@$version.*started"; then
                print_color "green" "   ✅ PHP $version: Đang chạy (Port: $port)"
            else
                print_color "red" "   ❌ PHP $version: Không chạy (Port: $port)"
            fi
        fi
    done
    
    echo ""
    print_color "blue" "Để xem chi tiết: brew services list"
}

# Function to show help
show_help() {
    print_color "blue" "
=== 🛠️  Nginx Multi-PHP Project Manager ===

Cách sử dụng: ./manage_nginx_projects.sh <command> [options]

📋 Commands:
   list                    - Hiển thị danh sách tất cả projects
   show <domain>          - Hiển thị chi tiết project cụ thể
   delete <domain>        - Xóa project
   restart                - Restart tất cả services
   status                 - Hiển thị trạng thái services
   help                   - Hiển thị hướng dẫn này

💡 Ví dụ:
   ./manage_nginx_projects.sh list
   ./manage_nginx_projects.sh show project.test
   ./manage_nginx_projects.sh delete project.test
   ./manage_nginx_projects.sh restart
   ./manage_nginx_projects.sh status
"
}

# Main function
main() {
    local command=$1
    local domain=$2
    
    case $command in
        "list")
            list_projects
            ;;
        "show")
            show_project_details "$domain"
            ;;
        "delete")
            delete_project "$domain"
            ;;
        "restart")
            restart_services
            ;;
        "status")
            show_services_status
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
