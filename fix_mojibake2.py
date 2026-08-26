import re

with open('E:/fastway/lib/core/api/mock_api_interceptor.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('"name": "????? ????"', '"name": "توصيل عادي"')
content = content.replace('"name": "????? ??? ????????"', '"name": "الدفع عند الاستلام"')
content = content.replace('"name": "???????"', '"name": "المحفظة"')
content = content.replace('"name_ar": "??????"', '"name_ar": "الرياض"')

with open('E:/fastway/lib/core/api/mock_api_interceptor.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
