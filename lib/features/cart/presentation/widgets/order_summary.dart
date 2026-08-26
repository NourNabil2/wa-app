// lib/features/cart/presentation/widgets/order_summary.dart

import 'package:fastway/core/theme/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/sar_symbol.dart';
import '../../../../core/widgets/loyalty_points_bar.dart';
import '../../domain/entities/cart_entity.dart';

class OrderSummary extends StatelessWidget {
  final CartEntity cart;
  final Widget? couponWidget;

  const OrderSummary({super.key, required this.cart, this.couponWidget});

  @override
  Widget build(BuildContext context) {
    final h = AppSizeHorizontal.instance;
    final v = AppSizeVertical.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? ColorsManager.surfaceDarkCard : Colors.white;

    return Container(
      padding: EdgeInsets.all(h.s16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
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
          Text(
            'cart.order_summary'.tr(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : ColorsManager.defaultText,
            ),
          ),
          SizedBox(height: v.s16),

          // ── Visual VAT breakdown (prices are inclusive) ──────────────────
          Builder(builder: (context) {
            final vatEnabled  = AppSettingsService.instance.vatEnabled;
            final vatRate     = AppSettingsService.instance.vatRate; // e.g. 15.0
            // Must mirror the server: the tier discount reduces the taxable base
            // exactly like the coupon does.
            final taxable     = cart.subtotal - (cart.couponDiscount ?? 0) - (cart.tierDiscount ?? 0);
            // Extract VAT from inclusive price: excl = incl / (1 + rate/100)
            final exclVat     = vatEnabled ? taxable / (1 + vatRate / 100) : taxable;
            final vatAmount   = vatEnabled ? taxable - exclVat : 0.0;

            return Column(
              children: [
                // 1. Products subtotal (ex-VAT)
                _SummaryRow(
                  label: 'cart.subtotal'.tr(),
                  valueWidget: SarText(
                    price: exclVat.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.normal,
                      color: isDark ? Colors.white : ColorsManager.defaultText,
                    ),
                  ),
                ),
                SizedBox(height: v.s10),

                if (couponWidget != null) ...[
                  SizedBox(height: v.s6),
                  couponWidget!,
                  SizedBox(height: v.s16),
                ],

                // 2. VAT line (only when VAT enabled)
                if (vatEnabled) ...[
                  _SummaryRow(
                    label: 'cart.summary.vat'.tr(args: [vatRate.toStringAsFixed(0)]),
                    valueWidget: SarText(
                      price: vatAmount.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  SizedBox(height: v.s10),
                ],

                // 3. Coupon discount
                if (cart.couponDiscount != null && cart.couponDiscount! > 0) ...[
                  _SummaryRow(
                    label: 'cart.coupon_discount'.tr(),
                    valueWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('-', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 14.sp, fontWeight: FontWeight.normal, color: ColorsManager.successFill)),
                        SarText(
                          price: cart.couponDiscount!.toStringAsFixed(2),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.normal,
                            color: ColorsManager.successFill,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: v.s10),
                ],

                // 3b. Loyalty tier discount
                if (cart.tierDiscount != null && cart.tierDiscount! > 0) ...[
                  _SummaryRow(
                    label: 'cart.tier_discount'.tr(),
                    valueWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('-', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 14.sp, fontWeight: FontWeight.normal, color: ColorsManager.successFill)),
                        SarText(
                          price: cart.tierDiscount!.toStringAsFixed(2),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.normal,
                            color: ColorsManager.successFill,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: v.s10),
                ],

                // 4. Points discount
                if (cart.pointsDiscount != null && cart.pointsDiscount! > 0) ...[
                  _SummaryRow(
                    label: 'cart.summary.points_discount'.tr(args: [cart.pointsUsed.toString()]),
                    valueWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('-', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 14.sp, fontWeight: FontWeight.normal, color: ColorsManager.primaryColor)),
                        SarText(
                          price: cart.pointsDiscount!.toStringAsFixed(2),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.normal,
                            color: ColorsManager.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: v.s10),
                ],

                // 5. Total Savings
                if (cart.totalSavings > 0) ...[
                  SizedBox(height: v.s4),
                  _SummaryRow(
                    label: '${'cart.savings_banner_prefix'.tr()}${'cart.savings_banner_suffix'.tr()}',
                    valueWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('- ', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 14.sp, fontWeight: FontWeight.normal, color: ColorsManager.errorFill)),
                        SarText(
                          price: cart.totalSavings.toStringAsFixed(2),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.normal,
                            color: ColorsManager.errorFill,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: v.s10),
                ],
              ],
            );
          }),

          // ── Dashed Divider ──
          const _DashedDivider(),

          // ── Total ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'cart.total'.tr(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.normal,
                  color: isDark ? Colors.white : ColorsManager.defaultText,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SarText(
                    price: cart.total.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.normal,
                      color: ColorsManager.primaryColor,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'product.vat_inclusive'.tr(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 11.sp,
                      color: isDark ? Colors.grey[500] : ColorsManager.defaultTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Points Earned Creative Box ──────────────────────────
          if (cart.pointsEarned > 0) ...[
            SizedBox(height: v.s20),
            LoyaltyPointsBar(
              bonusPercent: cart.tierBonusPercent,
              points: cart.pointsEarned,
              titleOverride: 'cart.summary.points_earned'.tr(),
              subtitleOverride: 'cart.summary.points_added_after_delivery'.tr(),
            ),
          ]
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final Color? valueColor;

  const _SummaryRow({required this.label, this.value, this.valueWidget, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 14.sp,
            color: isDark ? Colors.grey[400] : ColorsManager.defaultTextSecondary,
            fontWeight: FontWeight.normal,
          ),
        ),
        if (valueWidget != null) valueWidget! else if (value != null)
        Text(
          value!,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.normal,
            color: valueColor ?? (isDark ? Colors.white : ColorsManager.defaultText),
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 6.0;
          const dashHeight = 1.5;
          final dashCount = (boxWidth / (2 * dashWidth)).floor();
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: dashHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey[300]),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}