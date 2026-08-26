import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/routes/app_navigator.dart';
import '../../../../core/utils/slug_utils.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../../presentation/cubit/wishlist_cubit.dart';
import '../../domain/entities/wishlist_entity.dart';
import 'package:fastway/core/widgets/sar_symbol.dart';

class WishlistItemCard extends StatelessWidget {
  final WishlistItemEntity item;
  final VoidCallback onRemove;

  const WishlistItemCard({
    super.key,
    required this.item,
    required this.onRemove,
  });

  double get _savingsPct {
    if (item.originalPrice == null || item.originalPrice! <= item.price) {
      return 0;
    }
    return ((item.originalPrice! - item.price) / item.originalPrice! * 100);
  }

  bool get _isOnSale =>
      item.originalPrice != null && item.originalPrice! > item.price;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final subtleBg =
        isDark ? const Color(0xFF16213E) : const Color(0xFFF0FDF4);
    final borderColor = isDark
        ? const Color(0xFF10B981).withValues(alpha: 0.15)
        : const Color(0xFF10B981).withValues(alpha: 0.12);

    return GestureDetector(
      onTap: () => AppNavigator.pushNamed(
        context,
        '${Routes.productDetails}/${SlugUtils.slugify(item.productName, item.productId)}',
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : const Color(0xFF10B981).withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
          child: Stack(
            children: [
              // ── Background accent strip ──────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 3,
                child: _isOnSale
                    ? Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF10B981),
                              Color(0xFF2D2C70),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // ── Main card content ────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, _isOnSale ? 16.h : 14.h,
                    14.w, 14.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Product Image ──────────────────────────────────
                    _ProductImage(
                        imageUrl: item.imageUrl, isDark: isDark, item: item),

                    SizedBox(width: 14.w),

                    // ── Details ────────────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Name + remove button
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.productName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1A1A2E),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              _RemoveButton(onRemove: onRemove, isDark: isDark),
                            ],
                          ),

                          SizedBox(height: 6.h),

                          // Rating stars
                          if (item.rating != null) ...[
                            _StarRating(
                                rating: item.rating!,
                                reviewCount: item.reviewCount,
                                isDark: isDark),
                            SizedBox(height: 8.h),
                          ],

                          // Pricing row
                          _PricingRow(item: item, isDark: isDark),

                          // Savings chip
                          if (_isOnSale && _savingsPct >= 5) ...[
                            SizedBox(height: 6.h),
                            _SavingsChip(pct: _savingsPct, isDark: isDark),
                          ],

                          SizedBox(height: 10.h),

                          // Add to cart button
                          BlocBuilder<CartCubit, CartState>(
                            builder: (context, state) {
                              final isAdding = state is AddingToCart &&
                                  state.productId == item.productId;
                              return _AddToCartButton(
                                item: item,
                                isAdding: isAdding,
                                isDark: isDark,
                                subtleBg: subtleBg,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── "Out of stock" overlay ───────────────────────────────
              if (!item.isAvailable)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.38),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Text(
                          'wishlist.out_of_stock'.tr(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  final bool isDark;
  final WishlistItemEntity item;

  const _ProductImage(
      {required this.imageUrl, required this.isDark, required this.item});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 96.w,
          height: 96.w,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252540) : const Color(0xFFF4FBF8),
            borderRadius: BorderRadius.zero,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.zero,
            child: CachedNetworkImage(
              imageUrl: imageUrl ?? '',
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: isDark
                    ? const Color(0xFF252540)
                    : const Color(0xFFEEF7F3),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ColorsManager.primaryColor.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: isDark
                    ? const Color(0xFF252540)
                    : const Color(0xFFF4FBF8),
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey[400],
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        // Sale badge on image
        if (item.originalPrice != null && item.originalPrice! > item.price)
          Positioned(
            top: 6.h,
            left: 6.w,
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF4757), Color(0xFFFF6B81)],
                ),
                borderRadius: BorderRadius.zero,
              ),
              child: Text(
                '-${((item.originalPrice! - item.price) / item.originalPrice! * 100).round()}%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback onRemove;
  final bool isDark;
  const _RemoveButton({required this.onRemove, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRemove,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 28.w,
        height: 28.w,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: isDark ? 0.15 : 0.07),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.favorite,
          size: 14.sp,
          color: Colors.red[400],
        ),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final bool isDark;
  const _StarRating(
      {required this.rating, required this.reviewCount, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final filled = rating.floor();
    final partial = rating - filled;
    final empty = 5 - filled - (partial > 0 ? 1 : 0);

    return Row(
      children: [
        ...List.generate(
            filled,
            (_) => Icon(Icons.star_rounded,
                size: 13.sp, color: const Color(0xFFFBBF24))),
        if (partial > 0)
          Icon(Icons.star_half_rounded,
              size: 13.sp, color: const Color(0xFFFBBF24)),
        ...List.generate(
            math.max(0, empty),
            (_) => Icon(Icons.star_outline_rounded,
                size: 13.sp, color: Colors.grey[400])),
        SizedBox(width: 5.w),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFFBBF24),
          ),
        ),
        if (reviewCount != null) ...[
          SizedBox(width: 3.w),
          Text(
            '(${reviewCount!})',
            style: TextStyle(
              fontSize: 10.sp,
              color:
                  isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ],
    );
  }
}

class _PricingRow extends StatelessWidget {
  final WishlistItemEntity item;
  final bool isDark;
  const _PricingRow({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SarText(
          price: item.price.toStringAsFixed(2),
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w900,
            color: ColorsManager.primaryColor,
            letterSpacing: -0.3,
          ),
        ),
        if (item.originalPrice != null &&
            item.originalPrice! > item.price) ...[
          SizedBox(width: 8.w),
          SarText(
            price: item.originalPrice!.toStringAsFixed(2),
            strikeThrough: false,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ],
    );
  }
}

class _SavingsChip extends StatelessWidget {
  final double pct;
  final bool isDark;
  const _SavingsChip({required this.pct, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.12),
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 10.sp,
            color: ColorsManager.primaryColor,
          ),
          SizedBox(width: 4.w),
          Text(
            'Save ${pct.round()}%',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: ColorsManager.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddToCartButton extends StatelessWidget {
  final WishlistItemEntity item;
  final bool isAdding;
  final bool isDark;
  final Color subtleBg;

  const _AddToCartButton({
    required this.item,
    required this.isAdding,
    required this.isDark,
    required this.subtleBg,
  });

  @override
  Widget build(BuildContext context) {
    if (!item.isAvailable) return const SizedBox.shrink();

    return GestureDetector(
      onTap: isAdding
          ? null
          : () {
              context.read<CartCubit>().addToCart(
                productId: item.productId,
                quantity: 1,
              );
              // Auto-remove from wishlist when moved to cart
              context.read<WishlistCubit>().removeItem(
                item.wishlistItemId,
                productId: item.productId,
              );
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 38.h,
        decoration: BoxDecoration(
          gradient: isAdding
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: isAdding
              ? ColorsManager.primaryColor.withValues(alpha: 0.1)
              : null,
          borderRadius: BorderRadius.zero,
          boxShadow: isAdding
              ? null
              : [
                  BoxShadow(
                    color:
                        ColorsManager.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Center(
          child: isAdding
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14.w,
                      height: 14.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ColorsManager.primaryColor,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'common.loading'.tr(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: ColorsManager.primaryColor,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_shopping_cart_rounded,
                      size: 15.sp,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'wishlist.add_to_cart'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
