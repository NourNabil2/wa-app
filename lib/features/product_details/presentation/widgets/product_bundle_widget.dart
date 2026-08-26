// lib/features/product_details/presentation/widgets/product_bundle_widget.dart

import 'dart:math' as math;
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/utils/assets.dart';
import 'package:fastway/core/utils/slug_utils.dart';
import 'package:fastway/core/widgets/custom_lottie_icon.dart';
import 'package:fastway/core/widgets/sar_symbol.dart';
import 'package:flutter/material.dart';
import 'package:fastway/core/widgets/custom_network_image.dart';
import 'package:easy_localization/easy_localization.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BUNDLE SECTION HEADER  — simple, modern, no containers
// ─────────────────────────────────────────────────────────────────────────────
class BundleSectionHeader extends StatelessWidget {
  final double savingsAmount;
  final String currencyLabel;

  const BundleSectionHeader({
    super.key,
    this.savingsAmount = 0,
    this.currencyLabel = 'SAR',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.layers_rounded,
          size: 18,
          color: primary,
        ),
        const SizedBox(width: 8),
        Text(
          'product.whats_inside'.tr(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        if (savingsAmount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: ColorsManager.primaryColor.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorsManager.primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CustomLottieIcon(assetPath: Assets.savingIcon,height: 20,width: 20,),
                const SizedBox(width: 4),
                Text(
                  'product.save_discount'.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: ColorsManager.primaryColor,
                  ),
                ),
                SarText(
                  price: savingsAmount.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: ColorsManager.primaryColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUNDLE WIDGET  — static elegant border
// ─────────────────────────────────────────────────────────────────────────────
class ProductBundleWidget extends StatelessWidget {
  final List<dynamic> components;
  const ProductBundleWidget({super.key, required this.components});

  @override
  Widget build(BuildContext context) {
    if (components.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primary.withValues(alpha: isDark ? 0.15 : 0.10),
          width: 1.5,
        ),
      ),
      child: _BundleItemList(
        components: components,
        isDark: isDark,
        primary: primary,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUNDLE ITEM LIST
// ─────────────────────────────────────────────────────────────────────────────
class _BundleItemList extends StatelessWidget {
  final List<dynamic> components;
  final bool isDark;
  final Color primary;

  const _BundleItemList({
    required this.components,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: components.asMap().entries.map((entry) {
        final index = entry.key;
        final c = entry.value;
        final isLast = index == components.length - 1;

        String name = '';
        int qty = 1;
        bool isAr = context.locale.languageCode == 'ar';
        try { 
          name = isAr ? (c.productNameAr ?? c.productName ?? '') : (c.productName ?? ''); 
        } catch (_) {
          try { 
            name = isAr ? (c.nameAr ?? c.name ?? '') : (c.name ?? ''); 
          } catch (_) {}
        }
        try { qty = c.quantity ?? 1; } catch (_) {}

        return Column(
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => AppNavigator.pushNamed(
                  context,
                  '${Routes.productDetails}/${SlugUtils.slugify(name, c.productId)}',
                ),
                child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    // thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CustomNetworkImage.rounded(
                        imageUrl: c.imageUrl ?? '',
                        width: 50,
                        height: 50,
                        borderRadius: 0,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // name
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // quantity badge
                    if (qty > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: isDark ? 0.12 : 0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '×$qty',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ),

                    // chevron arrow to indicate it's tappable
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: cs.onSurface.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            ),
                ),
            // connector between items
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
                child: Row(
                  children: [
                    // dashed vertical line segment
                    SizedBox(
                      width: 18,
                      height: 22,
                      child: CustomPaint(
                        painter: _DashedLinePainter(color: primary.withValues(alpha: 0.3)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // plus icon only — no container, no text
                    Icon(
                      Icons.add_circle_outline_rounded,
                      size: 14,
                      color: cs.onSurface.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHED LINE PAINTER  — small vertical dashed separator
// ─────────────────────────────────────────────────────────────────────────────
class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dashHeight = 3.0;
    const dashSpace = 3.0;
    double y = 0;
    final x = size.width / 2;

    while (y < size.height) {
      canvas.drawLine(Offset(x, y), Offset(x, math.min(y + dashHeight, size.height)), paint);
      y += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}