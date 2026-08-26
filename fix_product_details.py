import re

files = [
    'lib/features/product_details/presentation/view/mobile/product_details_mobile.dart',
    'lib/features/product_details/presentation/view/web/product_details_web.dart'
]

for f in files:
    with open(f, 'r') as file:
        content = file.read()
    
    # Only remove if it's p.hasPromotion or p.promotionEndsAt (which is exactly what ProductCard uses in these files)
    content = re.sub(r'\s*hasPromotion:\s*p\.hasPromotion,?', '', content)
    content = re.sub(r'\s*promotionEndsAt:\s*p\.promotionEndsAt,?', '', content)

    with open(f, 'w') as file:
        file.write(content)
