// lib/features/home/presentation/widget/card/product_list.dart
import 'package:fastway/features/home/domain/entities/product_entity.dart';
import 'package:fastway/features/home/presentation/widget/card/product_card.dart';
import 'package:fastway/core/widgets/skeletons.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

class ProductsGrid extends StatelessWidget {
  final List<ProductEntity> products;
  final int? crossAxisCount;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsets? padding;
  final bool isLoadingMore;
  final void Function(String name, String id)? onTap;

  const ProductsGrid({
    super.key,
    required this.products,
    this.crossAxisCount,
    this.shrinkWrap = true,
    this.physics,
    this.padding,
    this.isLoadingMore = false,
    this.onTap,
  });

  int _cols(double w) {
    if (crossAxisCount != null) return crossAxisCount!;
    if (w >= 1100) return 4; // Web / Large screens
    if (w >= 700)  return 3; // Tablet
    return 2;                // Mobile
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final locale = Localizations.localeOf(context).languageCode;
    final cols = _cols(w);
    const ratio = kProductCardAspectRatio;

    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics ?? const NeverScrollableScrollPhysics(),
      padding: padding ?? const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: ratio,
      ),
      itemCount: products.length + (isLoadingMore ? cols : 0),
      itemBuilder: (_, i) {
        if (i >= products.length) return const ProductCardSkeleton();
        final p = products[i];
        return ProductCard(
          productId: p.id,
          name: p.localizedName(locale),
          imageUrl: p.imageUrl,
          price: p.price,
          originalPrice: p.originalPrice,
          rating: p.rating,
          reviewCount: p.reviewCount,
          isNew: p.isNew,
          isAvailable: p.isAvailable,
          isExpressEligible: p.isExpressEligible,
          isFeatured: p.isFeatured,
          stockWarning: p.stockWarning,
          pointsToEarn: p.pointsToEarn,
          brandName: p.localizedBrandName(context.locale.languageCode),
          onTap: onTap != null ? () => onTap!(p.localizedName(locale), p.id) : null,
        );
      },
    );
  }
}
