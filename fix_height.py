import re
import glob

files = [
    'lib/features/wishlist/presentation/widgets/cart_wishlist_reminder.dart',
    'lib/features/wishlist/presentation/view/wishlist_screen.dart',
    'lib/core/responsive/responsive_grid.dart',
    'lib/features/product_details/presentation/view/web/product_details_web.dart',
    'lib/features/cart/presentation/view/cart_screen.dart',
    'lib/features/search/presentation/view/search_sheet.dart',
    'lib/features/brand/presentation/screens/brand_screen.dart',
    'lib/features/home/presentation/view/products_list_screen.dart',
    'lib/features/home/presentation/view/home_tab_screen.dart'
]

for f in files:
    with open(f, 'r') as file:
        content = file.read()
    
    # replace 360 with 346
    content = re.sub(r'mainAxisExtent: 360', 'mainAxisExtent: 346', content)
    content = re.sub(r'this\.mainAxisExtent = 360', 'this.mainAxisExtent = 346', content)

    with open(f, 'w') as file:
        file.write(content)
