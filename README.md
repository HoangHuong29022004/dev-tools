# 🚀 Nginx Multi-PHP Development Tools

Bộ công cụ để setup môi trường phát triển Nginx với nhiều phiên bản PHP cùng lúc, không cần Valet.

## 📁 Files còn lại

- **`install_nginx.sh`** - Cài đặt và cấu hình Nginx
- **`setup_nginx_multi_php.sh`** - Tool chính để tạo dự án mới
- **`setup_multi_php_fpm.sh`** - Quản lý PHP-FPM services

## 🚀 Cách sử dụng

### 1. Cài đặt Nginx (nếu chưa có)
```bash
bash install_nginx.sh
```

### 2. Tạo dự án mới
```bash
bash setup_nginx_multi_php.sh
```

### 3. Quản lý PHP-FPM
```bash
bash setup_multi_php_fpm.sh
```

## 🎯 Alias hữu ích trong Fish shell

```fish
# Nginx tools
nginx-setup      # Tạo dự án mới
php-fpm          # Quản lý PHP-FPM
nginx-install    # Cài đặt Nginx

# PHP switching
switch-php 7.4   # Chuyển sang PHP 7.4
switch-php 8.2   # Chuyển sang PHP 8.2
php74            # Chuyển nhanh sang PHP 7.4
php82            # Chuyển nhanh sang PHP 8.2
phpv             # Hiển thị PHP version hiện tại

# PHP management
install-php 7.4  # Cài đặt PHP 7.4
install-php 8.2  # Cài đặt PHP 8.2
pi               # Hiển thị thông tin PHP

# Project navigation
haili            # Chuyển đến dự án haili-baohanh
mitsu            # Chuyển đến dự án mitsuheavy-ecommerce
```

## 🌐 Cách hoạt động

- **PHP 7.4** chạy trên port 9074
- **PHP 8.2** chạy trên port 9082
- Mỗi dự án có thể dùng PHP version khác nhau
- Nginx route request đến đúng PHP-FPM port
- Không cần switch PHP version, tất cả chạy song song

## 💡 Ví dụ sử dụng

```bash
# Tạo dự án Laravel 8.x với PHP 7.4
bash setup_nginx_multi_php.sh
# Chọn: Tạo dự án mới
# Domain: laravel-8.code
# PHP: 7.4

# Tạo dự án Laravel 10.x với PHP 8.2
bash setup_nginx_multi_php.sh
# Chọn: Tạo dự án mới
# Domain: laravel-10.code
# PHP: 8.2
```

Kết quả: Cả 2 dự án chạy song song, mỗi dự án dùng PHP version riêng!

## 🔧 Troubleshooting

### Kiểm tra services
```bash
brew services list
```

### Kiểm tra ports
```bash
lsof -i :9074  # PHP 7.4
lsof -i :9082  # PHP 8.2
```

### Restart Nginx
```bash
brew services restart nginx
```

---

🎉 **Chúc bạn sử dụng tool hiệu quả!**
