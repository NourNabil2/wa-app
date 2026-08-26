// lib/features/orders/presentation/widgets/order_product_item.dart

import 'package:fastway/core/routes/app_navigator.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/utils/slug_utils.dart';
import 'package:fastway/core/widgets/sar_symbol.dart';
import 'package:fastway/core/responsive/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/custom_network_image.dart';
import '../../domain/entities/order_entity.dart';

class OrderProductItem extends StatelessWidget {
  final OrderItemEntity item;

  const OrderProductItem({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final isWeb = isWebLayout(context);
    final imgSize = isWeb ? 64.0 : 70.w;
    final nameFontSize = isWeb ? 14.0 : 14.sp;
    final priceFontSize = isWeb ? 13.0 : 13.sp;
    final qtyFontSize = isWeb ? 13.0 : 13.sp;
    final padding = isWeb ? 12.0 : 12.w;
    final gap = isWeb ? 12.0 : 12.w;

    return GestureDetector(
      onTap: () => AppNavigator.pushNamed(
        context,
        '${Routes.productDetails}/${SlugUtils.slugify(item.name, item.productId)}',
      ),
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: ColorsManager.defaultSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Product Image
            CustomNetworkImage.rounded(
              imageUrl: item.imageUrl,
              width: imgSize,
              height: imgSize,
              borderRadius: isWeb ? 8 : 8.r,
            ),
            SizedBox(width: gap),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: nameFontSize,
                      fontWeight: FontWeight.w600,
                      color: ColorsManager.defaultText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  SarText(
                    price: item.price.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: priceFontSize,
                      fontWeight: FontWeight.w600,
                      color: ColorsManager.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isWeb ? 12.0 : 12.w,
                vertical: isWeb ? 6.0 : 6.h,
              ),
              decoration: BoxDecoration(
                color: ColorsManager.inputSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: ColorsManager.inputBorder.withValues(alpha: 0.3)),
              ),
              child: Text(
                'x${item.quantity}',
                style: TextStyle(
                  fontSize: qtyFontSize,
                  fontWeight: FontWeight.w600,
                  color: ColorsManager.defaultText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
