#!/usr/bin/env fish

# Script backup và restore cấu hình Valet

function backup-valet-config
    echo "📦 Đang backup cấu hình Valet..."
    
    # Tạo thư mục backup
    set backup_dir "$HOME/valet-backup/$(date +%Y%m%d_%H%M%S)"
    mkdir -p $backup_dir
    
    # Backup Valet config
    if test -d ~/.config/valet
        cp -r ~/.config/valet $backup_dir/
        echo "✅ Đã backup Valet config"
    end
    
    # Backup PHP configs
    for php_ver in 7.4 8.0 8.1 8.2 8.3
        if test -d "/opt/homebrew/etc/php/$php_ver"
            mkdir -p "$backup_dir/php/$php_ver"
            cp "/opt/homebrew/etc/php/$php_ver/php.ini" "$backup_dir/php/$php_ver/"
            echo "✅ Đã backup PHP $php_ver config"
        end
    end
    
    # Backup Homebrew services
    brew services list > "$backup_dir/brew-services.txt"
    echo "✅ Đã backup Homebrew services"
    
    echo "📁 Backup được lưu tại: $backup_dir"
end

function restore-valet-config
    if test (count $argv) -eq 0
        echo "❌ Vui lòng chỉ định thư mục backup. Ví dụ: restore-valet-config ~/valet-backup/20241201_090000"
        return 1
    end
    
    set backup_dir $argv[1]
    
    if not test -d $backup_dir
        echo "❌ Thư mục backup không tồn tại: $backup_dir"
        return 1
    end
    
    echo "🔄 Đang restore cấu hình Valet từ: $backup_dir"
    
    # Restore Valet config
    if test -d "$backup_dir/valet"
        rm -rf ~/.config/valet
        cp -r "$backup_dir/valet" ~/.config/
        echo "✅ Đã restore Valet config"
    end
    
    # Restore PHP configs
    if test -d "$backup_dir/php"
        for php_ver in (ls "$backup_dir/php/")
            if test -f "$backup_dir/php/$php_ver/php.ini"
                cp "$backup_dir/php/$php_ver/php.ini" "/opt/homebrew/etc/php/$php_ver/"
                echo "✅ Đã restore PHP $php_ver config"
            end
        end
    end
    
    # Restart services
    echo "🔄 Restart services..."
    valet restart
    brew services restart php@7.4 2>/dev/null
    brew services restart php@8.2 2>/dev/null
    
    echo "✅ Đã restore cấu hình thành công!"
end

# Main script
if test (count $argv) -eq 0
    echo "📝 Hướng dẫn sử dụng:"
    echo "  ./backup-valet-config.sh backup     # Backup cấu hình"
    echo "  ./backup-valet-config.sh restore <dir>  # Restore cấu hình"
    exit 1
end

set action $argv[1]

switch $action
    case "backup"
        backup-valet-config
    case "restore"
        restore-valet-config $argv[2..-1]
    case "*"
        echo "❌ Hành động không hợp lệ: $action"
        echo "💡 Sử dụng: backup hoặc restore"
        exit 1
end
