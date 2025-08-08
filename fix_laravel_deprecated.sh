#!/usr/bin/env fish

# Script fix deprecated warnings cho Laravel
if test (count $argv) -eq 0
    echo "🔧 Fix deprecated warnings cho Laravel project hiện tại..."
    fix-laravel-deprecated
else
    set project_path $argv[1]
    if test -d $project_path
        cd $project_path
        fix-laravel-deprecated
    else
        echo "❌ Thư mục $project_path không tồn tại"
        exit 1
    end
end
