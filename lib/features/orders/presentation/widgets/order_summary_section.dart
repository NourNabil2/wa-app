// lib/features/orders/presentation/widgets/order_summary_section.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/services/app_settings_service.dart';
import 'package:fastway/core/widgets/sar_symbol.dart';
import 'package:fastway/core/widgets/selectable.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../domain/entities/order_entity.dart';

class OrderSummarySection extends StatelessWidget {
  final OrderEntity order;

  const OrderSummarySection({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── VAT extraction — prices are VAT-INCLUSIVE (same logic as cart/checkout) ──
    final double effectiveRate = AppSettingsService.instance.vatRate > 0
        ? AppSettingsService.instance.vatRate
        : 15.0; // fallback: Saudi standard rate
    final bool showVat = AppSettingsService.instance.vatVisible || effectiveRate > 0;

    final double subtotalExclVat = showVat && effectiveRate > 0
        ? order.subtotal / (1 + effectiveRate / 100)
        : order.subtotal;
    final double extractedVat = showVat ? order.subtotal - subtotalExclVat : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorsManager.surfaceDarkCard : ColorsManager.inputSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorsManager.inputBorder.withValues(alpha: 0.2)),
      ),
      child: Selectable(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'orders.summary.title'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorsManager.defaultText,
            ),
          ),
          const SizedBox(height: 16),

          // ── 1. Subtotal (excl. VAT) ──────────────────────────────────────
          _SummaryRow(
            label: 'orders.summary.subtotal'.tr(),
            valueWidget: SarText(price: subtotalExclVat.toStringAsFixed(2)),
          ),
          const SizedBox(height: 8),

          // ── 2. VAT (extracted from inclusive price) ──────────────────────
          if (showVat && extractedVat > 0) ...[
            _SummaryRow(
              label: 'checkout.vat'.tr(namedArgs: {'rate': effectiveRate.toStringAsFixed(0)}),
              valueWidget: SarText(price: extractedVat.toStringAsFixed(2)),
            ),
            const SizedBox(height: 8),
          ],

          // ── 3. Shipping ──────────────────────────────────────────────────
          _SummaryRow(
            label: 'orders.summary.shipping'.tr(),
            valueWidget: order.shippingCost == 0
                ? Text(
                    'orders.summary.free_shipping'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ColorsManager.successText,
                    ),
                  )
                : SarText(price: order.shippingCost.toStringAsFixed(2)),
          ),
          const SizedBox(height: 8),

          // ── 4. Items count ───────────────────────────────────────────────
          _SummaryRow(
            label: 'orders.summary.items_count'.tr(),
            valueWidget: Text(
              '${order.itemCount}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorsManager.defaultText,
              ),
            ),
          ),

          const Divider(height: 24, color: Color(0x33000000)),

          // ── 5. Coupon discount ───────────────────────────────────────────
          if (order.couponDiscount > 0) ...[
            _SummaryRow(
              label: 'checkout.coupon'.tr(),
              valueWidget: SarText(
                price: '−${order.couponDiscount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── 5b. Loyalty tier discount ────────────────────────────────────
          if (order.tierDiscount > 0) ...[
            _SummaryRow(
              label: 'checkout.tier_discount'.tr(),
              valueWidget: SarText(
                price: '−${order.tierDiscount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── 6. Points discount ───────────────────────────────────────────
          if (order.pointsDiscount > 0) ...[
            _SummaryRow(
              label: 'checkout.points_redeemed'.tr(),
              valueWidget: SarText(
                price: '−${order.pointsDiscount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── 7. Wallet deduction ──────────────────────────────────────────
          // walletPaid > 0 means part/all of the order was covered by wallet.
          // Show it as a line so users can see their money wasn't hidden.
          if (order.walletPaid > 0) ...[
            _SummaryRow(
              label: 'wallet.checkout_use'.tr(),
              valueWidget: SarText(
                price: '−${order.walletPaid.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED)),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── 8. Grand Total ───────────────────────────────────────────────
          // Use grossTotal (= pre-wallet sale value) as the headline number.
          // For non-wallet orders grossTotal == total.
          _SummaryRow(
            label: 'orders.summary.total'.tr(),
            valueWidget: SarText(
              price: order.grossTotal.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ColorsManager.primaryColor,
              ),
            ),
            isTotal: true,
          ),
          // If the gateway was charged less than grossTotal (e.g. wallet covered the rest),
          // show a secondary "Paid online: SAR X" line so there's no confusion.
          if (order.walletPaid > 0 && order.total > 0) ...[
            const SizedBox(height: 6),
            _SummaryRow(
              label: 'orders.summary.paid_online'.tr(),
              valueWidget: SarText(
                price: order.total.toStringAsFixed(2),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ColorsManager.defaultTextSecondary),
              ),
            ),
          ],
        ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final Widget valueWidget;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.valueWidget,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15.0 : 14.0,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w400,
            color: isTotal ? ColorsManager.defaultText : ColorsManager.defaultTextSecondary,
          ),
        ),
        valueWidget,
      ],
    );
  }
}
