#!/bin/bash

# Colors
GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
NORMAL="\033[0;39m"

echo -e "${BLUE}🔧 PHP Permissions Fixer${NORMAL}"
echo "========================="
echo ""

echo -e "${BLUE}🔧 Sửa quyền cho tất cả PHP...${NORMAL}"

# Tạo thư mục PHP nếu chưa có
sudo mkdir -p /opt/homebrew/etc/php
sudo chown -R $(whoami):admin /opt/homebrew/etc/php
sudo chmod -R 755 /opt/homebrew/etc/php

# Sửa quyền cho từng PHP version
for version in 7.4 8.0 8.1 8.2 8.3 8.4; do
    if [ -d "/opt/homebrew/etc/php/$version" ]; then
        echo -e "${BLUE}📁 Sửa quyền PHP $version...${NORMAL}"
        sudo chown -R $(whoami):admin /opt/homebrew/etc/php/$version
        sudo chmod -R 755 /opt/homebrew/etc/php/$version
        echo -e "${GREEN}✅ Đã sửa quyền PHP $version${NORMAL}"
    else
        echo -e "${YELLOW}⚠️  PHP $version chưa cài đặt${NORMAL}"
    fi
done

# Sửa quyền cho thư mục log
sudo mkdir -p /opt/homebrew/var/log
sudo chown -R $(whoami):admin /opt/homebrew/var/log
sudo chmod -R 755 /opt/homebrew/var/log

echo ""
echo -e "${GREEN}✅ Hoàn thành sửa quyền PHP!${NORMAL}"
echo -e "${BLUE}💡 Bây giờ có thể cài đặt PHP 8.1: ./install_php.sh${NORMAL}"
