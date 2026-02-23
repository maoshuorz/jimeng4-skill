#!/usr/bin/env python3
"""
即梦 4.0 Pro 文生图
"""

import json
import sys
import time
from volcengine.visual.VisualService import VisualService

class Jimeng:
    def __init__(self, ak, sk):
        self.client = VisualService()
        self.client.set_ak(ak)
        self.client.set_sk(sk)
    
    def generate(self, prompt, width=1024, height=1024, max_wait=60):
        """生成图片"""
        # 提交任务
        resp = self.client.cv_sync2async_submit_task({
            'req_key': 'jimeng_t2i_v40',
            'prompt': prompt,
            'width': width,
            'height': height
        })
        
        task_id = resp.get('data', {}).get('task_id')
        if not task_id:
            return {'error': 'No task_id', 'response': resp}
        
        # 等待结果
        start_time = time.time()
        while time.time() - start_time < max_wait:
            time.sleep(2)
            result = self.client.cv_sync2async_get_result({
                'req_key': 'jimeng_t2i_v40',
                'task_id': task_id
            })
            
            status = result.get('data', {}).get('status')
            if status == 'done':
                images = result.get('data', {}).get('task_result', {}).get('image_urls', [])
                return {
                    'task_id': task_id,
                    'status': 'done',
                    'images': images,
                    'binary_data': result.get('data', {}).get('task_result', {}).get('binary_data_base64', [])
                }
            elif status == 'failed':
                return {'error': 'Generation failed', 'task_id': task_id}
        
        return {'error': 'Timeout', 'task_id': task_id}

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python jimeng.py <ak> <sk> <prompt>")
        sys.exit(1)
    
    ak = sys.argv[1]
    sk = sys.argv[2]
    prompt = ' '.join(sys.argv[3:])
    
    client = Jimeng(ak, sk)
    result = client.generate(prompt)
    print(json.dumps(result, indent=2))
