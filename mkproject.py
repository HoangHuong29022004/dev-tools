#!/usr/bin/env python3
"""
Quick Project Maker - Tạo project Nginx + PHP cực nhanh
Usage: python3 mkproject.py project-name [php-version]
Example: python3 mkproject.py myproject 8.2
"""

import os
import sys
import subprocess
from pathlib import Path

# Config
PHP_PORTS = {"7.4": 9074, "8.0": 9080, "8.1": 9081, "8.2": 9082, "8.3": 9083, "8.4": 9084}
WWW = Path("/opt/homebrew/var/www")
NGINX_CONF = Path("/opt/homebrew/etc/nginx/sites-available")
NGINX_ENABLED = Path("/opt/homebrew/etc/nginx/sites-enabled")
SSL_DIR = Path("/opt/homebrew/etc/nginx/ssl")
HOSTS = Path("/etc/hosts")

def run(cmd, shell=False):
    """Chạy lệnh"""
    if isinstance(cmd, str) and not shell:
        cmd = cmd.split()
    subprocess.run(cmd, shell=shell, check=False, capture_output=True)

def setup_dirs():
    """Setup directories một lần - NHANH"""
    print("⚙️  Setup...", end=" ", flush=True)
    # Tạo thư mục không cần sudo (nhanh hơn)
    for d in [
        Path("/opt/homebrew/var/run/nginx/client_body_temp"),
        Path("/opt/homebrew/var/run/nginx/proxy_temp"),
        Path("/opt/homebrew/var/run/nginx/fastcgi_temp"),
        Path("/opt/homebrew/var/log/nginx"),
        NGINX_CONF, NGINX_ENABLED, SSL_DIR, WWW
    ]:
        d.mkdir(parents=True, exist_ok=True)
    
    # Chỉ sudo 1 lần cho chmod nginx temp
    run("sudo chmod -R 777 /opt/homebrew/var/run/nginx 2>/dev/null", shell=True)
    
    # Kill nginx nhanh
    run("sudo pkill -9 -f nginx 2>/dev/null", shell=True)
    print("✅")

def clean_old_project(name, domain):
    """Xóa config và SSL cũ (giữ nguyên code)"""
    cleaned = False
    
    # Xóa nginx config cũ
    conf_file = NGINX_CONF / domain
    if conf_file.exists():
        conf_file.unlink()
        cleaned = True
    
    enabled_file = NGINX_ENABLED / domain
    if enabled_file.exists() or enabled_file.is_symlink():
        enabled_file.unlink()
        cleaned = True
    
    # Xóa SSL cũ
    for cert in SSL_DIR.glob(f"{domain}*"):
        cert.unlink()
        cleaned = True
    
    # Xóa khỏi hosts
    hosts_content = HOSTS.read_text()
    if domain in hosts_content:
        new_hosts = "\n".join([
            line for line in hosts_content.split("\n")
            if domain not in line
        ])
        run(f'sudo bash -c \'echo "{new_hosts}" > /etc/hosts\'', shell=True)
        cleaned = True
    
    if cleaned:
        print("   🧹 Đã xóa config cũ")

def create_project(name, php_ver="8.2"):
    """Tạo project"""
    name = name.lower().replace("_", "-")
    domain = f"{name}.test"
    php_port = PHP_PORTS.get(php_ver, 9082)
    
    # Check project đã tồn tại
    project_dir = WWW / name
    exists = project_dir.exists()
    
    if exists:
        print(f"\n🔄 Update: {domain} (PHP {php_ver})")
        clean_old_project(name, domain)
    else:
        print(f"\n🚀 Tạo: {domain} (PHP {php_ver})")
    
    # Setup
    setup_dirs()
    
    # Tạo project dir
    project_dir = WWW / name / "public"
    project_dir.mkdir(parents=True, exist_ok=True)
    
    # Index.php - chỉ tạo nếu chưa có (không ghi đè Laravel/WordPress)
    index_file = project_dir / "index.php"
    if not index_file.exists() or index_file.stat().st_size < 1000:
        (project_dir / "index.php").write_text(f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>{domain}</title>
    <style>
        body {{ 
            font-family: system-ui; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh; display: flex; align-items: center; justify-content: center;
            color: white; margin: 0;
        }}
        .box {{ 
            background: rgba(255,255,255,0.1); backdrop-filter: blur(10px);
            border-radius: 20px; padding: 40px; text-align: center;
            box-shadow: 0 8px 32px rgba(0,0,0,0.3);
        }}
    </style>
</head>
<body>
    <div class="box">
        <h1>🎉 {domain}</h1>
        <p>PHP <?php echo PHP_VERSION; ?></p>
        <p><?php echo date('Y-m-d H:i:s'); ?></p>
    </div>
</body>
</html>
""")
    
    # SSL - luôn tạo mới
    print("🔒 SSL...", end=" ", flush=True)
    os.chdir(SSL_DIR)
    # Xóa cert cũ nếu có
    for cert in SSL_DIR.glob(f"{domain}*"):
        cert.unlink()
    run(f"mkcert {domain} localhost 127.0.0.1 >/dev/null 2>&1", shell=True)
    (SSL_DIR / f"{domain}+2.pem").rename(SSL_DIR / f"{domain}.crt")
    (SSL_DIR / f"{domain}+2-key.pem").rename(SSL_DIR / f"{domain}.key")
    print("✅")
    
    # Nginx config
    print("⚙️  Nginx...", end=" ", flush=True)
    (NGINX_CONF / domain).write_text(f"""server {{
    listen 80;
    server_name {domain};
    return 301 https://$server_name$request_uri;
}}

server {{
    listen 443 ssl http2;
    server_name {domain};
    root {WWW}/{name}/public;
    
    ssl_certificate {SSL_DIR}/{domain}.crt;
    ssl_certificate_key {SSL_DIR}/{domain}.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    
    index index.php index.html;
    client_max_body_size 100M;
    
    location / {{ try_files $uri $uri/ /index.php?$query_string; }}
    location = /favicon.ico {{ access_log off; log_not_found off; }}
    location = /robots.txt {{ access_log off; log_not_found off; }}
    
    location ~ \\.php$ {{
        fastcgi_pass 127.0.0.1:{php_port};
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }}
    
    location ~ /\\. {{ deny all; }}
}}
""")
    
    (NGINX_ENABLED / domain).unlink(missing_ok=True)
    (NGINX_ENABLED / domain).symlink_to(NGINX_CONF / domain)
    
    # Hosts - không cần sudo tee, dùng bash nhanh hơn
    hosts = Path("/etc/hosts").read_text()
    if domain not in hosts:
        run(f'sudo bash -c \'echo "127.0.0.1 {domain}" >> /etc/hosts\'', shell=True)
    
    # Start nginx - silent
    run("sudo nginx -c /opt/homebrew/etc/nginx/nginx.conf 2>/dev/null", shell=True)
    print("✅")
    
    print(f"\n🎉 XONG!\n")
    print(f"🌐 https://{domain}")
    print(f"📁 {WWW}/{name}")
    print(f"🐘 PHP {php_ver}\n")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 mkproject.py project-name [php-version]")
        print("Example: python3 mkproject.py myproject 8.2")
        sys.exit(1)
    
    name = sys.argv[1]
    php = sys.argv[2] if len(sys.argv) > 2 else "8.2"
    
    if php not in PHP_PORTS:
        print(f"❌ PHP version không hợp lệ! Chọn: {', '.join(PHP_PORTS.keys())}")
        sys.exit(1)
    
    try:
        create_project(name, php)
    except KeyboardInterrupt:
        print("\n❌ Đã hủy!")
    except Exception as e:
        print(f"\n❌ Lỗi: {e}")

