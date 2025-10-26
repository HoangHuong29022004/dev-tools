#!/usr/bin/env python3
"""
Development Environment Installer - Cài đặt môi trường dev cho Mac mới
"""

import os
import sys
import subprocess
from pathlib import Path

def run(cmd, shell=False, check=True):
    """Chạy lệnh"""
    if isinstance(cmd, str) and not shell:
        cmd = cmd.split()
    result = subprocess.run(cmd, shell=shell, check=False, capture_output=True, text=True)
    if check and result.returncode != 0:
        print(f"❌ Lỗi: {result.stderr}")
        return False
    return result.returncode == 0

def check_installed(package):
    """Kiểm tra package đã cài chưa"""
    result = subprocess.run(
        ["brew", "list", package],
        capture_output=True,
        check=False
    )
    return result.returncode == 0

def install_homebrew():
    """Cài Homebrew"""
    print("\n📦 HOMEBREW")
    print("="*50)
    
    if run("which brew", shell=True, check=False):
        print("✅ Homebrew đã cài đặt!")
        return True
    
    print("🔧 Đang cài Homebrew...")
    cmd = '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    if run(cmd, shell=True):
        print("✅ Đã cài Homebrew!")
        return True
    return False

def install_nginx():
    """Cài Nginx"""
    print("\n🌐 NGINX")
    print("="*50)
    
    if check_installed("nginx"):
        print("✅ Nginx đã cài đặt!")
        return True
    
    print("🔧 Đang cài Nginx...")
    if run("brew install nginx"):
        # Tạo thư mục
        dirs = [
            "/opt/homebrew/var/run/nginx/client_body_temp",
            "/opt/homebrew/var/run/nginx/proxy_temp",
            "/opt/homebrew/var/run/nginx/fastcgi_temp",
            "/opt/homebrew/var/log/nginx",
            "/opt/homebrew/etc/nginx/sites-available",
            "/opt/homebrew/etc/nginx/sites-enabled",
            "/opt/homebrew/etc/nginx/ssl",
            "/opt/homebrew/var/www"
        ]
        for d in dirs:
            Path(d).mkdir(parents=True, exist_ok=True)
        
        # Fix permissions
        run("sudo chmod -R 777 /opt/homebrew/var/run/nginx", shell=True, check=False)
        
        print("✅ Đã cài Nginx!")
        print(f"   Config: /opt/homebrew/etc/nginx/nginx.conf")
        return True
    return False

def install_php():
    """Cài PHP"""
    print("\n🐘 PHP")
    print("="*50)
    print("\nChọn PHP versions cần cài (cách nhau bằng dấu cách):")
    print("1) PHP 7.4 (port 9074)  |  2) PHP 8.0 (port 9080)")
    print("3) PHP 8.1 (port 9081)  |  4) PHP 8.2 (port 9082)")
    print("5) PHP 8.3 (port 9083)  |  6) PHP 8.4 (port 9084)")
    print("0) Bỏ qua")
    
    choice = input("\nChọn (vd: 4 5 6): ").strip()
    if choice == "0":
        return True
    
    versions = {
        "1": "7.4", "2": "8.0", "3": "8.1",
        "4": "8.2", "5": "8.3", "6": "8.4"
    }
    
    # Port mapping: PHP 8.4 → 9084, PHP 8.2 → 9082
    def get_port(ver):
        return f"90{ver.replace('.', '')}"
    
    selected = [versions[c] for c in choice.split() if c in versions]
    
    for ver in selected:
        package = f"php@{ver}"
        port = get_port(ver)
        
        print(f"\n🔧 Cài PHP {ver} (port {port})...")
        
        if check_installed(package):
            print(f"✅ PHP {ver} đã cài!")
        else:
            if run(f"brew install {package}"):
                print(f"✅ Đã cài PHP {ver}!")
            else:
                print(f"❌ Không cài được PHP {ver}")
                continue
        
        # Config port riêng cho từng version
        conf_file = Path(f"/opt/homebrew/etc/php/{ver}/php-fpm.d/www.conf")
        if conf_file.exists():
            conf = conf_file.read_text()
            
            # Đổi từ socket sang port
            if "listen = " in conf:
                # Backup
                conf_file.with_suffix('.conf.bak').write_text(conf)
                
                # Replace listen directive
                lines = []
                for line in conf.split('\n'):
                    if line.startswith('listen = '):
                        lines.append(f'listen = 127.0.0.1:{port}')
                    else:
                        lines.append(line)
                
                conf_file.write_text('\n'.join(lines))
                print(f"   ⚙️  Configured port {port}")
        
        # Start service
        run(f"brew services start {package}", check=False)
        print(f"   🚀 Started PHP-FPM {ver}")
    
    return True

def install_composer():
    """Cài Composer"""
    print("\n🎼 COMPOSER")
    print("="*50)
    
    if run("which composer", shell=True, check=False):
        print("✅ Composer đã cài đặt!")
        return True
    
    print("🔧 Đang cài Composer...")
    if run("brew install composer"):
        print("✅ Đã cài Composer!")
        run("composer --version", shell=True, check=False)
        return True
    return False

def install_nodejs():
    """Cài Node.js"""
    print("\n📗 NODE.JS")
    print("="*50)
    print("\nChọn Node.js version:")
    print("1) v18 LTS")
    print("2) v20 LTS (Khuyến nghị)")
    print("3) v22 Latest")
    print("0) Bỏ qua")
    
    choice = input("\nChọn (1-3): ").strip()
    
    if choice == "0":
        return True
    
    versions = {"1": "18", "2": "20", "3": "22"}
    ver = versions.get(choice, "20")
    
    print(f"\n🔧 Cài Node.js v{ver}...")
    
    # Cài nvm/fnm trước
    if not run("which fnm", shell=True, check=False):
        print("🔧 Cài fnm (Fast Node Manager)...")
        run("brew install fnm")
    
    # Cài Node
    run(f"fnm install {ver}", shell=True)
    run(f"fnm use {ver}", shell=True)
    run(f"fnm default {ver}", shell=True)
    
    print(f"✅ Đã cài Node.js v{ver}!")
    print("   Thêm vào ~/.config/fish/config.fish:")
    print("   fnm env --use-on-cd | source")
    
    return True

def install_mysql():
    """Cài MySQL"""
    print("\n🗄️  MYSQL")
    print("="*50)
    print("\nChọn MySQL version:")
    print("1) MySQL 5.7")
    print("2) MySQL 8.0 (Khuyến nghị)")
    print("3) MySQL 8.4 Latest")
    print("0) Bỏ qua")
    
    choice = input("\nChọn (1-3): ").strip()
    
    if choice == "0":
        return True
    
    packages = {
        "1": "mysql@5.7",
        "2": "mysql@8.0",
        "3": "mysql"
    }
    
    package = packages.get(choice, "mysql@8.0")
    
    if check_installed(package):
        print(f"✅ {package} đã cài đặt!")
        return True
    
    print(f"🔧 Đang cài {package}...")
    if run(f"brew install {package}"):
        # Start service
        run(f"brew services start {package}", check=False)
        print(f"✅ Đã cài {package}!")
        print(f"   Start: brew services start {package}")
        print(f"   Stop:  brew services stop {package}")
        return True
    return False

def install_fish():
    """Cài Fish shell"""
    print("\n🐟 FISH SHELL")
    print("="*50)
    
    if check_installed("fish"):
        print("✅ Fish đã cài đặt!")
        return True
    
    print("🔧 Đang cài Fish shell...")
    if run("brew install fish"):
        print("✅ Đã cài Fish!")
        print("\n💡 Để đặt Fish làm shell mặc định:")
        print("   echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells")
        print("   chsh -s /opt/homebrew/bin/fish")
        return True
    return False

def install_essentials():
    """Cài các tools cần thiết"""
    print("\n🛠️  ESSENTIAL TOOLS")
    print("="*50)
    
    tools = {
        "git": "Git - Version control",
        "wget": "Wget - Download tool",
        "curl": "cURL - HTTP client",
        "mkcert": "mkcert - SSL certificates",
        "imagemagick": "ImageMagick - Image processing",
        "redis": "Redis - Cache server",
        "gh": "GitHub CLI",
    }
    
    print("\nCài các tools sau:")
    for name, desc in tools.items():
        print(f"  • {name:15} - {desc}")
    
    confirm = input("\nCài tất cả? (Y/n): ").strip().lower()
    
    if confirm == "n":
        return True
    
    installed = 0
    for tool in tools.keys():
        if check_installed(tool):
            print(f"✅ {tool} - đã có")
            continue
        
        print(f"🔧 Cài {tool}...", end=" ", flush=True)
        if run(f"brew install {tool}"):
            print("✅")
            installed += 1
        else:
            print("❌")
    
    print(f"\n✅ Đã cài {installed} tools mới!")
    
    # Setup mkcert
    if check_installed("mkcert"):
        print("\n🔒 Setup mkcert...")
        run("mkcert -install", check=False)
    
    return True

def install_all():
    """Cài tất cả"""
    print("\n🚀 CÀI ĐẶT TẤT CẢ")
    print("="*50)
    print("\nSẽ cài:")
    print("  • Homebrew")
    print("  • Nginx")
    print("  • PHP 8.2, 8.3, 8.4")
    print("  • Composer")
    print("  • Node.js v20")
    print("  • MySQL 8.0")
    print("  • Fish shell")
    print("  • Essential tools")
    
    confirm = input("\nXác nhận? (y/N): ").strip().lower()
    
    if confirm != "y":
        print("❌ Đã hủy!")
        return
    
    print("\n" + "="*50)
    print("BẮT ĐẦU CÀI ĐẶT")
    print("="*50)
    
    install_homebrew()
    install_nginx()
    
    # Auto install PHP 8.2, 8.3, 8.4
    for ver in ["8.2", "8.3", "8.4"]:
        package = f"php@{ver}"
        if not check_installed(package):
            print(f"\n🔧 Cài PHP {ver}...")
            run(f"brew install {package}")
    
    install_composer()
    
    # Auto install Node.js 20
    if not run("which node", shell=True, check=False):
        print("\n🔧 Cài Node.js v20...")
        run("brew install fnm")
        run("fnm install 20", shell=True)
        run("fnm default 20", shell=True)
    
    # Auto install MySQL 8.0
    if not check_installed("mysql@8.0"):
        print("\n🔧 Cài MySQL 8.0...")
        run("brew install mysql@8.0")
    
    install_fish()
    install_essentials()
    
    print("\n" + "="*50)
    print("✅ HOÀN TẤT!")
    print("="*50)

def main_menu():
    """Menu chính"""
    while True:
        print("\n" + "="*50)
        print("⚙️  DEV ENVIRONMENT INSTALLER")
        print("="*50)
        
        print("\n1.  🌐 Nginx")
        print("2.  🐘 PHP (chọn versions)")
        print("3.  🎼 Composer")
        print("4.  📗 Node.js (chọn version)")
        print("5.  🗄️  MySQL (chọn version)")
        print("6.  🐟 Fish Shell")
        print("7.  🛠️  Essential Tools")
        print("8.  🚀 Cài tất cả")
        print("9.  🚪 Thoát")
        
        try:
            choice = input("\nChọn (1-9): ").strip()
            
            if choice == "1":
                install_nginx()
            elif choice == "2":
                install_php()
            elif choice == "3":
                install_composer()
            elif choice == "4":
                install_nodejs()
            elif choice == "5":
                install_mysql()
            elif choice == "6":
                install_fish()
            elif choice == "7":
                install_essentials()
            elif choice == "8":
                install_all()
            elif choice == "9":
                print("\n👋 Bye!\n")
                break
            else:
                print("❌ Chọn từ 1-9!")
        
        except KeyboardInterrupt:
            print("\n\n👋 Bye!\n")
            break
        except Exception as e:
            print(f"\n❌ Lỗi: {e}")

if __name__ == "__main__":
    try:
        main_menu()
    except Exception as e:
        print(f"\n❌ Lỗi: {e}")
        sys.exit(1)

