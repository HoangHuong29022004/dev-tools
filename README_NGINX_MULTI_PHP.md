# 🚀 Nginx Multi-PHP Setup Tool

Tool này cho phép bạn setup Nginx với nhiều phiên bản PHP cùng lúc, mỗi PHP chạy PHP-FPM riêng trên port khác nhau. Không cần Valet, không cần switch PHP version!

## ✨ Tính năng chính

- **Multi-PHP Support**: Chạy nhiều phiên bản PHP (7.4, 8.0, 8.1, 8.2, 8.3) cùng lúc
- **Port Isolation**: Mỗi PHP-FPM chạy trên port riêng (9074, 9080, 9081, 9082, 9083)
- **Independent Projects**: Mỗi dự án có thể dùng PHP version khác nhau
- **SSL Support**: Tự động tạo SSL certificate cho mỗi domain
- **Easy Management**: Giao diện menu dễ sử dụng

## 🏗️ Kiến trúc hệ thống

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx (80/443)│    │   PHP-FPM 7.4   │    │   PHP-FPM 8.2   │
│                 │    │   Port: 9074     │    │   Port: 9082     │
│                 │    │                 │    │                 │
│  haili-baohanh  │───▶│  Laravel 8.x    │    │  Laravel 10.x   │
│  .code (PHP 8.2)│    │                 │    │                 │
│                 │    └─────────────────┘    └─────────────────┘
│  laravel-8.2    │
│  .code (PHP 7.4)│
└─────────────────┘
```

## 📋 Yêu cầu hệ thống

- macOS với Homebrew
- Nginx đã cài đặt (`bash install_nginx.sh`)
- Ít nhất một phiên bản PHP (`brew install php@7.4`)

## 🚀 Cài đặt và sử dụng

### 1. Cài đặt Nginx (nếu chưa có)
```bash
bash install_nginx.sh
```

### 2. Cài đặt PHP (nếu chưa có)
```bash
brew install php@7.4
brew install php@8.2
```

### 3. Chạy tool setup
```bash
bash setup_nginx_multi_php.sh
```

### 4. Quản lý PHP-FPM services
```bash
bash manage_php_fpm.sh
```

## 🎯 Cách hoạt động

### Port Mapping
- **PHP 7.4** → Port 9074
- **PHP 8.0** → Port 9080  
- **PHP 8.1** → Port 9081
- **PHP 8.2** → Port 9082
- **PHP 8.3** → Port 9083

### Workflow
1. **Tạo dự án**: Chọn domain, PHP version
2. **Setup PHP-FPM**: Tự động cấu hình PHP-FPM cho version được chọn
3. **Tạo Nginx config**: Virtual host trỏ đến đúng PHP-FPM port
4. **SSL Certificate**: Tự động tạo SSL cho domain
5. **Hosts file**: Cập nhật `/etc/hosts` để resolve domain

## 📁 Cấu trúc thư mục

```
/opt/homebrew/
├── etc/
│   ├── nginx/
│   │   ├── sites-available/     # Cấu hình Nginx
│   │   ├── sites-enabled/       # Sites đang hoạt động
│   │   └── ssl/                 # SSL certificates
│   └── php/
│       ├── 7.4/                 # PHP 7.4 config
│       │   ├── php-fpm.conf
│       │   └── php-fpm.d/
│       └── 8.2/                 # PHP 8.2 config
│           ├── php-fpm.conf
│           └── php-fpm.d/
├── var/
│   ├── www/                     # Thư mục dự án
│   │   ├── haili-baohanh.code/
│   │   └── laravel-8.2.code/
│   ├── log/                     # Log files
│   └── run/                     # PID files
```

## 🛠️ Sử dụng tool

### Setup dự án mới
1. Chạy `bash setup_nginx_multi_php.sh`
2. Chọn "1. Tạo dự án mới"
3. Nhập domain (vd: `project.test`)
4. Chọn PHP version
5. Xác nhận tạo dự án

### Quản lý PHP-FPM
1. Chạy `bash manage_php_fpm.sh`
2. Chọn action cần thiết:
   - Hiển thị trạng thái
   - Khởi động/dừng/restart services
   - Xem log và cấu hình
   - Test kết nối

## 🌐 Ví dụ sử dụng

### Tạo 2 dự án với PHP khác nhau

```bash
# Dự án 1: Laravel 8.x với PHP 7.4
bash setup_nginx_multi_php.sh
# Chọn: Tạo dự án mới
# Domain: laravel-8.test
# PHP: 7.4

# Dự án 2: Laravel 10.x với PHP 8.2  
bash setup_nginx_multi_php.sh
# Chọn: Tạo dự án mới
# Domain: laravel-10.test
# PHP: 8.2
```

### Kết quả
- `https://laravel-8.test` → PHP 7.4 (Port 9074)
- `https://laravel-10.test` → PHP 8.2 (Port 9082)
- Cả 2 chạy song song, không ảnh hưởng nhau

## 🔧 Troubleshooting

### PHP-FPM không khởi động
```bash
# Kiểm tra trạng thái
bash manage_php_fpm.sh
# Chọn: Hiển thị trạng thái

# Khởi động lại service
bash manage_php_fpm.sh
# Chọn: Khởi động lại PHP-FPM cụ thể
```

### Nginx config lỗi
```bash
# Kiểm tra cấu hình
nginx -t

# Restart Nginx
brew services restart nginx
```

### SSL certificate lỗi
```bash
# Xóa và tạo lại certificate
sudo rm /opt/homebrew/etc/nginx/ssl/domain.key
sudo rm /opt/homebrew/etc/nginx/ssl/domain.crt
# Chạy lại setup tool
```

## 📊 Monitoring

### Kiểm tra services
```bash
# Xem tất cả services
brew services list

# Xem PHP-FPM processes
ps aux | grep php-fpm

# Xem ports đang lắng nghe
lsof -i :9074  # PHP 7.4
lsof -i :9082  # PHP 8.2
```

### Xem logs
```bash
# Nginx logs
tail -f /opt/homebrew/var/log/nginx/error.log

# PHP-FPM logs
tail -f /opt/homebrew/var/log/php-fpm-7.4.log
tail -f /opt/homebrew/var/log/php-fpm-8.2.log
```

## 💡 Tips

1. **Performance**: Mỗi PHP-FPM chạy độc lập, không ảnh hưởng nhau
2. **Memory**: Mỗi PHP version có thể có cấu hình memory khác nhau
3. **Updates**: Cập nhật PHP version không ảnh hưởng dự án khác
4. **Backup**: Backup cấu hình trước khi thay đổi lớn

## 🆘 Lệnh khẩn cấp

```bash
# Dừng tất cả services
bash manage_php_fpm.sh
# Chọn: Dừng tất cả PHP-FPM services

# Restart toàn bộ hệ thống
brew services restart nginx
bash manage_php_fpm.sh
# Chọn: Khởi động lại tất cả PHP-FPM services
```

## 🔄 Migration từ Valet

1. **Backup cấu hình Valet**
   ```bash
   ./backup-valet-config.sh backup
   ```

2. **Setup dự án với tool mới**
   ```bash
   bash setup_nginx_multi_php.sh
   ```

3. **Copy code từ Valet project**
   ```bash
   cp -r ~/Projects/web/old-project/* /opt/homebrew/var/www/new-domain/
   ```

4. **Test và xóa Valet project**

## 📝 Lưu ý quan trọng

- **Không chạy script với sudo**
- **Backup trước khi thay đổi lớn**
- **Kiểm tra cấu hình Nginx sau mỗi thay đổi**
- **Mỗi domain phải unique**
- **SSL certificates tự động tạo cho localhost**

---

🎉 **Chúc bạn sử dụng tool hiệu quả!** 

Nếu có vấn đề, hãy kiểm tra logs và sử dụng tool quản lý PHP-FPM để debug.
