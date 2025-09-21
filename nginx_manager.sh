#!/bin/bash

# Colors
GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
NORMAL="\033[0;39m"

echo -e "${BLUE}🔧 Nginx Manager - Quản lý Nginx Dễ Dàng${NORMAL}"
echo "============================================="
echo ""

# Function để kill nginx
kill_nginx() {
    echo -e "${YELLOW}💀 Đang kill nginx...${NORMAL}"
    sudo pkill -9 -f nginx 2>/dev/null || true
    sleep 2
    
    if pgrep -f nginx > /dev/null; then
        echo -e "${RED}❌ Vẫn còn nginx processes!${NORMAL}"
        sudo kill -9 $(pgrep -f nginx) 2>/dev/null || true
        sleep 2
    fi
    
    if pgrep -f nginx > /dev/null; then
        echo -e "${RED}❌ Không thể kill nginx!${NORMAL}"
        return 1
    else
        echo -e "${GREEN}✅ Đã kill hết nginx!${NORMAL}"
        return 0
    fi
}

# Function để start nginx
start_nginx() {
    echo -e "${BLUE}🚀 Đang start nginx...${NORMAL}"
    
    if nginx -t; then
        sudo nginx -c /opt/homebrew/etc/nginx/nginx.conf
        sleep 2
        
        if pgrep -f "nginx.*master" > /dev/null; then
            echo -e "${GREEN}✅ Nginx đã start!${NORMAL}"
            return 0
        else
            echo -e "${RED}❌ Nginx không start được!${NORMAL}"
            return 1
        fi
    else
        echo -e "${RED}❌ Nginx config có lỗi!${NORMAL}"
        return 1
    fi
}

# Function để restart nginx
restart_nginx() {
    echo -e "${BLUE}🔄 Restart nginx...${NORMAL}"
    kill_nginx && start_nginx
}

# Function để kiểm tra trạng thái
check_status() {
    echo -e "${BLUE}📊 Trạng thái nginx:${NORMAL}"
    echo ""
    
    if pgrep -f "nginx.*master" > /dev/null; then
        echo -e "${GREEN}✅ Nginx đang chạy${NORMAL}"
        echo ""
        echo -e "${BLUE}📋 Nginx processes:${NORMAL}"
        ps aux | grep nginx | grep -v grep
    else
        echo -e "${RED}❌ Nginx không chạy${NORMAL}"
    fi
    
    echo ""
    echo -e "${BLUE}📋 Sites enabled:${NORMAL}"
    ls -la /opt/homebrew/etc/nginx/sites-enabled/ 2>/dev/null || echo "Không có sites enabled"
}

# Function để xem logs
view_logs() {
    echo -e "${BLUE}📋 Nginx logs:${NORMAL}"
    echo ""
    echo -e "${YELLOW}Error logs (10 dòng cuối):${NORMAL}"
    tail -10 /opt/homebrew/var/log/nginx/error.log 2>/dev/null || echo "Không có error logs"
    echo ""
    echo -e "${YELLOW}Access logs (5 dòng cuối):${NORMAL}"
    tail -5 /opt/homebrew/var/log/nginx/access.log 2>/dev/null || echo "Không có access logs"
}

# Main menu
while true; do
    echo ""
    echo -e "${BLUE}Chọn hành động:${NORMAL}"
    echo "1) Kill nginx"
    echo "2) Start nginx"
    echo "3) Restart nginx"
    echo "4) Kiểm tra trạng thái"
    echo "5) Xem logs"
    echo "6) Test nginx config"
    echo "7) Thoát"
    echo ""
    
    read -p "Nhập lựa chọn (1-7): " choice
    
    case $choice in
        1)
            kill_nginx
            ;;
        2)
            start_nginx
            ;;
        3)
            restart_nginx
            ;;
        4)
            check_status
            ;;
        5)
            view_logs
            ;;
        6)
            echo -e "${BLUE}🔧 Test nginx config...${NORMAL}"
            if nginx -t; then
                echo -e "${GREEN}✅ Nginx config OK!${NORMAL}"
            else
                echo -e "${RED}❌ Nginx config có lỗi!${NORMAL}"
            fi
            ;;
        7)
            echo -e "${GREEN}👋 Tạm biệt!${NORMAL}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Lựa chọn không hợp lệ!${NORMAL}"
            ;;
    esac
done
