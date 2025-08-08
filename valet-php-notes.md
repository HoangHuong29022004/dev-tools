# 📝 Hướng dẫn sử dụng Valet và chuyển PHP

## 🚀 Các Functions có sẵn trong Fish shell

### 1. Chuyển PHP version
```fish
switch-php 7.4
switch-php 8.0
switch-php 8.1
switch-php 8.2
```

### 2. Cài đặt PHP mới
```fish
install-php 7.4
install-php 8.2
```

### 3. Fix deprecated warnings cho Laravel
```fish
fix-laravel-deprecated
# hoặc
fix
```

### 4. Setup project mới
```fish
setup-project 7.4
setup-project 8.2
```

### 5. Hiển thị thông tin PHP
```fish
php-info
# hoặc
pi
```

## 🔧 Các Alias tiện lợi

```fish
pi          # Hiển thị thông tin PHP
fix         # Fix deprecated warnings
sp7.4       # Setup project với PHP 7.4
sp8.0       # Setup project với PHP 8.0
sp8.1       # Setup project với PHP 8.1
sp8.2       # Setup project với PHP 8.2
sp8.3       # Setup project với PHP 8.3
```

## 🌐 Valet Commands cơ bản

```fish
valet start          # Khởi động Valet
valet stop           # Dừng Valet
valet restart        # Khởi động lại Valet
valet link           # Link thư mục hiện tại
valet unlink         # Unlink thư mục hiện tại
valet secure         # Bật HTTPS cho site
valet share          # Chia sẻ site qua ngrok
valet use php@7.4    # Chuyển Valet sang PHP 7.4
valet use php@8.2    # Chuyển Valet sang PHP 8.2
```

## 🛠️ Troubleshooting

### 1. Deprecated warnings xuất hiện
```fish
# Cách 1: Fix deprecated warnings
fix-laravel-deprecated

# Cách 2: Chuyển về PHP 7.4 (ít deprecated nhất)
switch-php 7.4

# Cách 3: Force Valet dùng PHP version
valet use php@7.4 --force
```

### 2. Valet không hoạt động
```fish
# Restart Valet
valet restart

# Hoặc cài đặt lại Valet
composer global remove laravel/valet
composer global require laravel/valet:^3.0
valet install
```

### 3. PHP version không khớp
```fish
# Kiểm tra PHP CLI
php -v

# Kiểm tra PHP của Valet
valet use

# Force Valet dùng PHP version
valet use php@7.4 --force
```

## 📁 Cấu trúc thư mục

```
/Users/huong/Projects/web/
├── project1/          # https://project1.code
├── project2/          # https://project2.code
└── haili-baohanh/     # https://haili-baohanh.code
```

## ⚙️ Cấu hình PHP

### File cấu hình PHP
- PHP 7.4: `/opt/homebrew/etc/php/7.4/php.ini`
- PHP 8.2: `/opt/homebrew/etc/php/8.2/php.ini`

### Tắt deprecated warnings
```bash
# Backup file cấu hình
cp /opt/homebrew/etc/php/7.4/php.ini /opt/homebrew/etc/php/7.4/php.ini.backup

# Tắt deprecated warnings
sed -i '' 's/error_reporting = .*/error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT/' /opt/homebrew/etc/php/7.4/php.ini
sed -i '' 's/display_errors = .*/display_errors = Off/' /opt/homebrew/etc/php/7.4/php.ini

# Restart PHP service
brew services restart php@7.4
```

## 🔄 Workflow thường dùng

### 1. Setup project mới
```fish
cd /Users/huong/Projects/web/new-project
setup-project 7.4
```

### 2. Chuyển PHP cho project cũ
```fish
cd /Users/huong/Projects/web/old-project
switch-php 7.4
fix-laravel-deprecated
```

### 3. Fix deprecated warnings
```fish
cd /Users/huong/Projects/web/project-with-errors
fix-laravel-deprecated
```

## 📋 Checklist khi gặp vấn đề

- [ ] Kiểm tra PHP CLI: `php -v`
- [ ] Kiểm tra Valet PHP: `valet use`
- [ ] Restart Valet: `valet restart`
- [ ] Clear Laravel cache: `php artisan cache:clear`
- [ ] Force Valet dùng PHP: `valet use php@7.4 --force`
- [ ] Fix deprecated warnings: `fix-laravel-deprecated`

## 💡 Tips

1. **PHP 7.4** là phiên bản ổn định nhất cho Laravel, ít deprecated warnings
2. **PHP 8.x** có thể gây deprecated warnings với Laravel cũ
3. Luôn dùng `--force` khi chuyển PHP version với Valet
4. Clear cache sau khi thay đổi cấu hình
5. Backup file cấu hình trước khi sửa

## 🆘 Lệnh khẩn cấp

```fish
# Reset hoàn toàn Valet
composer global remove laravel/valet
rm -rf ~/.config/valet
composer global require laravel/valet:^3.0
valet install

# Reset PHP về 7.4
switch-php 7.4
valet use php@7.4 --force
valet restart
```

---
*Cập nhật lần cuối: $(date)*
