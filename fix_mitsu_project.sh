#!/bin/bash

# 🚀 Fix Nhanh Dự Án Mitsuheavy-Ecommerce
# Sửa các vấn đề CSP, font loading và JavaScript

set -e

# Màu sắc
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}🔧 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function để fix một dự án cụ thể
fix_project() {
    local project_name=$1
    local domain="${project_name}.code"
    local project_path="/opt/homebrew/var/www/$project_name"
    local nginx_config="/opt/homebrew/etc/nginx/sites-available/$domain"
    
    print_status "🔧 Đang fix dự án: $project_name"
    
    # Kiểm tra dự án
    if [ ! -d "$project_path" ]; then
        print_error "Dự án không tồn tại tại: $project_path"
        return 1
    fi
    
    if [ ! -f "$nginx_config" ]; then
        print_error "Cấu hình Nginx không tồn tại: $nginx_config"
        return 1
    fi
    
    print_success "Dự án và cấu hình Nginx đã tồn tại"
    
    # Backup cấu hình cũ
    print_status "Backup cấu hình cũ..."
    cp "$nginx_config" "${nginx_config}.backup.$(date +%Y%m%d_%H%M%S)"
    print_success "Đã backup cấu hình cũ"
    
    # Tạo cấu hình Nginx mới với fix
    print_status "Tạo cấu hình Nginx mới với fix..."
    
    # Auto-detect PHP version based on project name
    local php_port="9082"  # Default PHP 8.2
    if [ "$project_name" = "haili-baohanh" ]; then
        php_port="9074"  # PHP 7.4
    fi
    
    # Auto-detect PHP version from .php-version file if exists
    if [ -f "$project_path/.php-version" ]; then
        local project_php_version=$(cat "$project_path/.php-version" | tr -d '[:space:]')
        case $project_php_version in
            "7.4") php_port="9074" ;;
            "8.0") php_port="9080" ;;
            "8.1") php_port="9081" ;;
            "8.2") php_port="9082" ;;
            "8.3") php_port="9083" ;;
        esac
        print_info "   📋 Dự án yêu cầu PHP $project_php_version (Port $php_port)"
    fi
    
    cat > "$nginx_config" << EOF
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
    ssl_certificate     /opt/homebrew/etc/nginx/ssl/$domain.crt;
    ssl_certificate_key /opt/homebrew/etc/nginx/ssl/$domain.key;
    
    # SSL Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    
    index index.php index.html;
    charset utf-8;
    client_max_body_size 100M;
    
    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Content Security Policy - Allow Vue.js and modern web apps
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline' 'unsafe-eval'; font-src 'self' http: https: data: blob:; img-src 'self' http: https: data: blob:; script-src 'self' 'unsafe-inline' 'unsafe-eval' http: https:; style-src 'self' 'unsafe-inline' http: https:; connect-src 'self' http: https: wss: ws:;" always;
    
    # Logs
    access_log /opt/homebrew/var/log/nginx/$domain-access.log combined;
    error_log /opt/homebrew/var/log/nginx/$domain-error.log warn;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
        
        # Handle Vue.js routing
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            add_header Access-Control-Allow-Origin "*";
            try_files \$uri =404;
        }
    }
    
    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }
    
    # PHP-FPM Configuration - Auto-detect PHP version
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
        add_header Access-Control-Allow-Origin "*";
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range";
    }
    
    # Font files with proper CORS headers
    location ~* \.(woff|woff2|ttf|eot|otf)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Access-Control-Allow-Origin "*";
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range";
        add_header Vary "Accept-Encoding";
    }
}
EOF
    
    print_success "Đã tạo cấu hình Nginx mới cho $project_name"
    return 0
}

# Main function
main() {
    # Kiểm tra tham số
    if [ "$1" = "all" ]; then
        print_status "🚀 Fix tất cả dự án..."
        
        # Lấy danh sách tất cả dự án
        if [ -d "/opt/homebrew/var/www" ]; then
            local projects=()
            for project in /opt/homebrew/var/www/*; do
                if [ -d "$project" ]; then
                    projects+=("$(basename "$project")")
                fi
            done
            
            if [ ${#projects[@]} -eq 0 ]; then
                print_warning "Không có dự án nào được tạo!"
                return
            fi
            
            print_info "Tìm thấy ${#projects[@]} dự án:"
            for project in "${projects[@]}"; do
                echo "  📁 $project"
            done
            
            echo ""
            read -p "Bạn có muốn fix tất cả dự án này không? (y/N): " confirm
            
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                local success_count=0
                local total_count=${#projects[@]}
                
                for project in "${projects[@]}"; do
                    echo ""
                    if fix_project "$project"; then
                        ((success_count++))
                    fi
                done
                
                echo ""
                print_success "🎉 Đã fix xong $success_count/$total_count dự án!"
                
                # Kiểm tra cấu hình Nginx
                print_status "Kiểm tra cấu hình Nginx..."
                if nginx -t 2>&1 | grep -q "syntax is ok"; then
                    print_success "Cấu hình Nginx hợp lệ"
                    
                    # Reload Nginx
                    print_status "Reload Nginx..."
                    nginx -s reload 2>/dev/null
                    if [ $? -eq 0 ]; then
                        print_success "Đã reload Nginx thành công"
                    else
                        print_warning "Reload Nginx thất bại, thử restart..."
                        brew services restart nginx
                        print_success "Đã restart Nginx"
                    fi
                else
                    print_error "Cấu hình Nginx có lỗi!"
                    nginx -t
                    exit 1
                fi
            else
                print_info "Đã hủy fix tất cả dự án"
            fi
        else
            print_error "Thư mục dự án không tồn tại!"
        fi
        
    elif [ "$1" = "list" ]; then
        print_status "📋 Danh sách dự án:"
        
        if [ -d "/opt/homebrew/var/www" ]; then
            local projects=()
            for project in /opt/homebrew/var/www/*; do
                if [ -d "$project" ]; then
                    projects+=("$(basename "$project")")
                fi
            done
            
            if [ ${#projects[@]} -eq 0 ]; then
                echo "Không có dự án nào được tạo!"
            else
                for i in "${!projects[@]}"; do
                    local project="${projects[$i]}"
                    local domain="${project}.code"
                    local nginx_config="/opt/homebrew/etc/nginx/sites-available/$domain"
                    
                    if [ -f "$nginx_config" ]; then
                        echo "  $((i+1))) $project (✅ Có cấu hình Nginx)"
                    else
                        echo "  $((i+1))) $project (❌ Chưa có cấu hình Nginx)"
                    fi
                done
            fi
        else
            echo "Thư mục dự án không tồn tại!"
        fi
        
    elif [ "$1" = "status" ]; then
        print_status "📊 Trạng thái các dự án:"
        
        if [ -d "/opt/homebrew/var/www" ]; then
            local projects=()
            for project in /opt/homebrew/var/www/*; do
                if [ -d "$project" ]; then
                    projects+=("$(basename "$project")")
                fi
            done
            
            if [ ${#projects[@]} -eq 0 ]; then
                echo "Không có dự án nào được tạo!"
            else
                for project in "${projects[@]}"; do
                    local domain="${project}.code"
                    echo ""
                    print_info "Dự án: $project"
                    
                    # Kiểm tra cấu hình Nginx
                    local nginx_config="/opt/homebrew/etc/nginx/sites-available/$domain"
                    if [ -f "$nginx_config" ]; then
                        echo "  ✅ Cấu hình Nginx: OK"
                        
                        # Kiểm tra website
                        if curl -k -s -o /dev/null -w "%{http_code}" "https://$domain" 2>/dev/null | grep -q "200\|301\|302"; then
                            echo "  ✅ Website: Hoạt động (https://$domain)"
                        else
                            echo "  ❌ Website: Không hoạt động"
                        fi
                    else
                        echo "  ❌ Cấu hình Nginx: Chưa có"
                    fi
                done
            fi
        else
            echo "Thư mục dự án không tồn tại!"
        fi
        
    elif [ -n "$1" ]; then
        # Fix dự án cụ thể
        if fix_project "$1"; then
            echo ""
            print_success "🎉 Đã fix xong dự án $1!"
            echo "Các vấn đề đã được sửa:"
            echo "  ✅ Content Security Policy (CSP) - Cho phép Vue.js hoạt động"
            echo "  ✅ Font loading - CORS headers cho fonts"
            echo "  ✅ JavaScript execution - Cho phép 'unsafe-eval'"
            echo "  ✅ Static file handling - Cache và CORS cho assets"
            echo ""
            echo "Truy cập: https://$1.code"
            echo "Kiểm tra Console để xem còn lỗi nào không"
        fi
        
    else
        # Hiển thị trợ giúp
        echo "🚀 Fix Nhanh Dự Án - Hỗ trợ tất cả dự án"
        echo "=========================================="
        echo ""
        echo "Cách sử dụng:"
        echo "  $0                    - Hiển thị trợ giúp"
        echo "  $0 all                - Fix tất cả dự án"
        echo "  $0 list               - Liệt kê tất cả dự án"
        echo "  $0 status             - Kiểm tra trạng thái tất cả dự án"
        echo "  $0 <tên_dự_án>       - Fix dự án cụ thể"
        echo ""
        echo "Ví dụ:"
        echo "  $0 all                - Fix tất cả dự án"
        echo "  $0 mitsuheavy-ecommerce - Fix dự án mitsuheavy-ecommerce"
        echo "  $0 haili-baohanh      - Fix dự án haili-baohanh"
        echo ""
        echo "Các vấn đề sẽ được sửa:"
        echo "  ✅ Content Security Policy (CSP)"
        echo "  ✅ Font loading với CORS headers"
        echo "  ✅ JavaScript execution"
        echo "  ✅ Static file handling"
        echo "  ✅ Auto-detect PHP version từ .php-version"
    fi
}

# Function in màu
print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Gọi main function
main "$@"
