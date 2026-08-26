import re
import sys

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Add import if missing
    import_stmt = "import 'package:flutter_screenutil/flutter_screenutil.dart';"
    if import_stmt not in content:
        # insert after the first import
        content = re.sub(r'(import .*?;)', r'\1\n' + import_stmt, content, count=1)

    # replace fontSize: 14 with fontSize: 14.sp
    # be careful to not replace if already .sp
    content = re.sub(r'fontSize:\s*([0-9]+(\.[0-9]+)?)(?!\.sp)', r'fontSize: \1.sp', content)

    # add Flexible to originalPrice row in product_card _VCard and _Price
    content = content.replace("child: Text(\n                              '${'product.was'.tr()} ',", "child: Flexible(child: Text(\n                              '${'product.was'.tr()} ',")
    content = content.replace("child: SarText(\n                              price: originalPrice!.toStringAsFixed(2),", "child: Flexible(child: SarText(\n                              price: originalPrice!.toStringAsFixed(2),")

    # fix the closing parenthesis for Flexible
    # actually it's safer to just do a python script that accurately replaces text
    
    with open(filepath, 'w') as f:
        f.write(content)

process_file('lib/features/cart/presentation/widgets/cart_item_card.dart')
process_file('lib/features/home/presentation/widget/card/product_card.dart')

print("Done")
