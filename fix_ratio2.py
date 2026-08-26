files = [
    'lib/core/responsive/responsive_grid.dart',
    'lib/features/home/presentation/view/home_tab_screen.dart',
    'lib/features/home/presentation/view/products_list_screen.dart',
    'lib/features/brand/presentation/screens/brand_screen.dart',
    'lib/features/search/presentation/view/search_sheet.dart',
    'lib/features/cart/presentation/view/cart_screen.dart',
    'lib/features/product_details/presentation/view/web/product_details_web.dart',
    'lib/features/wishlist/presentation/view/wishlist_screen.dart',
    'lib/features/wishlist/presentation/widgets/cart_wishlist_reminder.dart',
]
for f in files:
    with open(f, 'r') as file:
        content = file.read()
    content = content.replace('childAspectRatio: 0.54', 'childAspectRatio: 0.52')
    content = content.replace('this.childAspectRatio = 0.54', 'this.childAspectRatio = 0.52')
    with open(f, 'w') as file:
        file.write(content)
print("Done")
