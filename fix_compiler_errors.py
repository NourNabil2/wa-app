import re
import glob

files = [
    'lib/features/wishlist/presentation/view/wishlist_screen.dart',
    'lib/features/home/presentation/view/products_list_screen.dart',
    'lib/features/search/presentation/view/search_sheet.dart',
    'lib/features/brand/presentation/screens/brand_screen.dart',
    'lib/features/wishlist/presentation/widgets/cart_wishlist_reminder.dart',
    'lib/features/home/presentation/view/home_tab_screen.dart',
    'lib/features/product_details/presentation/view/web/product_details_web.dart',
    'lib/features/product_details/presentation/view/mobile/product_details_mobile.dart',
    'lib/features/home/presentation/widget/card/products_row.dart',
    'lib/features/home/presentation/widget/card/product_card.dart'
]

for f in files:
    try:
        with open(f, 'r') as file:
            content = file.read()
            
        # For the ProductCard callers, remove the parameters
        if f != 'lib/features/home/presentation/widget/card/product_card.dart':
            content = re.sub(r'^\s*hasPromotion:\s*.*?,?\n', '', content, flags=re.MULTILINE)
            content = re.sub(r'^\s*promotionEndsAt:\s*.*?,?\n', '', content, flags=re.MULTILINE)
            content = re.sub(r'^\s*requiresColdShipping:\s*.*?,?\n', '', content, flags=re.MULTILINE)
            # Only remove expiryDate: if it's inside ProductCard or similar. In product_details_web it's used in _ExpiryBadge.
            # We will use a more targeted regex for expiryDate in callers:
            content = re.sub(r'^\s*expiryDate:\s*p\.expiryDate,?\n', '', content, flags=re.MULTILINE)
            content = re.sub(r'^\s*expiryDate:\s*item\.expiryDate,?\n', '', content, flags=re.MULTILINE)
            content = re.sub(r'^\s*expiryDate:\s*product\.expiryDate,?\n', '', content, flags=re.MULTILINE)

        with open(f, 'w') as file:
            file.write(content)
    except Exception as e:
        print(f"Error processing {f}: {e}")
