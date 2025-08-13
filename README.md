# 🚀 Nginx Multi-PHP Development Tools

Bộ công cụ để setup môi trường phát triển Nginx với nhiều phiên bản PHP cùng lúc, không cần Valet.

## 📁 Files còn lại

- **`install_nginx.sh`** - Cài đặt và cấu hình Nginx
- **`setup_nginx_multi_php.sh`** - Tool chính để tạo dự án mới
- **`setup_multi_php_fpm.sh`** - Quản lý PHP-FPM services
- **`fix_mitsu_project.sh`** - Fix các vấn đề CSP, font loading cho dự án
- **`fix_ssl_all_projects.sh`** - Fix SSL cho tất cả dự án với mkcert

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

### 4. Fix SSL cho tất cả dự án (khuyến nghị)
```bash
bash fix_ssl_all_projects.sh all
```

### 5. Fix vấn đề CSP/Font cho dự án cụ thể
```bash
bash fix_mitsu_project.sh <tên_dự_án>
```

## 🎯 Alias hữu ích trong Fish shell

```fish
# Nginx tools
nginx-setup      # Tạo dự án mới
php-fpm          # Quản lý PHP-FPM
nginx-install    # Cài đặt Nginx

# SSL & Fix tools
fix-ssl-all      # Fix SSL cho tất cả dự án
fix-ssl-status   # Kiểm tra trạng thái SSL
fix-project      # Fix vấn đề CSP/Font cho dự án

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
- **PHP 8.0** chạy trên port 9080
- **PHP 8.1** chạy trên port 9081
- **PHP 8.2** chạy trên port 9082
- **PHP 8.3** chạy trên port 9083
- Mỗi dự án có thể dùng PHP version khác nhau
- Nginx route request đến đúng PHP-FPM port
- Không cần switch PHP version, tất cả chạy song song
- **SSL certificates** được tạo bằng mkcert (tin tưởng 100%)

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
lsof -i :9080  # PHP 8.0
lsof -i :9081  # PHP 8.1
lsof -i :9082  # PHP 8.2
lsof -i :9083  # PHP 8.3
```

### Fix SSL cho tất cả dự án
```bash
bash fix_ssl_all_projects.sh all
```

### Kiểm tra trạng thái SSL
```bash
bash fix_ssl_all_projects.sh status
```

### Fix vấn đề CSP/Font cho dự án
```bash
bash fix_mitsu_project.sh <tên_dự_án>
```

### Restart Nginx
```bash
brew services restart nginx
```

---

🎉 **Chúc bạn sử dụng tool hiệu quả!**
