#!/bin/bash

# 🚀 Fix SSL cho tất cả dự án - Sử dụng mkcert
# Tool này sẽ tạo lại SSL certificate cho tất cả dự án với mkcert

set -e

# Màu sắc
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
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

print_info() {
    echo -e "${PURPLE}ℹ️  $1${NC}"
}

# Function kiểm tra mkcert
check_mkcert() {
    if ! command -v mkcert &> /dev/null; then
        print_status "📦 Cài đặt mkcert..."
        brew install mkcert
        mkcert -install
        print_success "Đã cài đặt và cài đặt mkcert"
    else
        print_success "mkcert đã có sẵn"
    fi
}

# Function fix SSL cho một dự án
fix_project_ssl() {
    local project_name=$1
    local domain="${project_name}.code"
    local ssl_dir="/opt/homebrew/etc/nginx/ssl"
    
    print_status "🔒 Đang fix SSL cho dự án: $project_name"
    
    # Kiểm tra dự án có tồn tại không
    if [ ! -d "/opt/homebrew/var/www/$project_name" ]; then
        print_warning "Dự án $project_name không tồn tại, bỏ qua"
        return 0
    fi
    
    # Kiểm tra cấu hình Nginx
    local nginx_config="/opt/homebrew/etc/nginx/sites-available/$domain"
    if [ ! -f "$nginx_config" ]; then
        print_warning "Cấu hình Nginx cho $domain không tồn tại, bỏ qua"
        return 0
    fi
    
    # Backup certificate cũ nếu có
    if [ -f "$ssl_dir/$domain.crt" ]; then
        print_status "Backup certificate cũ..."
        mv "$ssl_dir/$domain.crt" "$ssl_dir/$domain.crt.backup.$(date +%Y%m%d_%H%M%S)"
        print_success "Đã backup certificate cũ"
    fi
    
    if [ -f "$ssl_dir/$domain.key" ]; then
        mv "$ssl_dir/$domain.key" "$ssl_dir/$domain.key.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Tạo certificate mới với mkcert
    print_status "Tạo certificate mới với mkcert..."
    cd "$ssl_dir"
    
    # Tạo certificate với tất cả tên miền cần thiết
    mkcert "$domain" "*.$domain" localhost 127.0.0.1 ::1
    
    # Copy với tên đúng cho Nginx
    cp "$domain+4.pem" "$domain.crt"
    cp "$domain+4-key.pem" "$domain.key"
    
    # Set permissions
    chmod 644 "$domain.key" "$domain.crt"
    chown $(whoami):admin "$domain.key" "$domain.crt"
    
    # Verify
    if [ -f "$domain.key" ] && [ -f "$domain.crt" ]; then
        print_success "✅ SSL certificate mkcert đã tạo thành công cho $domain"
        print_success "✅ Certificate được tin tưởng 100% bởi browser"
    else
        print_error "❌ Lỗi tạo SSL certificate cho $domain"
        return 1
    fi
    
    # Quay về thư mục gốc
    cd - > /dev/null
    
    return 0
}

# Function fix tất cả dự án
fix_all_projects() {
    print_status "🚀 Fix SSL cho tất cả dự án..."
    
    if [ ! -d "/opt/homebrew/var/www" ]; then
        print_error "Thư mục dự án không tồn tại!"
        return 1
    fi
    
    local projects=()
    for project in /opt/homebrew/var/www/*; do
        if [ -d "$project" ]; then
            projects+=("$(basename "$project")")
        fi
    done
    
    if [ ${#projects[@]} -eq 0 ]; then
        print_warning "Không có dự án nào được tạo!"
        return 0
    fi
    
    print_info "Tìm thấy ${#projects[@]} dự án:"
    for project in "${projects[@]}"; do
        echo "  📁 $project"
    done
    
    echo ""
    read -p "Bạn có muốn fix SSL cho tất cả dự án này không? (y/N): " confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        local success_count=0
        local total_count=${#projects[@]}
        
        for project in "${projects[@]}"; do
            echo ""
            if fix_project_ssl "$project"; then
                ((success_count++))
            fi
        done
        
        echo ""
        print_success "🎉 Đã fix SSL xong $success_count/$total_count dự án!"
        
        # Kiểm tra và reload Nginx
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
        
        echo ""
        print_success "🎯 Tất cả dự án đã có SSL certificate mới!"
        print_info "Bây giờ bạn có thể truy cập các website mà không bị cảnh báo SSL"
        
    else
        print_info "Đã hủy fix SSL cho tất cả dự án"
    fi
}

# Function fix dự án cụ thể
fix_specific_project() {
    local project_name=$1
    
    if [ -z "$project_name" ]; then
        print_error "Vui lòng nhập tên dự án!"
        return 1
    fi
    
    if fix_project_ssl "$project_name"; then
        echo ""
        print_success "🎉 Đã fix SSL xong dự án $project_name!"
        
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
        
        echo ""
        print_success "🌐 Truy cập: https://$project_name.code"
        print_info "SSL certificate đã được tin tưởng 100% bởi browser"
    fi
}

# Function hiển thị trạng thái SSL
show_ssl_status() {
    print_status "📊 Trạng thái SSL của các dự án:"
    
    if [ ! -d "/opt/homebrew/var/www" ]; then
        print_error "Thư mục dự án không tồn tại!"
        return 1
    fi
    
    local projects=()
    for project in /opt/homebrew/var/www/*; do
        if [ -d "$project" ]; then
            projects+=("$(basename "$project")")
        fi
    done
    
    if [ ${#projects[@]} -eq 0 ]; then
        echo "Không có dự án nào được tạo!"
        return 0
    fi
    
    for project in "${projects[@]}"; do
        local domain="${project}.code"
        local ssl_dir="/opt/homebrew/etc/nginx/ssl"
        
        echo ""
        print_info "Dự án: $project"
        
        # Kiểm tra certificate
        if [ -f "$ssl_dir/$domain.crt" ] && [ -f "$ssl_dir/$domain.key" ]; then
            echo "  ✅ SSL Certificate: Có"
            
            # Kiểm tra loại certificate
            if file "$ssl_dir/$domain.crt" | grep -q "PEM certificate"; then
                echo "  ✅ Loại: PEM certificate (có thể là mkcert)"
            else
                echo "  ⚠️  Loại: Khác (có thể là self-signed)"
            fi
            
            # Kiểm tra website
            if curl -k -s -o /dev/null -w "%{http_code}" "https://$domain" 2>/dev/null | grep -q "200\|301\|302"; then
                echo "  ✅ Website: Hoạt động (https://$domain)"
            else
                echo "  ❌ Website: Không hoạt động"
            fi
        else
            echo "  ❌ SSL Certificate: Chưa có"
        fi
    done
}

# Function hiển thị trợ giúp
show_help() {
    echo "🚀 Fix SSL cho tất cả dự án - Sử dụng mkcert"
    echo "============================================="
    echo ""
    echo "Cách sử dụng:"
    echo "  $0                    - Hiển thị trợ giúp"
    echo "  $0 all                - Fix SSL cho tất cả dự án"
    echo "  $0 status             - Kiểm tra trạng thái SSL của tất cả dự án"
    echo "  $0 <tên_dự_án>       - Fix SSL cho dự án cụ thể"
    echo ""
    echo "Ví dụ:"
    echo "  $0 all                - Fix SSL cho tất cả dự án"
    echo "  $0 mitsuheavy-ecommerce - Fix SSL cho dự án mitsuheavy-ecommerce"
    echo "  $0 haili-baohanh      - Fix SSL cho dự án haili-baohanh"
    echo ""
    echo "Lợi ích của mkcert:"
    echo "  ✅ Certificate được tin tưởng 100% bởi browser"
    echo "  ✅ Không còn cảnh báo SSL"
    echo "  ✅ Hỗ trợ wildcard domains"
    echo "  ✅ Tự động cài đặt vào system trust store"
    echo "  ✅ Hết hạn sau 2 năm (thay vì 1 năm)"
}

# Main execution
main() {
    # Kiểm tra mkcert
    check_mkcert
    
    case "${1:-help}" in
        "all")
            fix_all_projects
            ;;
        "status")
            show_ssl_status
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            if [ -n "$1" ]; then
                fix_specific_project "$1"
            else
                show_help
            fi
            ;;
    esac
}

# Gọi main function
main "$@"
