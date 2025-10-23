#!/usr/bin/env python3
"""
Project Manager - Quản lý các project Nginx
"""

import os
import sys
import subprocess
from pathlib import Path

WWW = Path("/opt/homebrew/var/www")
NGINX_CONF = Path("/opt/homebrew/etc/nginx/sites-available")
NGINX_ENABLED = Path("/opt/homebrew/etc/nginx/sites-enabled")
SSL_DIR = Path("/opt/homebrew/etc/nginx/ssl")
HOSTS = Path("/etc/hosts")

def run(cmd, shell=False):
    """Chạy lệnh"""
    if isinstance(cmd, str) and not shell:
        cmd = cmd.split()
    return subprocess.run(cmd, shell=shell, check=False, capture_output=True, text=True)

def get_projects():
    """Lấy danh sách projects"""
    if not WWW.exists():
        return []
    
    projects = []
    for p in WWW.iterdir():
        if p.is_dir() and not p.name.startswith('.'):
            domain = f"{p.name}.test"
            conf_exists = (NGINX_CONF / domain).exists()
            ssl_exists = (SSL_DIR / f"{domain}.crt").exists()
            projects.append({
                'name': p.name,
                'domain': domain,
                'path': p,
                'has_config': conf_exists,
                'has_ssl': ssl_exists
            })
    
    return sorted(projects, key=lambda x: x['name'])

def list_projects():
    """Hiển thị danh sách projects"""
    projects = get_projects()
    
    if not projects:
        print("❌ Chưa có project nào!")
        return
    
    print(f"\n📋 Có {len(projects)} projects:\n")
    
    for i, p in enumerate(projects, 1):
        status = "✅" if p['has_config'] and p['has_ssl'] else "⚠️"
        print(f"{i:2}. {status} {p['name']:30} → https://{p['domain']}")
    
    print()

def delete_project(name):
    """Xóa project hoàn toàn"""
    domain = f"{name}.test"
    
    print(f"\n🗑️  Đang xóa: {name}")
    
    # 1. Xóa thư mục project
    project_dir = WWW / name
    if project_dir.exists():
        print(f"   📁 Xóa thư mục...", end=" ")
        run(f"rm -rf {project_dir}", shell=True)
        print("✅")
    
    # 2. Xóa nginx config
    conf_file = NGINX_CONF / domain
    if conf_file.exists():
        print(f"   ⚙️  Xóa nginx config...", end=" ")
        conf_file.unlink()
        print("✅")
    
    # 3. Xóa nginx enabled
    enabled_file = NGINX_ENABLED / domain
    if enabled_file.exists() or enabled_file.is_symlink():
        enabled_file.unlink()
    
    # 4. Xóa SSL certificates
    print(f"   🔒 Xóa SSL...", end=" ")
    for cert in SSL_DIR.glob(f"{domain}*"):
        cert.unlink()
    print("✅")
    
    # 5. Xóa khỏi /etc/hosts
    print(f"   📝 Xóa khỏi hosts...", end=" ")
    hosts_content = HOSTS.read_text()
    new_hosts = "\n".join([
        line for line in hosts_content.split("\n")
        if domain not in line
    ])
    run(f'sudo bash -c \'echo "{new_hosts}" > /etc/hosts\'', shell=True)
    print("✅")
    
    # 6. Reload nginx
    print(f"   🔄 Reload nginx...", end=" ")
    run("sudo nginx -s reload 2>/dev/null", shell=True)
    print("✅")
    
    print(f"\n✅ Đã xóa {name} hoàn toàn!\n")

def delete_menu():
    """Menu xóa project"""
    projects = get_projects()
    
    if not projects:
        print("❌ Chưa có project nào để xóa!")
        return
    
    print(f"\n🗑️  XÓA PROJECT\n")
    
    for i, p in enumerate(projects, 1):
        print(f"{i:2}. {p['name']}")
    
    print(f" 0. Quay lại")
    
    try:
        choice = input("\nChọn project cần xóa (số): ").strip()
        
        if choice == "0":
            return
        
        idx = int(choice) - 1
        if 0 <= idx < len(projects):
            project = projects[idx]
            
            confirm = input(f"\n⚠️  Xác nhận xóa '{project['name']}'? (y/N): ").strip().lower()
            
            if confirm == 'y':
                delete_project(project['name'])
            else:
                print("❌ Đã hủy!")
        else:
            print("❌ Số không hợp lệ!")
    
    except (ValueError, KeyboardInterrupt):
        print("\n❌ Đã hủy!")

def view_project(name):
    """Xem chi tiết project"""
    domain = f"{name}.test"
    project_dir = WWW / name
    
    print(f"\n📦 PROJECT: {name}\n")
    print(f"🌐 Domain:  https://{domain}")
    print(f"📁 Path:    {project_dir}")
    
    # Check nginx config
    conf_file = NGINX_CONF / domain
    if conf_file.exists():
        print(f"⚙️  Nginx:   ✅ {conf_file}")
    else:
        print(f"⚙️  Nginx:   ❌ Không có config")
    
    # Check SSL
    cert_file = SSL_DIR / f"{domain}.crt"
    if cert_file.exists():
        print(f"🔒 SSL:     ✅ {cert_file}")
    else:
        print(f"🔒 SSL:     ❌ Không có certificate")
    
    # Check hosts
    hosts_content = HOSTS.read_text()
    if domain in hosts_content:
        print(f"📝 Hosts:   ✅ Đã thêm vào /etc/hosts")
    else:
        print(f"📝 Hosts:   ❌ Chưa có trong /etc/hosts")
    
    # Check PHP
    if project_dir.exists():
        public_dir = project_dir / "public"
        if public_dir.exists():
            files = list(public_dir.glob("*"))
            print(f"📄 Files:   {len(files)} files trong public/")
        else:
            print(f"📄 Files:   ⚠️  Không có thư mục public/")
    else:
        print(f"📄 Files:   ❌ Thư mục không tồn tại")
    
    print()

def view_menu():
    """Menu xem chi tiết project"""
    projects = get_projects()
    
    if not projects:
        print("❌ Chưa có project nào!")
        return
    
    print(f"\n👁️  XEM CHI TIẾT\n")
    
    for i, p in enumerate(projects, 1):
        print(f"{i:2}. {p['name']}")
    
    print(f" 0. Quay lại")
    
    try:
        choice = input("\nChọn project: ").strip()
        
        if choice == "0":
            return
        
        idx = int(choice) - 1
        if 0 <= idx < len(projects):
            view_project(projects[idx]['name'])
            input("\nNhấn Enter để tiếp tục...")
        else:
            print("❌ Số không hợp lệ!")
    
    except (ValueError, KeyboardInterrupt):
        print("\n❌ Đã hủy!")

def open_browser(name):
    """Mở project trong browser"""
    domain = f"{name}.test"
    print(f"🌐 Mở https://{domain}...")
    run(f"open https://{domain}", shell=True)

def open_menu():
    """Menu mở browser"""
    projects = get_projects()
    
    if not projects:
        print("❌ Chưa có project nào!")
        return
    
    print(f"\n🌐 MỞ TRONG BROWSER\n")
    
    for i, p in enumerate(projects, 1):
        print(f"{i:2}. {p['name']}")
    
    print(f" 0. Quay lại")
    
    try:
        choice = input("\nChọn project: ").strip()
        
        if choice == "0":
            return
        
        idx = int(choice) - 1
        if 0 <= idx < len(projects):
            open_browser(projects[idx]['name'])
        else:
            print("❌ Số không hợp lệ!")
    
    except (ValueError, KeyboardInterrupt):
        print("\n❌ Đã hủy!")

def main_menu():
    """Menu chính"""
    while True:
        print("\n" + "="*50)
        print("🛠️  PROJECT MANAGER")
        print("="*50)
        
        print("\n1. 📋 Liệt kê projects")
        print("2. 👁️  Xem chi tiết project")
        print("3. 🌐 Mở trong browser")
        print("4. 🗑️  Xóa project")
        print("5. 🚪 Thoát")
        
        try:
            choice = input("\nChọn (1-5): ").strip()
            
            if choice == "1":
                list_projects()
                input("Nhấn Enter để tiếp tục...")
            
            elif choice == "2":
                view_menu()
            
            elif choice == "3":
                open_menu()
            
            elif choice == "4":
                delete_menu()
            
            elif choice == "5":
                print("\n👋 Bye!\n")
                break
            
            else:
                print("❌ Chọn từ 1-5!")
        
        except KeyboardInterrupt:
            print("\n\n👋 Bye!\n")
            break

if __name__ == "__main__":
    try:
        main_menu()
    except Exception as e:
        print(f"\n❌ Lỗi: {e}")
        sys.exit(1)

