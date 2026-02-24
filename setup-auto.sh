#!/bin/bash
# OpenClaw 自动生图 - 一键启动服务
# 创建定时任务，自动生成图片并发送通知

echo "🎨 OpenClaw 自动生图服务配置"
echo "================================"
echo ""

# 检查密钥
if [ -f ~/.jimeng-credentials ]; then
    echo "✅ 找到密钥文件: ~/.jimeng-credentials"
else
    echo "⚠️  需要配置密钥"
    echo ""
    read -p "输入 Access Key (AK): " ak
    read -p "输入 Secret Key (SK): " sk
    
    cat > ~/.jimeng-credentials << EOF
export JIMENG_AK="$ak"
export JIMENG_SK="$sk"
EOF
    chmod 600 ~/.jimeng-credentials
    echo "✅ 密钥已保存（仅当前用户可读）"
fi

echo ""
echo "配置选项:"
echo "1) 每小时自动生成一张随机图片"
echo "2) 每天特定时间生成图片"
echo "3) 手动触发（通过 OpenClaw 命令）"
echo "4) 通过 API 调用（Webhook）"
echo ""
read -p "选择 [1-4]: " choice

SERVICE_FILE="$HOME/Library/LaunchAgents/com.jimeng4.auto.plist"

# 创建输出目录
mkdir -p ~/jimeng4-outputs

case $choice in
    1)
        echo "创建每小时自动任务..."
        cat > "$SERVICE_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.jimeng4.auto</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>source ~/.jimeng-credentials \&\& ~/jimeng4-skill/scripts/auto-generate.sh "随机风景图" ~/jimeng4-outputs</string>
    </array>
    <key>StartInterval</key>
    <integer>3600</integer>
    <key>StandardOutPath</key>
    <string>/tmp/jimeng4-auto.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/jimeng4-auto.error.log</string>
</dict>
</plist>
EOF
        launchctl load "$SERVICE_FILE" 2>/dev/null || launchctl bootstrap gui/$(id -u) "$SERVICE_FILE"
        echo "✅ 每小时自动任务已启动"
        ;;
    
    2)
        read -p "输入时间 (如 09:00): " time
        hour=${time%%:*}
        min=${time##*:}
        
        echo "创建每天 $time 自动任务..."
        cat > "$SERVICE_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.jimeng4.auto</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>source ~/.jimeng-credentials \&\& ~/jimeng4-skill/scripts/auto-generate.sh "每日一图" ~/jimeng4-outputs</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>$hour</integer>
        <key>Minute</key>
        <integer>$min</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/jimeng4-auto.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/jimeng4-auto.error.log</string>
</dict>
</plist>
EOF
        launchctl load "$SERVICE_FILE" 2>/dev/null || launchctl bootstrap gui/$(id -u) "$SERVICE_FILE"
        echo "✅ 每天 $time 自动任务已启动"
        ;;
    
    3)
        echo "创建 OpenClaw 命令别名..."
        cat >> ~/.zshrc << 'EOF'

# Jimeng4 自动生图别名
alias jmgen='source ~/.jimeng-credentials && ~/jimeng4-skill/scripts/auto-generate.sh'
EOF
        echo "✅ 已添加别名 'jmgen'"
        echo "使用: jmgen \"提示词\""
        ;;
    
    4)
        echo "创建 API Webhook 服务..."
        cat > ~/jimeng4-skill/scripts/webhook-server.py << 'PYEOF'
#!/usr/bin/env python3
"""简单的 webhook 服务，接收 HTTP 请求生成图片"""

import os
import sys
import json
import subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/generate':
            content_len = int(self.headers.get('Content-Length', 0))
            post_body = self.rfile.read(content_len)
            
            try:
                data = json.loads(post_body)
                prompt = data.get('prompt', '一只可爱的猫咪')
                
                # 运行生图脚本
                result = subprocess.run([
                    '/bin/bash', '-c',
                    f'source ~/.jimeng-credentials && ~/jimeng4-skill/scripts/auto-generate.sh "{prompt}"'
                ], capture_output=True, text=True)
                
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({
                    'status': 'success',
                    'output': result.stdout,
                    'error': result.stderr
                }).encode())
            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(json.dumps({'error': str(e)}).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        pass  # 禁用日志

if __name__ == '__main__':
    port = int(os.environ.get('JIMENG_PORT', 8765))
    server = HTTPServer(('localhost', port), Handler)
    print(f'Webhook server running on http://localhost:{port}/generate')
    print('POST JSON: {"prompt": "提示词"}')
    server.serve_forever()
PYEOF
        chmod +x ~/jimeng4-skill/scripts/webhook-server.py
        
        cat > ~/Library/LaunchAgents/com.jimeng4.webhook.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.jimeng4.webhook</string>
    <key>ProgramArguments</key>
    <array>
        <string>python3</string>
        <string>$HOME/jimeng4-skill/scripts/webhook-server.py</string>
    </array>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/jimeng4-webhook.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/jimeng4-webhook.error.log</string>
</dict>
</plist>
EOF
        launchctl load ~/Library/LaunchAgents/com.jimeng4.webhook.plist 2>/dev/null
        echo "✅ Webhook 服务已启动"
        echo "API: http://localhost:8765/generate"
        echo "示例: curl -X POST http://localhost:8765/generate -d '{\"prompt\": \"一只猫\"}'"
        ;;
esac

echo ""
echo "================================"
echo "🎉 自动生图服务配置完成！"
echo ""
echo "管理命令:"
echo "  查看日志: tail -f /tmp/jimeng4-auto.log"
echo "  停止服务: launchctl unload ~/Library/LaunchAgents/com.jimeng4.auto.plist"
echo "  手动生成: ~/jimeng4-skill/scripts/auto-generate.sh \"提示词\""
echo ""
