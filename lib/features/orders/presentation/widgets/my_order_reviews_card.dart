// lib/features/orders/presentation/widgets/my_order_reviews_card.dart
//
// Shows the current user's own submitted reviews for a delivered order:
// store, shipment, and per-item. Each review is visible to its author even
// while still pending admin approval, and surfaces the admin's reply (if any).
//
// This is the read-back surface that complements RateOrderSheet (the write
// surface). Without it the user has no way to see a review once submitted,
// because the "Rate your order" button hides reviewed sections.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../domain/entities/order_entity.dart';

class MyOrderReviewsCard extends StatelessWidget {
  final OrderEntity order;
  const MyOrderReviewsCard({super.key, required this.order});

  bool get _hasAny {
    if (order.storeReview != null) return true;
    if (order.shipmentReview != null) return true;
    return order.items.any((i) => i.review != null);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAny) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reviewedItems = order.items.where((i) => i.review != null).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorsManager.inputBorder.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rate_review_outlined, size: 18, color: Color(0xFFFBBF24)),
              const SizedBox(width: 8),
              Text(
                'orders.rate_order.my_reviews_title'.tr(),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (order.storeReview != null)
            _ReviewTile(
              label: 'orders.rate_order.store'.tr(),
              rating: order.storeReview!.rating,
              comment: order.storeReview!.comment,
              isApproved: order.storeReview!.isApproved,
              adminReply: order.storeReview!.adminReply,
            ),

          if (order.shipmentReview != null)
            _ReviewTile(
              label: 'orders.rate_order.shipment'.tr(),
              rating: order.shipmentReview!.rating,
              comment: order.shipmentReview!.comment,
              isApproved: order.shipmentReview!.isApproved,
              adminReply: order.shipmentReview!.adminReply,
            ),

          ...reviewedItems.map((item) => _ReviewTile(
                label: item.name,
                rating: item.review!.rating,
                comment: item.review!.comment,
                isApproved: item.review!.isApproved,
                adminReply: item.review!.adminReply,
              )),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final String label;
  final int rating;
  final String? comment;
  final bool isApproved;
  final String? adminReply;

  const _ReviewTile({
    required this.label,
    required this.rating,
    required this.comment,
    required this.isApproved,
    required this.adminReply,
  });

  @override
  Widget build(BuildContext context) {
    final hasReply = adminReply != null && adminReply!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              _StatusChip(isApproved: isApproved),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                size: 18,
                color: const Color(0xFFFBBF24),
              ),
            ),
          ),
          if (comment != null && comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(comment!, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          ],
          if (hasReply) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ColorsManager.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ColorsManager.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storefront_outlined, size: 14, color: ColorsManager.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        'orders.rate_order.admin_reply_label'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ColorsManager.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(adminReply!, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isApproved;
  const _StatusChip({required this.isApproved});

  @override
  Widget build(BuildContext context) {
    final color = isApproved ? Colors.green : Colors.amber;
    final label = isApproved
        ? 'orders.rate_order.status_published'.tr()
        : 'orders.rate_order.status_pending'.tr();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isApproved ? Icons.check_circle_outline : Icons.hourglass_top_rounded,
            size: 12,
            color: isApproved ? Colors.green.shade700 : Colors.amber.shade800,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isApproved ? Colors.green.shade800 : Colors.amber.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
