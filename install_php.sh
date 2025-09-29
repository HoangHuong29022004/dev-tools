#!/bin/bash

# Colors
GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
NORMAL="\033[0;39m"

echo -e "${BLUE}🐘 PHP Installer - Cài đặt PHP Multi-Version${NORMAL}"
echo "============================================="
echo ""

# Function để cài đặt PHP version
install_php() {
    local version=$1
    local port=$2
    
    echo -e "${BLUE}📦 Cài đặt PHP $version...${NORMAL}"
    
    # Tạo thư mục PHP trước
    echo -e "${BLUE}📁 Tạo thư mục PHP...${NORMAL}"
    sudo mkdir -p /opt/homebrew/etc/php/$version
    sudo chown -R $(whoami):admin /opt/homebrew/etc/php
    sudo chmod -R 755 /opt/homebrew/etc/php
    
    # Cài đặt PHP qua brew
    if brew install php@$version; then
        echo -e "${GREEN}✅ PHP $version đã cài đặt!${NORMAL}"
        
        # Tạo symlink
        echo -e "${BLUE}🔗 Tạo symlink...${NORMAL}"
        brew link php@$version --force --overwrite
        
        # Copy config từ bottle nếu chưa có
        echo -e "${BLUE}📋 Copy config từ bottle...${NORMAL}"
        if [ ! -f "/opt/homebrew/etc/php/$version/php-fpm.conf" ]; then
            # Tìm đường dẫn bottle
            bottle_path=$(brew --prefix php@$version)
            if [ -d "$bottle_path/.bottle/etc/php/$version" ]; then
                sudo cp -r "$bottle_path/.bottle/etc/php/$version"/* /opt/homebrew/etc/php/$version/
                sudo chown -R $(whoami):admin /opt/homebrew/etc/php/$version
                sudo chmod -R 755 /opt/homebrew/etc/php/$version
                echo -e "${GREEN}✅ Đã copy config từ bottle!${NORMAL}"
            fi
        fi
        
        # Tạo PHP-FPM config
        echo -e "${BLUE}⚙️  Tạo PHP-FPM config...${NORMAL}"
        php_fpm_conf="/opt/homebrew/etc/php/$version/php-fpm.d/www.conf"
        
        if [ -f "$php_fpm_conf" ]; then
            # Backup config cũ
            cp "$php_fpm_conf" "$php_fpm_conf.backup"
            
            # Sửa config
            sed -i '' "s/listen = 127.0.0.1:9000/listen = 127.0.0.1:$port/" "$php_fpm_conf"
            sed -i '' "s/;listen.owner = www/listen.owner = $(whoami)/" "$php_fpm_conf"
            sed -i '' "s/;listen.group = www/listen.group = admin/" "$php_fpm_conf"
            sed -i '' "s/;listen.mode = 0660/listen.mode = 0660/" "$php_fpm_conf"
            
            echo -e "${GREEN}✅ PHP-FPM config đã cập nhật!${NORMAL}"
        else
            echo -e "${YELLOW}⚠️  Không tìm thấy PHP-FPM config!${NORMAL}"
        fi
        
        # Tạo launchd plist
        echo -e "${BLUE}🚀 Tạo launchd service...${NORMAL}"
        plist_file="/Users/$(whoami)/Library/LaunchAgents/homebrew.mxcl.php@$version.plist"
        
        # Xác định đường dẫn php-fpm đúng
        php_fpm_path="/opt/homebrew/sbin/php-fpm"
        if [ ! -f "$php_fpm_path" ]; then
            php_fpm_path="/opt/homebrew/bin/php-fpm"
        fi
        
        cat > "$plist_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>homebrew.mxcl.php@$version</string>
    <key>ProgramArguments</key>
    <array>
        <string>$php_fpm_path</string>
        <string>--fpm-config</string>
        <string>/opt/homebrew/etc/php/$version/php-fpm.conf</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/opt/homebrew/var/log/php@$version.log</string>
    <key>StandardOutPath</key>
    <string>/opt/homebrew/var/log/php@$version.log</string>
</dict>
</plist>
EOF
        
        # Load service
        launchctl load -w "$plist_file"
        
        # Sửa quyền sau khi cài đặt
        echo -e "${BLUE}🔧 Sửa quyền PHP...${NORMAL}"
        sudo chown -R $(whoami):admin /opt/homebrew/etc/php/$version
        sudo chmod -R 755 /opt/homebrew/etc/php/$version
        
        # Kiểm tra service đã chạy chưa
        sleep 2
        if lsof -i :$port > /dev/null 2>&1; then
            echo -e "${GREEN}✅ PHP $version service đã start trên port $port!${NORMAL}"
        else
            echo -e "${YELLOW}⚠️  PHP $version service chưa start, thử start manual...${NORMAL}"
            $php_fpm_path --fpm-config /opt/homebrew/etc/php/$version/php-fpm.conf &
            sleep 2
            if lsof -i :$port > /dev/null 2>&1; then
                echo -e "${GREEN}✅ PHP $version service đã start!${NORMAL}"
            else
                echo -e "${RED}❌ PHP $version service không start được!${NORMAL}"
            fi
        fi
        
        return 0
    else
        echo -e "${RED}❌ Không thể cài đặt PHP $version!${NORMAL}"
        return 1
    fi
}

# Function để kiểm tra PHP đã cài
check_php() {
    local version=$1
    if brew list php@$version &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function để start PHP service
start_php() {
    local version=$1
    local port=$2
    echo -e "${BLUE}🚀 Start PHP $version service...${NORMAL}"
    
    plist_file="/Users/$(whoami)/Library/LaunchAgents/homebrew.mxcl.php@$version.plist"
    if [ -f "$plist_file" ]; then
        launchctl load -w "$plist_file"
        sleep 2
        if lsof -i :$port > /dev/null 2>&1; then
            echo -e "${GREEN}✅ PHP $version service đã start!${NORMAL}"
        else
            echo -e "${YELLOW}⚠️  Service file có nhưng chưa chạy, thử start manual...${NORMAL}"
            # Xác định đường dẫn php-fpm đúng
            php_fpm_path="/opt/homebrew/sbin/php-fpm"
            if [ ! -f "$php_fpm_path" ]; then
                php_fpm_path="/opt/homebrew/bin/php-fpm"
            fi
            $php_fpm_path --fpm-config /opt/homebrew/etc/php/$version/php-fpm.conf &
            sleep 2
            if lsof -i :$port > /dev/null 2>&1; then
                echo -e "${GREEN}✅ PHP $version service đã start!${NORMAL}"
            else
                echo -e "${RED}❌ PHP $version service không start được!${NORMAL}"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  Không tìm thấy service file, tạo mới...${NORMAL}"
        # Tạo lại service file
        install_php "$version" "$port"
    fi
}

# Function để fix quyền cho tất cả PHP
fix_php_permissions() {
    echo -e "${BLUE}🔧 Sửa quyền cho tất cả PHP...${NORMAL}"
    
    sudo mkdir -p /opt/homebrew/etc/php
    sudo chown -R $(whoami):admin /opt/homebrew/etc/php
    sudo chmod -R 755 /opt/homebrew/etc/php
    
    for version in 7.4 8.0 8.1 8.2 8.3 8.4; do
        if [ -d "/opt/homebrew/etc/php/$version" ]; then
            sudo chown -R $(whoami):admin /opt/homebrew/etc/php/$version
            sudo chmod -R 755 /opt/homebrew/etc/php/$version
            echo -e "${GREEN}✅ Đã sửa quyền PHP $version${NORMAL}"
        fi
    done
    
    echo -e "${GREEN}✅ Hoàn thành sửa quyền!${NORMAL}"
}

# Main menu
while true; do
    echo ""
    echo -e "${BLUE}Chọn hành động:${NORMAL}"
    echo "1) Cài đặt PHP 7.4"
    echo "2) Cài đặt PHP 8.0"
    echo "3) Cài đặt PHP 8.1"
    echo "4) Cài đặt PHP 8.2"
    echo "5) Cài đặt PHP 8.3"
    echo "6) Cài đặt PHP 8.4"
    echo "7) Kiểm tra PHP đã cài"
    echo "8) Start tất cả PHP services"
    echo "9) Fix quyền PHP"
    echo "10) Thoát"
    echo ""
    
    read -p "Nhập lựa chọn (1-10): " choice
    
    case $choice in
        1)
            if check_php "7.4"; then
                echo -e "${YELLOW}⚠️  PHP 7.4 đã cài đặt!${NORMAL}"
                start_php "7.4" "9074"
            else
                install_php "7.4" "9074"
            fi
            ;;
        2)
            if check_php "8.0"; then
                echo -e "${YELLOW}⚠️  PHP 8.0 đã cài đặt!${NORMAL}"
                start_php "8.0" "9080"
            else
                install_php "8.0" "9080"
            fi
            ;;
        3)
            if check_php "8.1"; then
                echo -e "${YELLOW}⚠️  PHP 8.1 đã cài đặt!${NORMAL}"
                start_php "8.1" "9081"
            else
                install_php "8.1" "9081"
            fi
            ;;
        4)
            if check_php "8.2"; then
                echo -e "${YELLOW}⚠️  PHP 8.2 đã cài đặt!${NORMAL}"
                start_php "8.2" "9082"
            else
                install_php "8.2" "9082"
            fi
            ;;
        5)
            if check_php "8.3"; then
                echo -e "${YELLOW}⚠️  PHP 8.3 đã cài đặt!${NORMAL}"
                start_php "8.3" "9083"
            else
                install_php "8.3" "9083"
            fi
            ;;
        6)
            if check_php "8.4"; then
                echo -e "${YELLOW}⚠️  PHP 8.4 đã cài đặt!${NORMAL}"
                start_php "8.4" "9084"
            else
                install_php "8.4" "9084"
            fi
            ;;
        7)
            echo -e "${BLUE}📊 PHP đã cài đặt:${NORMAL}"
            for version in 7.4 8.0 8.1 8.2 8.3 8.4; do
                if check_php "$version"; then
                    echo -e "${GREEN}✅ PHP $version${NORMAL}"
                else
                    echo -e "${RED}❌ PHP $version${NORMAL}"
                fi
            done
            ;;
        8)
            echo -e "${BLUE}🚀 Start tất cả PHP services...${NORMAL}"
            for version in 7.4 8.0 8.1 8.2 8.3 8.4; do
                if check_php "$version"; then
                    case $version in
                        7.4) start_php "$version" "9074" ;;
                        8.0) start_php "$version" "9080" ;;
                        8.1) start_php "$version" "9081" ;;
                        8.2) start_php "$version" "9082" ;;
                        8.3) start_php "$version" "9083" ;;
                        8.4) start_php "$version" "9084" ;;
                    esac
                fi
            done
            ;;
        9)
            fix_php_permissions
            ;;
        10)
            echo -e "${GREEN}👋 Tạm biệt!${NORMAL}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Lựa chọn không hợp lệ!${NORMAL}"
            ;;
    esac
done
