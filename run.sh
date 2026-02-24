#!/bin/bash
# 加载密钥并运行
source "$(dirname "$0")/.env"

if [ $# -eq 0 ]; then
    echo "用法: ./run.sh \"提示词\""
    echo "示例: ./run.sh \"一只可爱的猫咪\""
    exit 1
fi

python3 "$(dirname "$0")/scripts/jimeng4.py" "$JIMENG_AK" "$JIMENG_SK" "$@"
