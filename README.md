# 即梦 4.0 Pro 文生图

火山引擎即梦 AI 图片生成 4.0 API 封装。

## 功能

- 🎨 文生图：根据提示词生成图片
- 🖼️ 支持多种尺寸：1024x1024, 1280x720, 720x1280
- ⚡ 异步任务：支持任务提交和结果查询

## 安装

```bash
# 确保已安装 Python 和 volcengine SDK
pip3 install volcengine
```

## 使用

```python
from jimeng4 import Jimeng

client = Jimeng(
    ak='你的AccessKey',
    sk='你的SecretKey'
)

# 生成图片
result = client.generate('一只可爱的猫咪')
print(result['images'])
```

## API Key

需要火山引擎即梦 AI 服务权限：
1. 登录 https://console.volcengine.com/
2. 开通 "即梦 AI 图片生成 4.0"
3. 获取 Access Key 和 Secret Key

## 参数说明

| 参数 | 类型 | 说明 |
|------|------|------|
| prompt | string | 提示词 |
| width | int | 图片宽度 |
| height | int | 图片高度 |

## License

MIT
