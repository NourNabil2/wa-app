// lib/features/checkout/presentation/widgets/order_summary_card.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/services/app_settings_service.dart';
import 'package:fastway/core/utils/app_size.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/sar_symbol.dart';
import '../../../../core/widgets/selectable.dart';

/// Order Summary Card — shows the full price breakdown.
///
/// VAT policy: prices are VAT-INCLUSIVE (e.g. product shows 115 SAR).
/// Row order: Subtotal (excl. VAT) → Shipping (excl. VAT) → VAT → Discounts → Total
/// The VAT line sits directly BELOW the two ex-VAT lines it is charged on, so the
/// breakdown reads top-to-bottom as: what you're buying, what delivery costs, the
/// tax on both, then the total.
///
/// The delivery fee is VAT-inclusive too — a 25 SAR delivery is 21.74 + 3.26 VAT —
/// so once a shipping method is chosen the VAT covers goods AND delivery. When
/// [serverVatAmount] is supplied (from /checkout/quote) it is used verbatim: the
/// app must never do tax arithmetic of its own, or the screen will quote a
/// different VAT than the invoice. The shipping row then shows the fee EX-VAT, so
/// the rows still add up to the total (excl-VAT lines + one VAT line).
/// [serverVatAmount] is null until a method is picked; we fall back to the old
/// goods-only extraction, which is correct at that point (there is no fee yet).
class OrderSummaryCard extends StatelessWidget {
  final double itemsTotal;
  /// GAP-39: coupon-only SAR discount (separate line from points)
  final double? couponDiscount;

  /// Loyalty-tier discount (e.g. أسطورة −5%), shown on its own line so the
  /// customer can see the benefit rather than an unexplained smaller total.
  final double? tierDiscount;
  final double? discountAmount;   // legacy fallback — used if couponDiscount null
  final double shippingCost;
  /// vatAmount kept for API compat but we recompute visually from itemsTotal
  final double vatAmount;
  /// Authoritative VAT from the server for the CHOSEN shipping method — covers
  /// goods + delivery. When set, it wins over any local extraction.
  final double? serverVatAmount;
  /// The delivery fee with its own VAT removed. Required whenever
  /// [serverVatAmount] is set, so the breakdown still sums to the total.
  final double? shippingExclVat;
  final double vatRate;
  final bool vatEnabled;
  final double total;
  final int earnedPoints;

  // Points slider support
  final int pointsToUse;
  final int pointsRate; // 100 points = 1 SAR by default

  /// Real-money wallet amount applied to this order (SAR). Shown as its own
  /// "Wallet applied −X" line; the grand total passed in is already net of it.
  final double walletApplied;

  // Free shipping progress
  final double freeShippingThreshold;
  final bool freeShippingQualifies;
  final String? freeShippingMessage;

  /// When true, shipping cost is displayed with strikethrough + FREE badge
  final bool isFreeShipping;
  /// The original (non-discounted) shipping cost — used for strikethrough display
  /// when isFreeShipping=true because the free threshold was met.
  final double? originalShippingCost;
  final bool isExpanded;


  const OrderSummaryCard({
    super.key,
    required this.itemsTotal,
    this.couponDiscount,
    this.tierDiscount,
    this.discountAmount,
    this.shippingCost = 0,
    this.originalShippingCost,
    this.vatAmount = 0,
    this.serverVatAmount,
    this.shippingExclVat,
    this.vatRate = 0,
    this.vatEnabled = false,
    required this.total,
    required this.earnedPoints,
    this.pointsToUse = 0,
    this.pointsRate = 100,
    this.walletApplied = 0,
    this.freeShippingThreshold = 0,
    this.freeShippingQualifies = false,
    this.freeShippingMessage,
    this.isFreeShipping = false,
    this.isExpanded = true,
  });


  /// Points discount in SAR: pointsToUse ÷ pointsRate
  double get _pointsDiscountSar =>
      pointsToUse > 0 ? pointsToUse / pointsRate : 0.0;

  /// The effective coupon discount to show
  double get _effectiveCouponDiscount =>
      couponDiscount ?? discountAmount ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final v = AppSizeVertical.instance;
    final h = AppSizeHorizontal.instance;
    final t = TextSizeApp.instance;

    // ── Visual VAT extraction (prices are VAT-inclusive) ──────────────────
    final bool showVat = AppSettingsService.instance.vatEnabled || vatEnabled || vatRate > 0;
    final double effectiveRate = vatRate > 0 ? vatRate : AppSettingsService.instance.vatRate;
    final double subtotalExclVat = showVat && effectiveRate > 0
        ? itemsTotal / (1 + effectiveRate / 100)
        : itemsTotal;
    final double localVat = showVat ? itemsTotal - subtotalExclVat : 0.0;

    // The server's figure wins whenever we have it — it is the same number the
    // order will be charged with, delivery VAT included.
    final double computedVat = serverVatAmount ?? localVat;
    // …and if it is in play, the fee must be shown ex-VAT or the rows over-count
    // the delivery VAT (once inside the fee, once in the VAT line).
    final bool   useServerVat  = serverVatAmount != null;
    final double shippingShown = useServerVat ? (shippingExclVat ?? shippingCost) : shippingCost;

    return Selectable(
      child: Container(
      padding: EdgeInsets.all(h.s16),
      decoration: BoxDecoration(
        color: ColorsManager.inputSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.defaultText.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'cart.orderSummary'.tr(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: t.s16,
              fontWeight: FontWeight.bold,
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Column(
                    children: [
                      SizedBox(height: v.s16),

          // ── Free-shipping progress bar ────────────────────────────────
          if (freeShippingThreshold > 0 && !freeShippingQualifies) ...[
            Container(
              padding: EdgeInsets.all(h.s12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (itemsTotal / freeShippingThreshold).clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.shade200,
                        color: ColorsManager.primaryColor,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  SizedBox(height: v.s8),
                  Text(
                    freeShippingMessage ??
                        'checkout.freeShippingNudge'.tr(namedArgs: {
                          'amount': (freeShippingThreshold - itemsTotal)
                              .toStringAsFixed(0),
                        }),
                    style: TextStyle(
                      fontSize: t.s12,
                      color: ColorsManager.defaultTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: v.s12),
          ],

          // ── 1. Subtotal (excl. VAT) ───────────────────────────────────
          _SummaryRow(
            label: 'checkout.subtotal_products'.tr(),
            valueWidget: SarText(
              price: subtotalExclVat.toStringAsFixed(2),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: t.s14,
                color: ColorsManager.defaultTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // ── 2. Shipping (ex-VAT once a method is chosen) ──────
          () {
            final realCost = originalShippingCost ?? shippingCost;
            if (isFreeShipping && realCost > 0) {
              // Strikethrough original cost + FREE badge
              return Padding(
                padding: EdgeInsets.only(bottom: v.s10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'orders.summary.shipping'.tr(),
                          style: TextStyle(
                            fontSize: t.s14,
                            color: ColorsManager.defaultTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        SarText(
                          price: realCost.toStringAsFixed(2),
                          strikeThrough: true,
                          style: TextStyle(
                            fontSize: t.s12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    // Right: FREE badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ColorsManager.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'checkout.free'.tr(),
                        style: TextStyle(
                          fontSize: t.s12,
                          fontWeight: FontWeight.bold,
                          color: ColorsManager.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return _SummaryRow(
              label: useServerVat && shippingShown > 0
                  ? 'checkout.shipping_excl_vat'.tr()
                  : 'orders.summary.shipping'.tr(),
              value: shippingShown == 0 ? 'checkout.free'.tr() : null,
              valueWidget: shippingShown == 0
                  ? null
                  : SarText(
                      price: shippingShown.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: t.s14,
                        color: ColorsManager.defaultTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
              valueColor: shippingShown == 0
                  ? ColorsManager.primaryColor
                  : ColorsManager.defaultTextSecondary,
            );
          }(),

          // ── 3. VAT — sits BELOW the two ex-VAT lines it is charged on.
          // Once a shipping method is picked the server's VAT covers goods AND the
          // delivery fee, so say so; before that (and in the cart) it is goods-only.
          if (showVat && computedVat > 0)
            _SummaryRow(
              label: effectiveRate > 0
                  ? (useServerVat && shippingShown > 0
                      ? 'checkout.vat_incl_shipping'.tr(namedArgs: {'rate': effectiveRate.toStringAsFixed(0)})
                      : 'checkout.vat'.tr(namedArgs: {'rate': effectiveRate.toStringAsFixed(0)}))
                  : 'product.vat_inclusive'.tr(),
              valueWidget: SarText(
                price: computedVat.toStringAsFixed(2),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: t.s14,
                  color: ColorsManager.defaultTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),


          // ── 4. Coupon discount ────────────────────────────────────────
          if (_effectiveCouponDiscount > 0)
            _SummaryRow(
              label: 'cart.discount'.tr(),
              valueWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('- ', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: t.s14, color: ColorsManager.errorFill, fontWeight: FontWeight.w500)),
                  SarText(
                    price: _effectiveCouponDiscount.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: t.s14,
                      color: ColorsManager.errorFill,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // ── 4b. Loyalty tier discount ─────────────────────────────────
          if ((tierDiscount ?? 0) > 0)
            _SummaryRow(
              label: 'checkout.tier_discount'.tr(),
              valueWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('- ', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: t.s14, color: ColorsManager.errorFill, fontWeight: FontWeight.w500)),
                  SarText(
                    price: tierDiscount!.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: t.s14,
                      color: ColorsManager.errorFill,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // ── 5. Points discount ────────────────────────────────────────
          if (_pointsDiscountSar > 0)
            _SummaryRow(
              label: 'checkout.points_discount'.tr(),
              valueWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('- ', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: t.s14, color: Colors.amber.shade700, fontWeight: FontWeight.w500)),
                  SarText(
                    price: _pointsDiscountSar.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: t.s14,
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              trailingBadge: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, size: 12, color: Colors.amber),
                    const SizedBox(width: 3),
                    Text(
                      '$pointsToUse',
                      style: TextStyle(
                        fontSize: t.s10,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── 5b. Wallet applied (real-money tender) ────────────────────
          if (walletApplied > 0)
            _SummaryRow(
              label: 'wallet.applied_summary'.tr(),
              valueWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('- ', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: t.s14, color: ColorsManager.primary2Color, fontWeight: FontWeight.w500)),
                  SarText(
                    price: walletApplied.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: t.s14,
                      color: ColorsManager.primary2Color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              trailingBadge: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ColorsManager.primary2Color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.account_balance_wallet_rounded,
                    size: 12, color: ColorsManager.primary2Color),
              ),
            ),

          // ── 6. Points to earn ─────────────────────────────────────────
          if (earnedPoints > 0)
            _SummaryRow(
              label: 'cart.points'.tr(),
              value: '+$earnedPoints ${'cart.point'.tr()}',
              valueColor: ColorsManager.primaryColor,
            ),

          Divider(height: v.s24, color: ColorsManager.backgroundCard),

          // ── 7. Grand total ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'cart.total'.tr(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: t.s16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SarText(
                price: total.toStringAsFixed(2),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: t.s18,
                  fontWeight: FontWeight.bold,
                  color: ColorsManager.primaryColor,
                ),
              ),
            ],
          ),

          // ── "Prices incl. VAT" badge ──────────────────────────────────
          if (showVat) ...[
            SizedBox(height: v.s4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'product.vat_inclusive'.tr(),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      )
    : const SizedBox(width: double.infinity),
  ),
],
      ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final Color? valueColor;
  final Widget? trailingBadge;

  const _SummaryRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.valueColor,
    this.trailingBadge,
  });

  @override
  Widget build(BuildContext context) {
    final v = AppSizeVertical.instance;
    final t = TextSizeApp.instance;

    return Padding(
      padding: EdgeInsets.only(bottom: v.s10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Left: label ───────────────────────────────
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: t.s14,
                color: ColorsManager.defaultTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // ── Right: value + optional badge ──────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingBadge != null) ...[
                trailingBadge!,
                const SizedBox(width: 6),
              ],
              if (valueWidget != null) valueWidget! else if (value != null)
              Text(
                value!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: t.s14,
                  color: valueColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}