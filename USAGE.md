# 🚀 Dev Tools - Cách Dùng

## ⚡ Tool Chính

### 1. Tạo Project - `mkproject.py` (./mk)

```bash
cd ~/dev-tools

# Tạo với PHP 8.2 + .code domain (mặc định)
./mk project-name  # → project-name.code

# Tạo với PHP cụ thể + .test domain
./mk project-name 8.4  # PHP 8.4 → port 9084
./mk my-site 8.1       # PHP 8.1 → port 9081
./mk test 7.4          # PHP 7.4 → port 9074

# Tạo với .code domain (cho công ty)
./mk project-name 8.2 .code  # → project-name.code
./mk my-app 8.4 .code        # → my-app.code
./mk company-site 8.1 .code  # → company-site.code

# Tạo với .test domain (rõ ràng)
./mk project-name 8.2 .test  # → project-name.test
```

**Thời gian:** ~2-3 giây ⚡

**Port mapping:** Mỗi PHP version dùng port riêng (7.4→9074, 8.0→9080, 8.1→9081, 8.2→9082, 8.3→9083, 8.4→9084)

**Domain types:** 
- `.code` - Mặc định (công ty/team)
- `.test` - Cho development cá nhân

### 2. Quản Lý Projects - `manage.py` (./pm)

```bash
cd ~/dev-tools
./pm
```

**Menu:**
- 📋 Liệt kê tất cả projects (hiển thị domain type: 🔧 .code, 🧪 .test)
- 👁️  Xem chi tiết project (config, SSL, hosts, files, domain type)
- 🌐 Mở project trong browser
- 🗑️  Xóa project (xóa sạch: thư mục, nginx config, SSL, hosts)

### 3. Cài Đặt Môi Trường - `install.py` (./setup)

```bash
cd ~/dev-tools
./setup
```

**Menu:**
- 🌐 Nginx
- 🐘 PHP (chọn versions: 7.4, 8.0, 8.1, 8.2, 8.3, 8.4)
  - **Port mapping:** PHP 7.4→9074, 8.0→9080, 8.1→9081, 8.2→9082, 8.3→9083, 8.4→9084
  - Auto config từng version với port riêng
- 🎼 Composer
- 📗 Node.js (chọn version: 18, 20, 22)
- 🗄️  MySQL (chọn version: 5.7, 8.0, 8.4)
- 🐟 Fish Shell
- 🛠️  Essential Tools (git, wget, mkcert, imagemagick, redis, gh...)
- 🚀 Cài tất cả (auto setup cho Mac mới)

**Cài all một lần:**
```bash
./setup
# Chọn 8 → Confirm → Xong!
```

---

## 📝 Các Tool Khác

### 1. Create Project (bash) - Interactive

```bash
bash create_project.sh
```

Nhập tên → Chọn PHP → Xong!

---

### 2. Install PHP

```bash
bash install_php.sh
```

Menu cài đặt PHP 7.4, 8.0, 8.1, 8.2, 8.3, 8.4

---

### 3. Nginx Manager

```bash
bash nginx_manager.sh
```

Menu: Kill, Start, Restart, Check status, View logs

---

### 4. Switch PHP CLI

```bash
bash switch_php.sh 8.2
```

Chuyển PHP CLI sang version khác

---

## 🐛 Fix Lỗi 500 (POST/Upload)

Nếu gặp lỗi 500 khi edit/upload trong admin:

```bash
sudo chmod -R 777 /opt/homebrew/var/run/nginx
sudo nginx -s reload
```

**Nguyên nhân:** Nginx không có quyền ghi `client_body_temp`

**Tool đã fix sẵn:** `mkproject.py` tự động fix lỗi này!

---

## 📋 PHP Versions & Ports

| PHP Version | Port |
|-------------|------|
| 7.4 | 9074 |
| 8.0 | 9080 |
| 8.1 | 9081 |
| 8.2 | 9082 |
| 8.3 | 9083 |
| 8.4 | 9084 |

---

## 📁 Cấu trúc

```
/opt/homebrew/
├── var/
│   ├── www/              # Projects
│   │   └── project-name/
│   │       └── public/   # Web root
│   ├── log/nginx/        # Nginx logs
│   └── run/nginx/        # Temp files (fix 500 error)
└── etc/nginx/
    ├── nginx.conf        # Config chính
    ├── sites-available/  # Tất cả configs
    ├── sites-enabled/    # Configs đang active
    └── ssl/              # SSL certificates
```

---

## 💡 Tips

### Xem log lỗi

```bash
tail -20 /opt/homebrew/var/log/nginx/project-name.test-error.log
```

### Check PHP chạy chưa

```bash
lsof -i :9082  # PHP 8.2
lsof -i :9084  # PHP 8.4
```

### Restart PHP

```bash
brew services restart php@8.2
```

### Reload nginx

```bash
sudo nginx -s reload
```

### List tất cả projects

```bash
ls /opt/homebrew/var/www/
```

### Xóa project

```bash
# Xóa thư mục
rm -rf /opt/homebrew/var/www/project-name

# Xóa nginx config
rm /opt/homebrew/etc/nginx/sites-available/project-name.test
rm /opt/homebrew/etc/nginx/sites-enabled/project-name.test

# Xóa khỏi hosts
sudo nano /etc/hosts  # Xóa dòng có project-name.test

# Reload nginx
sudo nginx -s reload
```

---

## 🎯 Examples

### Tạo project Laravel cá nhân (.test)

```bash
./mk laravel-app 8.2
cd /opt/homebrew/var/www/laravel-app
composer create-project laravel/laravel .
chmod -R 775 storage bootstrap/cache
# Truy cập: https://laravel-app.test
```

### Tạo project Laravel công ty (.code)

```bash
./mk company-laravel 8.2 .code
cd /opt/homebrew/var/www/company-laravel
composer create-project laravel/laravel .
chmod -R 775 storage bootstrap/cache
# Truy cập: https://company-laravel.code
```

### Tạo project WordPress

```bash
./mk wordpress 8.1
cd /opt/homebrew/var/www/wordpress
# Download WordPress và giải nén vào public/
# Truy cập: https://wordpress.test
```

### Clone project từ Git

```bash
cd /opt/homebrew/var/www
git clone <repo-url> project-name
cd ~/dev-tools
./mk project-name 8.2 .code  # Cho dự án công ty
# hoặc
./mk project-name 8.2 .test  # Cho dự án cá nhân
```

---

## 🚨 Troubleshooting

### Lỗi: "Permission denied"

```bash
sudo chmod -R 777 /opt/homebrew/var/run/nginx
```

### Lỗi: "Address already in use"

```bash
sudo pkill -9 -f nginx
sudo nginx -c /opt/homebrew/etc/nginx/nginx.conf
```

### Lỗi: SSL certificate invalid

```bash
cd /opt/homebrew/etc/nginx/ssl

# Cho .test domain
rm project-name.test.*
mkcert project-name.test localhost 127.0.0.1
cp project-name.test+2.pem project-name.test.crt
cp project-name.test+2-key.pem project-name.test.key

# Cho .code domain
rm project-name.code.*
mkcert project-name.code localhost 127.0.0.1
cp project-name.code+2.pem project-name.code.crt
cp project-name.code+2-key.pem project-name.code.key

sudo nginx -s reload
```

---

**Made with ❤️ for fast development!**

