import re

with open('E:/fastway/lib/core/api/mock_api_interceptor.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(r'data: \{"message": "\?\?\? \?\? \?\?\?\?\?\? \?\?\?\? \?\?\?\?\? 200 \?\.\? \?\?\?\?\?\? \?\?\?\?\?\?\?"\}', 'data: {"message": "يجب ان تتجاوز قيمة الطلب 200 ر.س لتطبيق الكوبون"}', content)
content = re.sub(r'data: \{"message": "\?\?\?\?\? \?\?\? \?\?\?\?"\}', 'data: {"message": "كوبون غير صالح"}', content)

with open('E:/fastway/lib/core/api/mock_api_interceptor.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
