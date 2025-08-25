#!/bin/bash

# Colors
GREEN="\\033[1;32m"
RED="\\033[1;31m"
BLUE="\\033[1;34m"
YELLOW="\\033[1;33m"
NORMAL="\\033[0;39m"

echo -e "${BLUE}🔄 Migration Tool: .code → .test${NORMAL}"
echo "======================================"
echo ""

# Kiểm tra xem có domain .code nào không
code_domains=$(find /opt/homebrew/etc/nginx/sites-available -name "*.code" 2>/dev/null | wc -l)

if [ "$code_domains" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Không tìm thấy domain .code nào để migrate!${NORMAL}"
    exit 0
fi

echo -e "${BLUE}📋 Tìm thấy $code_domains domain .code:${NORMAL}"
echo ""

# Liệt kê các domain .code
find /opt/homebrew/etc/nginx/sites-available -name "*.code" 2>/dev/null | while read -r config_file; do
    domain=$(basename "$config_file")
    echo -e "${YELLOW}• $domain${NORMAL}"
done

echo ""
read -p "Bạn có muốn migrate tất cả domain .code sang .test? (y/N): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}❌ Migration đã bị hủy!${NORMAL}"
    exit 0
fi

echo ""
echo -e "${BLUE}🚀 Bắt đầu migration...${NORMAL}"
echo ""

# Backup SSL certificates
ssl_backup_dir="/opt/homebrew/etc/nginx/ssl/backup_$(date +%Y%m%d_%H%M%S)"
sudo mkdir -p "$ssl_backup_dir"
echo -e "${BLUE}📦 Backup SSL certificates vào: $ssl_backup_dir${NORMAL}"

# Migrate từng domain
find /opt/homebrew/etc/nginx/sites-available -name "*.code" 2>/dev/null | while read -r config_file; do
    old_domain=$(basename "$config_file")
    new_domain="${old_domain%.code}.test"
    
    echo ""
    echo -e "${BLUE}🔄 Migrating: $old_domain → $new_domain${NORMAL}"
    
    # 1. Backup config cũ
    sudo cp "$config_file" "${config_file}.backup"
    
    # 2. Tạo config mới với domain .test
    sudo cp "$config_file" "/opt/homebrew/etc/nginx/sites-available/$new_domain"
    
    # 3. Cập nhật nội dung config
    sudo sed -i '' "s/$old_domain/$new_domain/g" "/opt/homebrew/etc/nginx/sites-available/$new_domain"
    
    # 4. Cập nhật log paths
    sudo sed -i '' "s/$old_domain/$new_domain/g" "/opt/homebrew/etc/nginx/sites-available/$new_domain"
    
    # 5. Xóa config cũ
    sudo rm -f "$config_file"
    
    # 6. Cập nhật symbolic link
    if [ -L "/opt/homebrew/etc/nginx/sites-enabled/$old_domain" ]; then
        sudo rm -f "/opt/homebrew/etc/nginx/sites-enabled/$old_domain"
        sudo ln -sf "/opt/homebrew/etc/nginx/sites-available/$new_domain" "/opt/homebrew/etc/nginx/sites-enabled/$new_domain"
    fi
    
    # 7. Migrate SSL certificates
    ssl_dir="/opt/homebrew/etc/nginx/ssl"
    if [ -f "$ssl_dir/$old_domain.crt" ] && [ -f "$ssl_dir/$old_domain.key" ]; then
        echo -e "${BLUE}🔒 Migrating SSL certificates...${NORMAL}"
        
        # Backup certificates cũ
        sudo cp "$ssl_dir/$old_domain.crt" "$ssl_backup_dir/"
        sudo cp "$ssl_dir/$old_domain.key" "$ssl_backup_dir/"
        
        # Tạo certificates mới cho domain .test
        cd "$ssl_dir"
        mkcert "$new_domain" "*.$new_domain" localhost 127.0.0.1 ::1
        cp "$new_domain+4.pem" "$new_domain.crt"
        cp "$new_domain+4-key.pem" "$new_domain.key"
        sudo chmod 644 "$new_domain.key" "$new_domain.crt"
        sudo chown $(whoami):admin "$new_domain.key" "$new_domain.crt"
        cd - > /dev/null
        
        # Xóa certificates cũ
        sudo rm -f "$ssl_dir/$old_domain.crt" "$ssl_dir/$old_domain.key"
        sudo rm -f "$ssl_dir/$old_domain+4.pem" "$ssl_dir/$old_domain+4-key.pem"
    fi
    
    # 8. Cập nhật hosts file
    sudo sed -i '' "s/$old_domain/$new_domain/g" /etc/hosts
    
    echo -e "${GREEN}✅ Đã migrate: $old_domain → $new_domain${NORMAL}"
done

echo ""
echo -e "${BLUE}🔧 Kiểm tra cấu hình Nginx...${NORMAL}"

if nginx -t; then
    echo -e "${GREEN}✅ Cấu hình Nginx OK!${NORMAL}"
    echo -e "${BLUE}🔄 Restart Nginx...${NORMAL}"
    brew services restart nginx
    
    echo ""
    echo -e "${GREEN}🎉 Migration hoàn tất!${NORMAL}"
    echo ""
    echo -e "${BLUE}📋 Danh sách domain mới:${NORMAL}"
    find /opt/homebrew/etc/nginx/sites-available -name "*.test" 2>/dev/null | while read -r config_file; do
        domain=$(basename "$config_file")
        echo -e "${GREEN}• $domain${NORMAL}"
    done
    
    echo ""
    echo -e "${BLUE}💡 Backup được lưu tại: $ssl_backup_dir${NORMAL}"
    echo -e "${BLUE}🌐 Bây giờ bạn có thể truy cập các domain .test!${NORMAL}"
    
else
    echo -e "${RED}❌ Cấu hình Nginx có lỗi!${NORMAL}"
    echo -e "${YELLOW}⚠️  Kiểm tra logs và khôi phục từ backup nếu cần!${NORMAL}"
    exit 1
fi
