// lib/features/orders/presentation/widgets/order_card.dart

import 'package:fastway/core/theme/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/widgets/sar_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/widgets/app_buton.dart';
import '../../../../core/widgets/custom_network_image.dart';
import '../../../../core/utils/assets.dart';
import '../../domain/entities/order_entity.dart';
import 'order_status_badge.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onTap;
  final VoidCallback onTrackOrder;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onTrackOrder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = context.locale.languageCode == 'ar';

    // إخفاء زر التتبع لو الطلب تم توصيله أو ملغي
    final bool canTrack = order.status != 'delivered' && order.status != 'cancelled';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Header (Order Number & Status & Date) ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tag_rounded, size: 14, color: ColorsManager.primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          order.orderNumber,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      DateFormat('dd MMM yyyy • hh:mm a').format(order.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    OrderStatusBadge(status: order.status),
                    if (order.shipmentProvider == 'express') ...[
                      SizedBox(height: 6.h),
                      SvgPicture.asset(
                        isAr ? Assets.shippingExpressAR : Assets.shippingExpress,
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ],
                ),
              ],
            ),

            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.grey.shade100),
            ),

            // ── 2. Body (Products Overlapping & Price) ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Overlapping Images
                if (order.items.isNotEmpty) _OverlappingProducts(items: order.items),

                // Total Price & Items count
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SarText(
                      price: order.total.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: ColorsManager.primaryColor,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${order.itemCount} ${'orders.items_count'.tr()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // ── 3. Footer (Action Buttons) ──
            Row(
              children: [
                Expanded(
                  child: AppOutlinedButton(
                    text: 'orders.view_details'.tr(),
                    onPressed: onTap,
                    borderRadius: 14.r,
                    verticalPadding: 12.h,

                  ),
                ),
                if (canTrack) ...[
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppButton(
                      text: 'orders.track'.tr(),
                      onPressed: onTrackOrder,
                      backgroundColor: ColorsManager.primary2Color,
                      borderRadius: 14.r,
                      verticalPadding: 12.h,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    )
    );
  }
}

// حركة إبداعية لعرض صور المنتجات راكبة فوق بعض بشكل فخم
class _OverlappingProducts extends StatelessWidget {
  final List<OrderItemEntity> items;

  const _OverlappingProducts({required this.items});

  @override
  Widget build(BuildContext context) {
    final displayItems = items.take(3).toList();
    final remainingCount = items.length - displayItems.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 46.r,
      // حساب العرض بناءً على التداخل
      width: (46.r * displayItems.length) - ((displayItems.length - 1) * 15.r) + (remainingCount > 0 ? 30.r : 0),
      child: Stack(
        children: [
          ...displayItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Positioned(
              left: index * 30.r, // مقدار التداخل بين الصور
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? ColorsManager.surfaceDarkCard : Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: CustomNetworkImage.rounded(
                    imageUrl: item.imageUrl,
                    width: 40.r,
                    height: 40.r,
                    borderRadius: 100.r,
                  ),
                ),
              ),
            );
          }),
          if (remainingCount > 0)
            Positioned(
              left: displayItems.length * 30.r,
              child: Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? ColorsManager.surfaceDarkCard : Colors.white, width: 2.5),
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}