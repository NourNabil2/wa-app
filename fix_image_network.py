import os
import re

dir_path = '/Users/yossefzaki/Desktop/ATW-Work/fastway/fastWay-mobile/lib'

files_to_fix = [
    '/Users/yossefzaki/Desktop/ATW-Work/fastway/fastWay-mobile/lib/core/widgets/full_screen_media_viewer.dart',
    '/Users/yossefzaki/Desktop/ATW-Work/fastway/fastWay-mobile/lib/core/layout/web_shell.dart',
    '/Users/yossefzaki/Desktop/ATW-Work/fastway/fastWay-mobile/lib/features/orders/presentation/widgets/return_request_sheet.dart',
    '/Users/yossefzaki/Desktop/ATW-Work/fastway/fastWay-mobile/lib/features/product_details/presentation/view/mobile/product_details_mobile.dart',
    '/Users/yossefzaki/Desktop/ATW-Work/fastway/fastWay-mobile/lib/features/orders/presentation/widgets/return_status_modal.dart',
    '/Users/yossefzaki/Desktop/ATW-Work/fastway/fastWay-mobile/lib/features/orders/presentation/screens/order_tracking_screen.dart',
    '/Users/yossefzaki/Desktop/ATW-Work/fastway/fastWay-mobile/lib/features/checkout/presentation/widgets/shipping_method_picker.dart',
    '/Users/yossefzaki/Desktop/ATW-Work/fastway/fastWay-mobile/lib/features/checkout/presentation/view/checkout_screen.dart'
]

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Need to add import 'package:cached_network_image/cached_network_image.dart';
    if "import 'package:cached_network_image/cached_network_image.dart';" not in content:
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:cached_network_image/cached_network_image.dart';")
    
    # Replace Image.network(url, ...) with CachedNetworkImage(imageUrl: url, ...)
    # Wait, regular expressions can be tricky if there are multiple lines.
    # It's better to replace 'Image.network(' with 'CachedNetworkImage(imageUrl: '
    # But wait, Image.network might have a named parameter 'fit', but its first parameter is positional (the url).
    # CachedNetworkImage takes 'imageUrl: ' instead.
    # We can do this simply with:
    # re.sub(r'Image\.network\(\s*([^,\n\)]+)', r'CachedNetworkImage(imageUrl: \1', content)
    
    # Let's test a sample replacement.
    content = re.sub(r'Image\.network\(\s*([^,\n\)]+)', r'CachedNetworkImage(imageUrl: \1', content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for file in files_to_fix:
    fix_file(file)
    print(f"Fixed {file}")
