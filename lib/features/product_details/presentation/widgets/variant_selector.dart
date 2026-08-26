// lib/features/product_details/presentation/widgets/variant_selector.dart
//
// A horizontal scrollable row of flavor/variant chips.
// Each chip shows the variant image + label and highlights the currently-viewed
// product. Out-of-stock variants are greyed with an overlay badge.
// No animations, no BoxShadow — GPU safe.

import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/features/product_details/domain/entities/product_details_entity.dart';

class VariantSelector extends StatelessWidget {
  final List<ProductVariant> variants;
  final String currentProductId;
  final String? currentProductSku;
  final bool isDark;
  final bool isAr;
  /// Admin-defined header for this variant group, e.g. "Flavor", "Size", "Type".
  /// Falls back to the default "Flavor" translation when null/empty.
  final String? groupLabel;
  /// Chip size — slightly larger on web
  final double chipWidth;
  final double chipHeight;
  final void Function(String) onVariantSwitch;

  const VariantSelector({
    super.key,
    required this.variants,
    required this.currentProductId,
    this.currentProductSku,
    required this.isDark,
    required this.isAr,
    this.groupLabel,
    this.chipWidth = 80,
    this.chipHeight = 92,
    required this.onVariantSwitch,
  });

  @override
  Widget build(BuildContext context) {
    if (variants.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            (groupLabel?.trim().isNotEmpty ?? false) ? groupLabel!.trim() : 'product.flavors_label'.tr(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            child: Row(
            children: variants.map((v) {
              final isSelected = v.id == currentProductId || (currentProductSku != null && v.sku == currentProductSku);
              return _VariantChip(
              variant: v,
              isSelected: isSelected,
              isDark: isDark,
              isAr: isAr,
              chipWidth: chipWidth,
              chipHeight: chipHeight,
              onTap: () {
                if (isSelected) return;
                onVariantSwitch(v.id);
              },
            );
          }).toList(),
          ),
        ),
        ),
      ],
    );
  }
}

class _VariantChip extends StatelessWidget {
  final ProductVariant variant;
  final bool isSelected;
  final bool isDark;
  final bool isAr;
  final double chipWidth;
  final double chipHeight;
  final VoidCallback onTap;

  const _VariantChip({
    required this.variant,
    required this.isSelected,
    required this.isDark,
    required this.isAr,
    required this.chipWidth,
    required this.chipHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = variant.displayLabel(isAr);

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 10),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
        child: Opacity(
          opacity: variant.inStock ? 1.0 : 0.45,
          child: Container(
            width: chipWidth,
            height: chipHeight,
            decoration: BoxDecoration(
              color: isSelected
                  ? ColorsManager.primaryColor.withValues(alpha: isDark ? 0.18 : 0.08)
                  : (isDark ? const Color(0xFF2C2C2E) : Colors.white),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? ColorsManager.primaryColor
                    : (isDark ? Colors.white12 : Colors.black12),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                // Image (top portion)
                Positioned(
                  top: 0, left: 0, right: 0,
                  height: chipHeight * 0.60,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.zero),
                    // Empty image_url (variant has no image — API returns null to
                    // avoid the CORS-blocked /images/Logo.png placeholder) → show
                    // the styled placeholder directly instead of a broken thumb.
                    child: variant.imageUrl.trim().isEmpty
                        ? _variantImagePlaceholder(isDark)
                        : CachedNetworkImage(
                            imageUrl: variant.imageUrl,
                            fit: BoxFit.contain,
                            memCacheWidth: 160,
                            fadeInDuration: Duration.zero,
                            fadeOutDuration: Duration.zero,
                            errorWidget: (_, __, ___) => _variantImagePlaceholder(isDark),
                          ),
                  ),
                ),

                // Label (bottom portion)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  height: chipHeight * 0.45,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: variant.inStock ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? ColorsManager.primaryColor
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                        if (!variant.inStock) ...[
                          const SizedBox(height: 1),
                          Text(
                            'product.outOfStock'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
       ),
      ),
    );
  }
}

/// Placeholder shown when a variant has no image. Themed to match the chip so
/// it reads as "no image" rather than a broken/blank thumbnail.
Widget _variantImagePlaceholder(bool isDark) => Container(
      color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7),
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined, size: 20, color: Colors.grey),
    );
