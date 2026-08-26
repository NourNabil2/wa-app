import re

with open('E:/fastway/lib/core/api/local_database.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "couponDiscount = 50;" in line:
        lines[i+1] = '        savingsMessage = "تم تطبيق خصم 50 ر.س بنجاح!";\n'
        break

with open('E:/fastway/lib/core/api/local_database.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)
print("Done")
