# 🚀 Quick Reference - Valet & PHP

## ⚡ Lệnh nhanh

```fish
# Chuyển PHP
switch-php 7.4
switch-php 8.2

# Fix deprecated warnings
fix

# Setup project mới
sp7.4
sp8.2

# Hiển thị thông tin PHP
pi
```

## 🔧 Valet Commands

```fish
valet start          # Khởi động
valet stop           # Dừng
valet restart        # Khởi động lại
valet link           # Link project
valet secure         # Bật HTTPS
valet use php@7.4    # Chuyển PHP
```

## 🛠️ Troubleshooting

### Deprecated warnings
```fish
fix-laravel-deprecated
# hoặc
valet use php@7.4 --force
```

### Valet không hoạt động
```fish
valet restart
# hoặc
composer global remove laravel/valet
composer global require laravel/valet:^3.0
valet install
```

### PHP version không khớp
```fish
php -v              # Kiểm tra CLI
valet use           # Kiểm tra Valet
valet use php@7.4 --force  # Force version
```

## 📁 Projects

```
/Users/huong/Projects/web/
├── haili-baohanh/     # https://haili-baohanh.code
├── project1/          # https://project1.code
└── project2/          # https://project2.code
```

## 💡 Tips

- PHP 7.4 = ít deprecated warnings nhất
- Luôn dùng `--force` khi chuyển PHP
- Clear cache sau khi thay đổi: `php artisan cache:clear`
- Backup config: `./backup-valet-config.sh backup`

---
*Xem chi tiết: valet-php-notes.md*
