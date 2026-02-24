#!/bin/bash
# OpenClaw 自动生图服务 - 定时任务脚本
# 将此脚本添加到 crontab 实现自动生成

set -e

# 配置
PROMPT="${1:-一只在草地上玩耍的金毛犬}"
OUTPUT_DIR="${2:-$HOME/jimeng4-outputs}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 从安全位置读取密钥（用户需提前设置）
AK="${JIMENG_AK:-}"
SK="${JIMENG_SK:-}"

if [ -z "$AK" ] || [ -z "$SK" ]; then
    echo "❌ 错误: 未设置 JIMENG_AK 或 JIMENG_SK 环境变量"
    echo "请先运行: source ~/.jimeng-credentials"
    exit 1
fi

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 运行生图
echo "🎨 开始生成图片..."
echo "提示词: $PROMPT"
echo "时间: $(date)"

cd ~/jimeng4-skill
RESULT=$(python scripts/jimeng4.py "$AK" "$SK" "$PROMPT")

# 解析结果
STATUS=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','unknown'))")

echo "结果: $RESULT"

if [ "$STATUS" = "done" ]; then
    # 提取图片URL
    IMAGE_URL=$(echo "$RESULT" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('images',[''])[0])")
    
    # 下载图片
    OUTPUT_FILE="$OUTPUT_DIR/image_${TIMESTAMP}.jpg"
    curl -sL "$IMAGE_URL" -o "$OUTPUT_FILE"
    
    echo "✅ 图片生成成功!"
    echo "保存位置: $OUTPUT_FILE"
    echo "图片URL: $IMAGE_URL"
    
    # 发送通知（如果配置了 Telegram/其他渠道）
    # openclaw message send --target @user --message "图片已生成: $OUTPUT_FILE"
else
    echo "❌ 生成失败: $RESULT"
    exit 1
fi
