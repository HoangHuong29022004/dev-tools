#!/bin/bash

# Colors
GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
NORMAL="\033[0;39m"

echo -e "${BLUE}🔧 Fix PHP 8.4 Service${NORMAL}"
echo "========================="
echo ""

# Tạo thư mục config cho PHP 8.4
echo -e "${BLUE}📁 Tạo thư mục config PHP 8.4...${NORMAL}"
sudo mkdir -p /opt/homebrew/etc/php/8.4
sudo chown -R $(whoami):admin /opt/homebrew/etc/php/8.4
sudo chmod -R 755 /opt/homebrew/etc/php/8.4

# Copy config từ bottle
echo -e "${BLUE}📋 Copy config từ bottle...${NORMAL}"
sudo cp -r /opt/homebrew/Cellar/php/8.4.12/.bottle/etc/php/8.4/* /opt/homebrew/etc/php/8.4/
sudo chown -R $(whoami):admin /opt/homebrew/etc/php/8.4
sudo chmod -R 755 /opt/homebrew/etc/php/8.4

# Sửa PHP-FPM config
echo -e "${BLUE}⚙️  Sửa PHP-FPM config...${NORMAL}"
php_fpm_conf="/opt/homebrew/etc/php/8.4/php-fpm.d/www.conf"

if [ -f "$php_fpm_conf" ]; then
    # Backup config cũ
    cp "$php_fpm_conf" "$php_fpm_conf.backup"
    
    # Sửa config
    sed -i '' "s/listen = 127.0.0.1:9000/listen = 127.0.0.1:9084/" "$php_fpm_conf"
    sed -i '' "s/;listen.owner = www/listen.owner = $(whoami)/" "$php_fpm_conf"
    sed -i '' "s/;listen.group = www/listen.group = admin/" "$php_fpm_conf"
    sed -i '' "s/;listen.mode = 0660/listen.mode = 0660/" "$php_fpm_conf"
    
    echo -e "${GREEN}✅ PHP-FPM config đã cập nhật!${NORMAL}"
fi

# Tạo launchd plist
echo -e "${BLUE}🚀 Tạo launchd service...${NORMAL}"
plist_file="/Users/$(whoami)/Library/LaunchAgents/homebrew.mxcl.php@8.4.plist"

cat > "$plist_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>homebrew.mxcl.php@8.4</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/sbin/php-fpm</string>
        <string>--fpm-config</string>
        <string>/opt/homebrew/etc/php/8.4/php-fpm.conf</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/opt/homebrew/var/log/php@8.4.log</string>
    <key>StandardOutPath</key>
    <string>/opt/homebrew/var/log/php@8.4.log</string>
</dict>
</plist>
EOF

# Load service
echo -e "${BLUE}🚀 Load PHP 8.4 service...${NORMAL}"
launchctl load -w "$plist_file"

# Kiểm tra service
echo -e "${BLUE}🔍 Kiểm tra PHP 8.4 service...${NORMAL}"
sleep 2

if lsof -i :9084 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PHP 8.4 đã chạy trên port 9084!${NORMAL}"
    
    # Test kết nối
    echo -e "${BLUE}🧪 Test kết nối...${NORMAL}"
    if curl -s -o /dev/null -w "%{http_code}" https://estiva-master.test | grep -q "200"; then
        echo -e "${GREEN}✅ Website hoạt động bình thường!${NORMAL}"
    else
        echo -e "${YELLOW}⚠️  Website chưa hoạt động, kiểm tra nginx...${NORMAL}"
    fi
else
    echo -e "${RED}❌ PHP 8.4 chưa chạy!${NORMAL}"
    echo -e "${BLUE}💡 Thử start manual: /opt/homebrew/sbin/php-fpm --fpm-config /opt/homebrew/etc/php/8.4/php-fpm.conf${NORMAL}"
fi

echo ""
echo -e "${GREEN}🎉 Hoàn thành fix PHP 8.4!${NORMAL}"
