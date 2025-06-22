#!/bin/bash

# Function to display text in color
print_color() {
    local color=$1
    local text=$2
    case $color in
        "green") echo -e "\033[0;32m${text}\033[0m" ;;
        "blue")  echo -e "\033[0;34m${text}\033[0m" ;;
        "red")   echo -e "\033[0;31m${text}\033[0m" ;;
    esac
}

# Check and install Homebrew if not installed
if ! command -v brew &> /dev/null; then
    print_color "blue" "📦 Đang cài đặt Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install Fish Shell
print_color "blue" "🐟 Đang cài đặt Fish Shell..."
brew install fish

# Add Fish to allowed shells
print_color "blue" "🔒 Thêm Fish vào danh sách shell được phép..."
if [[ "$(uname -m)" == "arm64" ]]; then
    # For Apple Silicon
    echo "/opt/homebrew/bin/fish" | sudo tee -a /etc/shells
else
    # For Intel Mac
    echo "/usr/local/bin/fish" | sudo tee -a /etc/shells
fi

# Set Fish as default shell
print_color "blue" "🔄 Đặt Fish làm shell mặc định..."
if [[ "$(uname -m)" == "arm64" ]]; then
    chsh -s /opt/homebrew/bin/fish
else
    chsh -s /usr/local/bin/fish
fi

# Install Oh My Fish
print_color "blue" "🎨 Đang cài đặt Oh My Fish..."
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish

# Install Powerline fonts
print_color "blue" "📝 Đang cài đặt font Powerline..."
git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
./install.sh
cd ..
rm -rf fonts

# Create Fish config directory
mkdir -p ~/.config/fish

# Create Fish config
print_color "blue" "⚙️ Tạo cấu hình Fish..."
cat > ~/.config/fish/config.fish << 'EOL'
# Cấu hình môi trường
set -gx PATH /opt/homebrew/bin $PATH
set -gx PATH /opt/homebrew/sbin $PATH
set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8
set -gx EDITOR nano

# Cấu hình Node.js
set -gx PATH node_modules/.bin $PATH

# Cấu hình PHP/Composer
set -gx PATH ~/.composer/vendor/bin $PATH

# Alias cho Laravel
alias art="php artisan"
alias sail="./vendor/bin/sail"
alias serve="php -S localhost:8000"

# Alias cho Git
alias g="git"
alias gst="git status"
alias gaa="git add ."
alias gcm="git commit -m"
alias gco="git checkout"
alias gpl="git pull"
alias gps="git push"

# Alias cho Docker
alias d="docker"
alias dc="docker-compose"
alias dps="docker ps"

# Alias cho npm/yarn
alias ni="npm install"
alias nr="npm run"
alias dev="npm run dev"
alias build="npm run build"
alias yi="yarn install"
alias yd="yarn dev"

# Cấu hình Fish prompt
function fish_prompt
    set_color brblue
    echo -n "["
    set_color yellow
    echo -n (whoami)
    set_color green
    echo -n "@"
    set_color brblue
    echo -n (hostname)
    set_color brblue
    echo -n "] "
    set_color $fish_color_cwd
    echo -n (prompt_pwd)
    set_color red
    echo -n (__fish_git_prompt)
    set_color normal
    echo -n "> "
end

# Cấu hình Git trong prompt
set -g __fish_git_prompt_show_informative_status 1
set -g __fish_git_prompt_showdirtystate 'yes'
set -g __fish_git_prompt_char_stateseparator ' '
set -g __fish_git_prompt_char_dirtystate '⚡'
set -g __fish_git_prompt_char_cleanstate '✔'
set -g __fish_git_prompt_char_untrackedfiles '…'
set -g __fish_git_prompt_char_stagedstate '→'
set -g __fish_git_prompt_char_conflictedstate '✖'
EOL

# Install useful Oh My Fish packages
print_color "blue" "🔌 Đang cài đặt các plugin hữu ích..."
fish -c "omf install bobthefish"
fish -c "omf install bass"
fish -c "omf install z"
fish -c "omf install nvm"

# Set bobthefish theme
fish -c "omf theme bobthefish"

print_color "green" "
🎉 Fish Shell đã được cài đặt và cấu hình thành công!

📝 Đã cài đặt:
- Fish Shell với Oh My Fish
- Theme bobthefish
- Font Powerline
- Các plugin: bass, z, nvm
- Cấu hình cho PHP/Laravel, Node.js, Git, Docker

💡 Tính năng:
- Prompt đẹp với thông tin Git
- Alias cho Laravel, Git, Docker, npm/yarn
- Auto-completion thông minh
- Directory navigation với z
- Node version management với nvm

⚙️ File cấu hình:
- ~/.config/fish/config.fish

🔄 Để áp dụng thay đổi:
1. Đóng terminal hiện tại
2. Mở terminal mới
3. Fish shell sẽ tự động được kích hoạt

🎨 Gợi ý:
- Sử dụng 'omf list' để xem các plugin đã cài
- Sử dụng 'omf theme' để đổi theme
- Chỉnh sửa ~/.config/fish/config.fish để thêm alias
" 