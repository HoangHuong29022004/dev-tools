#!/bin/bash

# Script đơn giản để chuyển đổi PHP version
# Cách sử dụng: bash switch_php.sh 7.4

PHP_VERSION=$1

if [ -z "$PHP_VERSION" ]; then
    echo "Cách sử dụng: bash switch_php.sh <version>"
    echo "Ví dụ: bash switch_php.sh 7.4"
    echo "Các version có sẵn: 7.4, 8.0, 8.1, 8.2, 8.3, 8.4"
    exit 1
fi

PHP_PATH="/opt/homebrew/opt/php@$PHP_VERSION/bin"

if [ ! -d "$PHP_PATH" ]; then
    echo "❌ PHP $PHP_VERSION không được cài đặt!"
    exit 1
fi

echo "🔄 Chuyển sang PHP $PHP_VERSION..."
export PATH="$PHP_PATH:$PATH"

echo "✅ Đã chuyển sang PHP $PHP_VERSION"
echo "Kiểm tra: php -v"
php -v
