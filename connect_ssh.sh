#!/bin/bash

# Function to display text in color
print_color() {
    local color=$1
    local text=$2
    case $color in
        "green") echo -e "\033[0;32m${text}\033[0m" ;;
        "blue")  echo -e "\033[0;34m${text}\033[0m" ;;
        "red")   echo -e "\033[0;31m${text}\033[0m" ;;
        "yellow") echo -e "\033[0;33m${text}\033[0m" ;;
    esac
}

# Đường dẫn đến thư mục SSH
SSH_DIR="./ssh"

# Tạo thư mục SSH nếu chưa tồn tại
if [ ! -d "$SSH_DIR" ]; then
    mkdir -p "$SSH_DIR"
    print_color "green" "✓ Đã tạo thư mục SSH"
fi

# Kiểm tra quyền của thư mục SSH
chmod 700 "$SSH_DIR"

# Function để lấy danh sách file SSH
get_ssh_files() {
    ls -1 "$SSH_DIR" 2>/dev/null
}

# Function để liệt kê các file SSH với số thứ tự
list_ssh_files() {
    print_color "blue" "=== Danh sách các file SSH ==="
    local files=($(get_ssh_files))
    if [ ${#files[@]} -eq 0 ]; then
        print_color "yellow" "Chưa có file SSH nào"
        return 1
    fi
    
    for i in "${!files[@]}"; do
        echo "[$((i+1))] ${files[$i]}"
    done
    return 0
}

# Function để thêm file SSH mới
add_ssh_file() {
    print_color "blue" "=== Thêm file SSH mới ==="
    read -p "Nhập đường dẫn đến file SSH (hoặc nhấn Enter để tạo mới): " ssh_file
    
    if [ -z "$ssh_file" ]; then
        create_ssh_script
        return 0
    fi
    
    if [ ! -f "$ssh_file" ]; then
        print_color "red" "❌ File không tồn tại!"
        return 1
    fi
    
    # Lấy tên file từ đường dẫn
    filename=$(basename "$ssh_file")
    
    # Copy file vào thư mục SSH
    cp "$ssh_file" "$SSH_DIR/$filename"
    chmod 700 "$SSH_DIR/$filename"
    
    print_color "green" "✓ Đã thêm file SSH: $filename"
}

# Function để tạo file SSH script mới
create_ssh_script() {
    print_color "blue" "=== Tạo file SSH mới ==="
    read -p "Nhập tên file (không cần .sh): " filename
    read -p "Nhập username: " username
    read -p "Nhập địa chỉ máy chủ: " host
    read -p "Nhập port (mặc định: 22): " port
    
    port=${port:-22}
    filename="${filename}.sh"
    
    # Tạo nội dung file SSH
    echo "#!/bin/bash" > "$SSH_DIR/$filename"
    echo "ssh -p $port $username@$host" >> "$SSH_DIR/$filename"
    
    # Cấp quyền thực thi
    chmod 700 "$SSH_DIR/$filename"
    
    print_color "green" "✓ Đã tạo file SSH: $filename"
}

# Function để xóa file SSH
remove_ssh_file() {
    print_color "blue" "=== Xóa file SSH ==="
    if ! list_ssh_files; then
        return 1
    fi
    
    local files=($(get_ssh_files))
    read -p "Nhập số thứ tự file cần xóa: " number
    
    if ! [[ "$number" =~ ^[0-9]+$ ]] || [ "$number" -lt 1 ] || [ "$number" -gt ${#files[@]} ]; then
        print_color "red" "❌ Số thứ tự không hợp lệ!"
        return 1
    fi
    
    local filename="${files[$((number-1))]}"
    if [ -f "$SSH_DIR/$filename" ]; then
        rm "$SSH_DIR/$filename"
        print_color "green" "✓ Đã xóa file: $filename"
    else
        print_color "red" "❌ File không tồn tại!"
    fi
}

# Function để kết nối SSH
connect_ssh() {
    print_color "blue" "=== Kết nối SSH ==="
    if ! list_ssh_files; then
        return 1
    fi
    
    local files=($(get_ssh_files))
    read -p "Nhập số thứ tự file SSH muốn sử dụng: " number
    
    if ! [[ "$number" =~ ^[0-9]+$ ]] || [ "$number" -lt 1 ] || [ "$number" -gt ${#files[@]} ]; then
        print_color "red" "❌ Số thứ tự không hợp lệ!"
        return 1
    fi
    
    local filename="${files[$((number-1))]}"
    if [ -f "$SSH_DIR/$filename" ]; then
        print_color "blue" "Đang kết nối..."
        bash "$SSH_DIR/$filename"
    else
        print_color "red" "❌ File SSH không tồn tại!"
    fi
}

# Menu chính
while true; do
    print_color "blue" "
=== QUẢN LÝ KẾT NỐI SSH ===
1. Liệt kê các file SSH
2. Thêm/Tạo file SSH mới
3. Xóa file SSH
4. Kết nối SSH
5. Thoát
"
    read -p "Chọn chức năng (1-5): " choice
    
    case $choice in
        1)
            list_ssh_files
            ;;
        2)
            add_ssh_file
            ;;
        3)
            remove_ssh_file
            ;;
        4)
            connect_ssh
            ;;
        5)
            print_color "green" "Tạm biệt!"
            exit 0
            ;;
        *)
            print_color "red" "❌ Lựa chọn không hợp lệ!"
            ;;
    esac
    
    echo
    read -p "Nhấn Enter để tiếp tục..."
done