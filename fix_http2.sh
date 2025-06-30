#!/bin/bash

# Colors
GREEN="\033[0;32m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

echo -e "${BLUE}Đang sửa cấu hình HTTP/2 cho các virtual host...${NC}"

# Đường dẫn đến thư mục sites-enabled
SITES_ENABLED="/opt/homebrew/etc/nginx/sites-enabled"

# Lặp qua tất cả các file trong sites-enabled
for file in "$SITES_ENABLED"/*; do
    if [ -f "$file" ]; then
        echo -e "${BLUE}Đang xử lý file: $(basename "$file")${NC}"
        
        # Tạo file tạm
        temp_file=$(mktemp)
        
        # Thay thế cấu hình HTTP/2
        sed 's/listen 443 ssl http2;/listen 443 ssl;\n    http2 on;/' "$file" > "$temp_file"
        
        # Di chuyển file tạm về file gốc
        mv "$temp_file" "$file"
        
        echo -e "${GREEN}✓ Đã cập nhật: $(basename "$file")${NC}"
    fi
done

echo -e "${BLUE}Kiểm tra cấu hình Nginx...${NC}"
nginx -t

echo -e "${BLUE}Khởi động lại Nginx...${NC}"
brew services restart nginx

echo -e "${GREEN}Hoàn tất!${NC}" 