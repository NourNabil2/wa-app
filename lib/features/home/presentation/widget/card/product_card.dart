// lib/features/home/presentation/widget/card/product_card.dart
// Complete rewrite — Noon / Amazon inspired, zero overflow, SAR symbol correct.

import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/utils/assets.dart';
import 'package:fastway/core/utils/extension.dart';
import 'package:fastway/core/widgets/custom_network_image.dart';
import 'package:fastway/core/widgets/wishlist_heart_button.dart';
import 'package:fastway/features/home/presentation/widget/card/animated_cart_button.dart';
import 'package:fastway/core/widgets/discount_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fastway/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:fastway/features/cart/presentation/cubit/cart_state.dart';
import 'package:fastway/features/cart/domain/entities/cart_entity.dart';
import 'package:fastway/core/widgets/sar_symbol.dart';
import 'package:fastway/core/responsive/hoverable_card.dart';
import 'package:fastway/features/home/presentation/widget/card/product_quick_view.dart'
    as pqv;

void _showQuickView(BuildContext context, String productId) {
  pqv.showQuickView(context, productId);
}

/// The width / height ratio a ProductCard cell must have for its image box to
/// come out SQUARE — which is what product images are (1:1, white-padded).
///
/// The card is a Column of [image | text]. The text block has a fixed height of
/// roughly 0.77 x cardWidth:
///
///   padding x2   0.074w      name           0.237w
///   brand+rating 0.100w      price          0.112w
///   4 gaps       0.048w      stock warning  ~0.07w   (Visibility maintainSize)
///                            express badge  ~0.12w   (Visibility maintainSize)
///
/// The last two always reserve their height even when hidden, which is easy to
/// miss. So cellHeight = w + 0.77w = 1.77w, i.e. ratio = 1 / 1.77 = 0.565.
///
/// It is not perfectly width-independent — the warning font and the badge height
/// are clamped, so the true value drifts to ~0.58 on very wide (300px+) cards.
/// That residual is deliberately absorbed by [BoxFit.contain] in _CardImage
/// rather than chased with per-width math: worst case it leaves a ~3% white
/// margin, and it can never crop the image.
///
/// Use this for EVERY grid / rail that hosts a ProductCard. Do not hand-tune a
/// ratio per screen — that is what produced the 0.42 - 0.72 spread this replaces.
const double kProductCardAspectRatio = 0.565;

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC API
// ─────────────────────────────────────────────────────────────────────────────
class ProductCard extends StatelessWidget {
  final String productId;
  final String name;
  final String? imageUrl;
  final double price;
  final double? originalPrice;
  final double? rating;
  final int? reviewCount;
  final bool isNew;
  final bool isAvailable;
  final VoidCallback? onTap;
  final bool isExpressEligible;
  final bool isFeatured;
  final String? stockWarning;
  final int? pointsToEarn;
  final String? categoryName;
  final String? brandName;

  /// compact = horizontal layout (used in carts / sidebars)
  final bool compact;
  final bool hideCartButton;
  final bool hideFavoriteButton;
  final double? titleFontSize;
  final double? priceFontSize;
  final FontWeight? priceFontWeight;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.productId,
    required this.name,
    this.imageUrl,
    required this.price,
    this.originalPrice,
    this.rating,
    this.reviewCount,
    this.isNew = false,
    this.isAvailable = true,
    this.isExpressEligible = false,
    this.isFeatured = false,
    this.stockWarning,
    this.pointsToEarn,
    this.categoryName,
    this.brandName,
    this.onTap,
    this.compact = false,
    this.hideCartButton = false,
    this.hideFavoriteButton = false,
    this.titleFontSize,
    this.priceFontSize,
    this.priceFontWeight,
    this.onAddToCart,
  });

  int? get _discount {
    if (originalPrice == null || originalPrice! <= price) return null;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClickCursor(
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () => _showQuickView(context, productId),
        // Opacity widget removed — it forces CanvasKit to create a GPU
        // saveLayer for every OOS card, causing sparkling. The dark overlay
        // on the image already communicates "unavailable".
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: compact
                ? _HCard(
                    productId: productId,
                    name: name,
                    imageUrl: imageUrl ?? '',
                    price: price,
                    originalPrice: originalPrice,
                    rating: rating,
                    reviewCount: reviewCount,
                    isAvailable: isAvailable,
                    isExpressEligible: isExpressEligible,
                    isFeatured: isFeatured,
                    stockWarning: stockWarning,
                    pointsToEarn: pointsToEarn,
                    discount: _discount,
                    categoryName: categoryName,
                    hideCartButton: hideCartButton,
                    hideFavoriteButton: hideFavoriteButton,
                    titleFontSize: titleFontSize,
                    priceFontSize: priceFontSize,
                    priceFontWeight: priceFontWeight,
                  )
                : _VCard(
                    productId: productId,
                    name: name,
                    imageUrl: imageUrl ?? '',
                    price: price,
                    originalPrice: originalPrice,
                    rating: rating,
                    reviewCount: reviewCount,
                    isNew: isNew,
                    isAvailable: isAvailable,
                    isExpressEligible: isExpressEligible,
                    isFeatured: isFeatured,
                    stockWarning: stockWarning,
                    pointsToEarn: pointsToEarn,
                    discount: _discount,
                    categoryName: categoryName,
                    brandName: brandName,
                    hideCartButton: hideCartButton,
                    hideFavoriteButton: hideFavoriteButton,
                    priceFontSize: priceFontSize,
                    priceFontWeight: priceFontWeight,
                    onAddToCart: onAddToCart,
                  ), // _VCard / _HCard
          ), // ClipRRect
        ), // Container
      ), // GestureDetector
    ); // ClickCursor
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VERTICAL CARD  (grid default)
// ─────────────────────────────────────────────────────────────────────────────
class _VCard extends StatefulWidget {
  final String productId, name, imageUrl;
  final double price;
  final double? originalPrice, rating;
  final int? reviewCount, discount, pointsToEarn;
  final bool isNew, isAvailable, isExpressEligible, isFeatured;
  final String? stockWarning, categoryName, brandName;
  final bool hideCartButton;
  final bool hideFavoriteButton;
  final double? priceFontSize;
  final FontWeight? priceFontWeight;
  final VoidCallback? onAddToCart;

  const _VCard({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.isNew,
    required this.isAvailable,
    required this.isExpressEligible,
    required this.isFeatured,
    this.stockWarning,
    this.pointsToEarn,
    this.originalPrice,
    this.rating,
    this.reviewCount,
    this.discount,
    this.categoryName,
    this.brandName,
    this.hideCartButton = false,
    this.hideFavoriteButton = false,
    this.priceFontSize,
    this.priceFontWeight,
    this.onAddToCart,
  });

  @override
  State<_VCard> createState() => _VCardState();
}

class _VCardState extends State<_VCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8A8A8E);

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;

        // ── Responsive scale factor ───────────────────────────────────────
        // All spacing / sizing is derived as a % of card width so the card
        // looks identical at 120 px wide (mobile) or 220 px wide (desktop).
        // Base reference width = 160 px (typical grid card on a mid-range screen).
        final double w =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 160.0;
        final double scale = (w / 160.0).clamp(0.6, 1.6);

        // Spacing helpers (% of card width)
        final double gapXS =
            w * (hasBoundedHeight ? 0.012 : 0.018); // tighter when bounded
        final double gapSM = w * 0.025; // ~4 %  — small gap
        final double padH = w * 0.062; // ~10 % — horizontal padding
        final double padV = w * 0.037; // ~6 %  — vertical padding

        // Slot heights (% of card width) — simplified layout
        final double brandRatingH =
            w * 0.100; // ~16 px @ 160 (brand + mini rating)
        final double nameH = w * 0.237; // ~38 px @ 160  (2 lines)
        final double priceH = w * 0.112; // ~18 px @ 160

        // Font sizes scale with the card width
        final double fsBrand = (10 * scale).clamp(7.0, 14.0);
        final double fsRating = (8.0 * scale).clamp(6.0, 10.0); // Made smaller
        final double fsName = (11.0 * scale).clamp(9.0, 17.0);
        final double fsOrig = (11 * scale).clamp(8.0, 15.0);
        final double fsPrice = (16 * scale).clamp(11.0, 22.0);
        final double fsWarning = (8.5 * scale).clamp(6.0, 11.0);

        final bool hasStockWarning = widget.stockWarning != null && widget.stockWarning!.isNotEmpty && widget.isAvailable;

        Widget detailsBody = Padding(
          padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Slot 1: Brand name + Rating ────────────────
              SizedBox(
                height: hasBoundedHeight ? brandRatingH : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (widget.brandName != null &&
                        widget.brandName!.isNotEmpty)
                      Expanded(
                        child: Text(
                          widget.brandName!,
                          style: TextStyle(
                            fontSize: fsBrand,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF00BFA5),
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      const Spacer(),
                    if (widget.rating != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6 * scale, vertical: 2 * scale),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade800
                              : const Color(0xFFF2F4F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.star_rounded,
                                size: (12 * scale).clamp(9.0, 14.0),
                                color: const Color(0xFFFFC107)),
                            SizedBox(width: 3 * scale),
                            Padding(
                              padding: EdgeInsets.only(
                                  top: 1.5 *
                                      scale), // Slightly pushed down for font baseline alignment
                              child: Text(
                                widget.rating!.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: fsRating,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: gapXS),

              // ── Slot 2: Product name & Stock Warning ─────────────────────
              (() {
                final bool isAr = context.locale.languageCode == 'ar';
                final Widget nameWidget = Text(
                  widget.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: isAr ? TextAlign.right : TextAlign.left,
                  style: TextStyle(
                    fontSize: fsName,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    color: nameColor,
                  ),
                );

                final col = Column(
                  crossAxisAlignment:
                      isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    hasBoundedHeight
                        ? SizedBox(
                            height: nameH,
                            child: Align(
                                alignment: isAr
                                    ? Alignment.topRight
                                    : Alignment.topLeft,
                                child: nameWidget))
                        : nameWidget,
                    SizedBox(height: gapXS),
                    Visibility(
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      visible: hasStockWarning,
                      child: Text(
                        widget.stockWarning == 'low'
                            ? 'product.stockWarning.low'.tr()
                            : (widget.stockWarning != null
                                ? 'product.stockWarning.limited'.tr()
                                : ''),
                        style: TextStyle(
                          fontSize: fsWarning,
                          color: const Color(0xFFEF5350),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
                return col;
              })(),
              if (!hasBoundedHeight) SizedBox(height: gapXS),

              // ── Slot 3: Price row (current + original + discount + express) ─
              SizedBox(
                height: hasBoundedHeight ? priceH : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SarText(
                              price: widget.price.toPriceFormat(),
                              style: TextStyle(
                                fontSize: fsPrice,
                                fontWeight: FontWeight.normal,
                                color: widget.isAvailable
                                    ? ColorsManager.primaryColor
                                    : subColor,
                                height: 1.1,
                              ),
                            ),
                            if (widget.originalPrice != null) ...[
                              SizedBox(width: gapSM),
                              SarText(
                                price: widget.originalPrice!.toPriceFormat(),
                                strikeThrough: false,
                                style: TextStyle(
                                  fontSize: fsOrig,
                                  color: subColor.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                            if (widget.discount != null &&
                                widget.isAvailable) ...[
                              SizedBox(width: 6 * scale),
                              DiscountBadge(
                                  percent: widget.discount!, scale: scale),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: gapXS),
              Visibility(
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                visible: widget.isExpressEligible,
                child: _ExpressBadge(scale: scale * 0.9),
              ),
              SizedBox(height: gapXS),

              // ── Slot 4: Removed ─────────────────────────────
            ],
          ),
        );

        // ── Image section ─────────────────────────────────────────────────────
        final imageWidget = _CardImage(
          borderRadius: BorderRadius.circular(8),
          productId: widget.productId,
          imageUrl: widget.imageUrl,
          isAvailable: widget.isAvailable,
          discount: widget.discount,
          isNew: widget.isNew,
          isFeatured: widget.isFeatured,
          rating: null,
          isHovered: _isHovered,
          stockWarning: null,
          showOverlayCartButton: !widget.hideCartButton,
          hideFavoriteButton: widget.hideFavoriteButton,
          onAddToCart: widget.onAddToCart,
        );

        if (!hasBoundedHeight) {
          return GestureDetector(
            onLongPress: () => _showQuickView(context, widget.productId),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) {
                setState(() {
                  _isHovered = true;
                });
              },
              onExit: (_) {
                setState(() {
                  _isHovered = false;
                });
              },
              child: Container(
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Square: product images are 1:1. (This branch only runs when
                    // the parent gives the card an unbounded height — no current
                    // call site does, but 0.85 here would crop if one ever did.)
                    AspectRatio(aspectRatio: 1.0, child: imageWidget),
                    detailsBody,
                  ],
                ),
              ),
            ),
          );
        }

        return GestureDetector(
          onLongPress: () => _showQuickView(context, widget.productId),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) {
              setState(() {
                _isHovered = true;
              });
            },
            onExit: (_) {
              setState(() {
                _isHovered = false;
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: imageWidget),
                  detailsBody,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HORIZONTAL CARD  (compact list / sidebar)
// ─────────────────────────────────────────────────────────────────────────────
class _HCard extends StatelessWidget {
  final String productId, name, imageUrl;
  final double price;
  final double? originalPrice, rating;
  final int? reviewCount, discount, pointsToEarn;
  final bool isAvailable, isExpressEligible, isFeatured;
  final String? stockWarning, categoryName;
  final bool hideCartButton;
  final bool hideFavoriteButton;
  final double? titleFontSize;
  final double? priceFontSize;
  final FontWeight? priceFontWeight;

  const _HCard({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.isAvailable,
    required this.isExpressEligible,
    required this.isFeatured,
    this.stockWarning,
    this.pointsToEarn,
    this.originalPrice,
    this.rating,
    this.reviewCount,
    this.discount,
    this.categoryName,
    this.hideCartButton = false,
    this.hideFavoriteButton = false,
    this.titleFontSize,
    this.priceFontSize,
    this.priceFontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8A8A8E);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            SizedBox(
              width: 100,
              child: _CardImage(
                productId: productId,
                imageUrl: imageUrl,
                isAvailable: isAvailable,
                discount: discount,
                isNew: false,
                isFeatured: isFeatured,
                rating: rating,
                borderRadius: const BorderRadius.horizontal(left: Radius.zero),
                stockWarning: stockWarning,
                showOverlayCartButton: false,
                fixedWidth: 100,
                hideFavoriteButton: hideFavoriteButton,
              ),
            ),

            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isExpressEligible) ...[
                      Row(
                        children: [
                          const Spacer(),
                          const _ExpressBadge(scale: 0.8),
                        ],
                      ),
                      const SizedBox(height: 2),
                    ],
                    if (categoryName != null && categoryName!.isNotEmpty) ...[
                      Text(
                        categoryName!,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color:
                              ColorsManager.primaryColor.withValues(alpha: 0.8),
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titleFontSize ?? 14.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                        color: nameColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _Price(
                            price: price,
                            originalPrice: originalPrice,
                            isAvailable: isAvailable,
                            discount: discount,
                            priceFontSize: priceFontSize,
                            priceFontWeight: priceFontWeight,
                          ),
                        ),
                        if (isAvailable && !hideCartButton)
                          AnimatedCartButtonCompact(
                            productId: productId,
                            productName: name,
                            price: price,
                            originalPrice: originalPrice,
                            imageUrl: imageUrl,
                            isAvailable: true,
                          )
                        else if (!isAvailable)
                          _OutOfStockChip(),
                      ],
                    ),
                    if (stockWarning == 'low' && isAvailable) ...[
                      const SizedBox(height: 4),
                      Text(
                        'product.stockWarning.low'.tr(),
                        style: TextStyle(
                            fontSize: 10.sp,
                            color: const Color(0xFFF59E0B),
                            fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD IMAGE  — discount badge top-left, wishlist top-right, OOS overlay
// ─────────────────────────────────────────────────────────────────────────────
class _CardImage extends StatelessWidget {
  final String productId, imageUrl;
  final bool isAvailable, isNew, isFeatured;
  final int? discount;
  final BorderRadius? borderRadius;
  final double? rating;
  final bool isHovered;
  final String? stockWarning;
  final bool showOverlayCartButton;
  final double? fixedWidth;
  final bool hideFavoriteButton;
  final VoidCallback? onAddToCart;

  const _CardImage({
    required this.productId,
    required this.imageUrl,
    required this.isAvailable,
    required this.isNew,
    this.isFeatured = false,
    this.discount,
    this.borderRadius,
    this.rating,
    this.isHovered = false,
    this.stockWarning,
    this.showOverlayCartButton = true,
    this.fixedWidth,
    this.hideFavoriteButton = false,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final radius =
        borderRadius ?? const BorderRadius.vertical(top: Radius.zero);

    Widget content;
    if (fixedWidth != null) {
      content = _buildStack(context, fixedWidth!);
    } else {
      content = LayoutBuilder(
        builder: (context, constraints) {
          final double iw =
              constraints.maxWidth.isFinite ? constraints.maxWidth : 160.0;
          return _buildStack(context, iw);
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade900
            : const Color(0xFFF2F4F5), // Light gray like the image
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: content,
      ),
    );
  }

  Widget _buildStack(BuildContext context, double iw) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;
    final double bScale = (iw / 160.0).clamp(0.55, 1.8);
    final double badgeOffset = iw * 0.04;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Product photo
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomNetworkImage.rounded(
              imageUrl: imageUrl,
              width: double.infinity,
              height: double.infinity,
              borderRadius: 0,
              // contain, NOT cover. Product images are square (1:1, white-padded).
              // cover fills the box and slices off whatever overflows — in a
              // portrait box it shaved the product's sides, in a landscape box
              // its top and bottom. contain always fits the whole image inside,
              // whatever shape the box is, so nothing can ever be cropped.
              //
              // With kProductCardAspectRatio the box is already square, so this
              // is a no-op in practice — it is the seatbelt that stops a future
              // screen with a different ratio from silently cropping again.
              fit: BoxFit.contain,
              // Any leftover margin must be WHITE so it blends into the white
              // padding baked into the image. The default is grey[200], which
              // would show up as grey bars.
              backgroundColor: Colors.white,
            ),
          ),
        ),

        // Out-of-stock dim overlay label (placed here so it doesn't block hover icons)
        if (!isAvailable)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
              alignment: Alignment.center,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: iw * 0.062,
                  vertical: iw * 0.025,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  'product.unavailable'.tr(),
                  style: TextStyle(
                    fontSize: (11 * bScale).clamp(8.0, 16.0),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

        // Wishlist & Quick View
        if (isDesktop) ...[
          // 1) Quick View
          AnimatedPositionedDirectional(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            bottom: isHovered ? badgeOffset + 8.0 : -50.0,
            start: badgeOffset + 8.0,
            child: AnimatedOpacity(
              opacity: isHovered ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2A2A2E).withValues(alpha: 0.92)
                      : Colors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  iconSize: 18,
                  hoverColor:
                      ColorsManager.primaryColor.withValues(alpha: 0.15),
                  highlightColor:
                      ColorsManager.primaryColor.withValues(alpha: 0.25),
                  splashColor:
                      ColorsManager.primaryColor.withValues(alpha: 0.25),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: Icon(Icons.remove_red_eye_outlined,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87),
                  onPressed: () => _showQuickView(context, productId),
                ),
              ),
            ),
          ),
          
          // 2) Favorite
          if (!hideFavoriteButton)
            AnimatedPositionedDirectional(
              duration: const Duration(milliseconds: 450), // longer duration creates a staggered effect
              curve: Curves.easeOutBack,
              bottom: isHovered ? badgeOffset + 8.0 : -50.0,
              start: badgeOffset + 44.0, // Shifted to the right of the first circle
              child: AnimatedOpacity(
                opacity: isHovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 350), // slightly delayed fade in
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2A2A2E).withValues(alpha: 0.92)
                        : Colors.white.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: WishlistHeartButton(
                      productId: productId,
                      noBackground: true,
                      iconSize: 18,
                      hideTooltip: true),
                ),
              ),
            ),
        ] else if (!hideFavoriteButton)
          PositionedDirectional(
            top: -4,
            end: -4,
            child: WishlistHeartButton(
                productId: productId, noBackground: true, hideTooltip: true),
          ),

        // Rating badge (kept for HCard)
        if (rating != null)
          PositionedDirectional(
            bottom: badgeOffset,
            start: badgeOffset,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded,
                      size: (13 * bScale).clamp(11.0, 15.0),
                      color: const Color(0xFFFFC107)),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(top: 3.5),
                    child: Text(
                      rating!.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: (12 * bScale).clamp(10.0, 13.0),
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Stock warning chip (kept for HCard)
        if (stockWarning != null && stockWarning!.isNotEmpty && isAvailable)
          PositionedDirectional(
            bottom: badgeOffset + (showOverlayCartButton ? 36 : 0),
            end: badgeOffset,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 8 * bScale, vertical: 4 * bScale),
              decoration: BoxDecoration(
                color: const Color(0xFFEDB452),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                stockWarning == 'low'
                    ? 'product.stockWarning.low'.tr()
                    : 'product.stockWarning.limited'.tr(),
                style: TextStyle(
                  fontSize: (9 * bScale).clamp(7.0, 12.0),
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
          ),

        // Mobile/Web Overlay Cart Button
        if (showOverlayCartButton && isAvailable)
          PositionedDirectional(
            bottom: badgeOffset,
            end: badgeOffset,
            child: _OverlayCartButton(
              productId: productId,
              onAddToCart: onAddToCart,
            ),
          ),

        // Top-start corner badges (Best Seller, New)
        if (isFeatured || isNew)
          PositionedDirectional(
            top: 0,
            start: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFeatured) _BestSellerBadge(scale: bScale),
                if (isNew) _NewBadge(scale: bScale),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// NEW BADGE
// ─────────────────────────────────────────────────────────────────────────────
class _NewBadge extends StatelessWidget {
  final double scale;
  const _NewBadge({this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    final double fs = (8.5 * scale).clamp(6.5, 11.0);
    final double ph = (6.0 * scale).clamp(4.0, 9.0);
    final double pv = (2.0 * scale).clamp(1.5, 4.0);
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.only(left: ph, right: ph, top: pv + 2.0, bottom: pv),
      decoration: const BoxDecoration(
        color: ColorsManager.primary2Color,
        borderRadius: BorderRadiusDirectional.only(
          bottomEnd:
              Radius.circular(8), // Matches BestSeller shape, less circular
        ),
      ),
      child: Text(
        'product.new'.tr(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fs,
          fontWeight: FontWeight.w400,
          color: Colors.white,
          height: 1.1,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ExpressBadge extends StatelessWidget {
  final double scale;
  const _ExpressBadge({this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    // Use a fixed height and let the width scale naturally to avoid empty space
    final double badgeHeight = (22 * scale).clamp(16.0, 30.0);

    return Transform.translate(
      offset: Offset(isAr ? 6.0 * scale : -6.0 * scale,
          -3.5 * scale), // Shift UP slightly to align perfectly with price text
      child: SvgPicture.asset(
        isAr ? Assets.shippingExpressAR : Assets.shippingExpress,
        height: badgeHeight,
        fit: BoxFit.contain,
        alignment: AlignmentDirectional.centerStart,
      ),
    );
  }
}

class _BestSellerBadge extends StatelessWidget {
  final double scale;
  const _BestSellerBadge({this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    final double fs = (8.5 * scale).clamp(6.5, 11.0); // Make text smaller
    final double ph = (6.0 * scale).clamp(4.0, 9.0); // Make padding smaller
    final double pv = (2.0 * scale).clamp(1.5, 4.0); // Make padding smaller
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.only(left: ph, right: ph, top: pv + 2.0, bottom: pv),
      decoration: const BoxDecoration(
        color: Color(0xFFEF5350), // Matches image red
        borderRadius: BorderRadiusDirectional.only(
          bottomEnd: Radius.circular(8), // Less circular
        ),
      ),
      child: Text(
        'product.badges.best_seller'.tr(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fs,
          fontWeight: FontWeight.w400,
          color: Colors.white,
          height: 1.1, // Align text neatly
        ),
      ),
    );
  }
}

// _MiniChip removed

// ─────────────────────────────────────────────────────────────────────────────
// PRICE BLOCK  — uses SarText for correct SAR symbol
// ─────────────────────────────────────────────────────────────────────────────
class _Price extends StatelessWidget {
  final double price;
  final double? originalPrice;
  final bool isAvailable;
  final int? discount;
  final double? priceFontSize;
  final FontWeight? priceFontWeight;

  const _Price({
    required this.price,
    required this.isAvailable,
    this.originalPrice,
    this.discount,
    this.priceFontSize,
    this.priceFontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grey = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8A8A8E);
    final mainColor = isAvailable ? ColorsManager.primaryColor : grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Struck original price
        if (originalPrice != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SarText(
                  price: originalPrice!.toPriceFormat(),
                  strikeThrough: false,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: grey,
                  ),
                ),
              ),
              if (discount != null && isAvailable) ...[
                const SizedBox(width: 8),
                DiscountBadge(percent: discount!),
              ],
            ],
          ),

        if (originalPrice != null) const SizedBox(height: 2),

        // Main price & Discount tag
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: SarText(
                  price: price.toPriceFormat(),
                  style: TextStyle(
                    fontSize: priceFontSize ?? 16.sp,
                    fontWeight: priceFontWeight ?? FontWeight.normal,
                    color: mainColor,
                    height: 1.1,
                  ),
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
// STAR ROW — always shows 5 stars; filled/partial when rated, greyed when null
// ─────────────────────────────────────────────────────────────────────────────
// _StarRow and _HalfClipper removed

// ─────────────────────────────────────────────────────────────────────────────
// RATING ROW (legacy — kept for HCard)
// ─────────────────────────────────────────────────────────────────────────────
class _RatingRow extends StatelessWidget {
  final double rating;
  final int? count;
  final Color color;

  const _RatingRow({required this.rating, required this.color, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded,
            size: 14, color: Color(0xFFFFC107)), // Rich golden color
        const SizedBox(width: 3),
        Text(rating.toStringAsFixed(1),
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500)),
        if (count != null) ...[
          const SizedBox(width: 3),
          Text('($count)',
              style: TextStyle(
                  fontSize: 10.sp, color: color, fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POINTS ROW
// ─────────────────────────────────────────────────────────────────────────────
// _PointsRow removed

// ─────────────────────────────────────────────────────────────────────────────
// OUT OF STOCK CHIP — replaces the cart button when stock == 0
// ─────────────────────────────────────────────────────────────────────────────
class _OutOfStockChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36, // Match the height of AnimatedCartButtonCompact
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),

      child: Text(
        'product.stockWarning.outOfStock'.tr(),
        maxLines: 1,
        style: const TextStyle(
          fontSize:
              13, // Fixed logical pixels, removed .sp to fix Web Mobile scaling bug
          fontWeight: FontWeight.normal,
          color: Color(0xFFFF3B30),
        ),
      ),
    );
  }
}

class _OverlayCartButton extends StatefulWidget {
  final String productId;
  final VoidCallback? onAddToCart;
  const _OverlayCartButton({required this.productId, this.onAddToCart});

  @override
  State<_OverlayCartButton> createState() => _OverlayCartButtonState();
}

class _OverlayCartButtonState extends State<_OverlayCartButton> {
  bool _expanded = false;
  Timer? _collapseTimer;

  void _startCollapseTimer() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _expanded = false;
        });
      }
    });
  }

  void _expand() {
    setState(() {
      _expanded = true;
    });
    _startCollapseTimer();
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      buildWhen: (previous, current) {
        if (current is CartLoaded ||
            current is AddedToCart ||
            current is CartToastError) return true;
        if (current is AddingToCart)
          return current.productId == widget.productId;
        return false;
      },
      builder: (context, state) {
        CartItemEntity? item;
        if (state is CartLoaded) {
          try {
            item = state.cart.items
                .firstWhere((i) => i.productId == widget.productId);
          } catch (_) {}
        }

        final quantity = item?.quantity ?? 0;
        final isLoading =
            state is AddingToCart && state.productId == widget.productId;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            axis: Axis.horizontal,
            axisAlignment: 1.0,
            child: child,
          ),
          child: quantity == 0
              ? _buildAddButton(context, isLoading)
              : _expanded
                  ? _buildCounter(
                      context, quantity, item!.maxQuantity, isLoading, item.id)
                  : _buildCollapsedBadge(context, quantity),
        );
      },
    );
  }

  Widget _buildCollapsedBadge(BuildContext context, int quantity) {
    return GestureDetector(
      key: const ValueKey('collapsed'),
      onTap: _expand,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: ColorsManager.primary2Color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 4),
            )
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$quantity',
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
          strutStyle: const StrutStyle(
            forceStrutHeight: true,
            height: 1.0,
            leading: 0,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, bool isLoading) {
    return GestureDetector(
      key: const ValueKey('add'),
      onTap: () {
        if (!isLoading) {
          context
              .read<CartCubit>()
              .addToCart(productId: widget.productId, quantity: 1);
          widget.onAddToCart?.call();
          _expand();
        }
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            color: ColorsManager.primary2Color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ]),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.add_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildCounter(BuildContext context, int quantity, int maxQuantity,
      bool isLoading, String itemId) {
    final atMax = quantity >= maxQuantity;
    return Container(
      key: const ValueKey('counter'),
      height: 32,
      decoration: BoxDecoration(
          color: ColorsManager.primary2Color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ]),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Delete / Minus
          GestureDetector(
            onTap: () {
              if (isLoading) return;
              _startCollapseTimer();
              if (quantity == 1) {
                context.read<CartCubit>().removeItem(itemId);
              } else {
                context.read<CartCubit>().decrementQuantity(itemId);
              }
            },
            child: Container(
              width: 32,
              height: 32,
              color: Colors.transparent,
              child: Icon(
                quantity == 1
                    ? Icons.delete_outline_rounded
                    : Icons.remove_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          // Quantity
          Container(
            constraints: const BoxConstraints(minWidth: 16),
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
          ),
          // Plus
          GestureDetector(
            onTap: () {
              if (isLoading || atMax) return;
              _startCollapseTimer();
              context.read<CartCubit>().incrementQuantity(itemId);
              widget.onAddToCart?.call();
            },
            child: Container(
              width: 32,
              height: 32,
              color: Colors.transparent,
              child: Icon(
                Icons.add_rounded,
                color: atMax ? Colors.white54 : Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
