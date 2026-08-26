// lib/features/product_details/presentation/widgets/product_info_section.dart

import 'package:fastway/core/utils/assets.dart';
import 'package:fastway/core/widgets/CustomIcon.dart';
import 'package:fastway/core/widgets/custom_lottie_icon.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/colors.dart';
import 'package:fastway/features/home/presentation/widget/card/product_countdown_timer.dart';
import 'package:fastway/core/widgets/sar_symbol.dart';

import 'package:fastway/core/widgets/discount_badge.dart';

class ProductInfoSection extends StatelessWidget {
  final String name;
  final String brand;
  final double price;
  final double? originalPrice;
  final double? rating;
  final int? reviewCount;
  final bool isAvailable;
  final bool isNew;
  final bool isExpressEligible;
  final bool isFeatured;
  final String? stockWarning;
  final int? pointsToEarn;
  final int? discountPercent;
  final bool hasPromotion;
  final String? promotionEndsAt;
  final bool requiresColdShipping;
  final String? expiryDate;
  final VoidCallback? onRatingTap;

  const ProductInfoSection({
    super.key,
    required this.name,
    required this.brand,
    required this.price,
    this.originalPrice,
    this.rating,
    this.reviewCount,
    required this.isAvailable,
    this.isNew = false,
    this.isExpressEligible = false,
    this.isFeatured = false,
    this.stockWarning,
    this.pointsToEarn,
    this.discountPercent,
    this.hasPromotion = false,
    this.promotionEndsAt,
    this.requiresColdShipping = false,
    this.expiryDate,
    this.onRatingTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Product Badges (Chips) ──
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [



            // Special Offer Badge
            if (hasPromotion)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade500,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'product.badge_special_offer'.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),

            // Stock Warning
            if (stockWarning == 'low' || stockWarning == 'veryLow')
              _buildChip(
                  icon: Assets.warningIcon,
                  label: stockWarning == 'low' ? 'product.stockWarning.low'.tr() : 'product.stockWarning.veryLow'.tr(),
                  color: ColorsManager.errorFill,
                  bgColor: ColorsManager.errorFill.withValues(alpha: 0.1),
                  isLottie: false
              ),
          ],
        ),

        const SizedBox(height: 12),

        // ── 2. Product Name ──
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.normal,
            color: cs.onSurface,
            height: 1.3,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),

        // ── Rating ──
        GestureDetector(
          onTap: onRatingTap,
          child: Builder(
            builder: (context) {
              final r = rating ?? 0.0;
              final filled = r.floor();
              final partial = r - filled;
              final empty = 5 - filled - (partial > 0.1 ? 1 : 0);
              final isClickable = onRatingTap != null;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (reviewCount != null) ...[
                    Text(
                      '($reviewCount)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: isClickable ? TextDecoration.underline : null,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    r.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      decoration: isClickable ? TextDecoration.underline : null,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  ...List.generate(filled,
                      (_) => const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFBBF24))),
                  if (partial > 0.1)
                    const Icon(Icons.star_half_rounded, size: 16, color: Color(0xFFFBBF24)),
                  ...List.generate(empty > 0 ? empty : 0,
                      (_) => Icon(Icons.star_outline_rounded, size: 16, color: Colors.grey.shade300)),
                ],
              );
            }
          ),
        ),

        const SizedBox(height: 24),

        // ── 3. السعر وحالة التوفر ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SarText(
              price: price.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.normal,
                color: ColorsManager.primaryColor,
                height: 1,
              ),
            ),
            if (originalPrice != null && originalPrice! > price) ...[
              const SizedBox(width: 8),
              SarText(
                price: originalPrice!.toStringAsFixed(2),
                strikeThrough: false,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ),
              const SizedBox(width: 8),
              if (discountPercent != null && discountPercent! > 0)
                DiscountBadge(percent: discountPercent!, scale: 1.2),
            ],

            const Spacer(),

            if (isExpressEligible)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MobileExpressBadge(),
              ),
          ],
        ),

        const SizedBox(height: 4),
        Text(
          'product.vat_inclusive'.tr(),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),

        if (hasPromotion && promotionEndsAt != null) ...[
          const SizedBox(height: 8),
          ProductCountdownTimer(endsAt: DateTime.parse(promotionEndsAt!)),
        ],


      ],
    );
  }

  Widget _buildChip({
    required String icon,
    required String label,
    required Color color,
    required Color bgColor,
    required bool isLottie,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          !isLottie ? CustomIcon(assetPath: icon, size: 14,noColor: true,)
              : CustomLottieIcon(assetPath: icon,height: 14,width: 14,),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileExpressBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isAr = locale == 'ar';
    return SvgPicture.asset(
      isAr ? Assets.shippingExpressAR : Assets.shippingExpress,
      height: 28,
    );
  }
}