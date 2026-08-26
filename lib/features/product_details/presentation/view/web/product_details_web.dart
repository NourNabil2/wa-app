// lib/features/product_details/presentation/view/web/product_details_web.dart
import 'package:flutter/gestures.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:fastway/core/utils/slug_utils.dart';
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/widgets/drag_scroll.dart';
import 'package:fastway/core/widgets/selectable.dart';
import 'package:fastway/core/widgets/safe_mouse_region.dart';
import 'package:fastway/core/layout/simple_web_shell.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/utils/assets.dart';
import 'package:fastway/core/widgets/CustomIcon.dart';
import 'package:fastway/features/home/presentation/widget/card/animated_cart_button.dart';
import 'package:fastway/features/home/presentation/widget/card/product_card.dart';
import 'package:fastway/features/home/domain/entities/category_entity.dart';
import 'package:fastway/features/product_details/domain/entities/product_details_entity.dart';
import 'package:fastway/features/product_details/presentation/cubit/product_details_cubit.dart';
import 'package:fastway/features/user_data/user_cubit.dart';
import 'package:fastway/features/product_details/presentation/widgets/product_bundle_widget.dart';
import 'package:fastway/features/product_details/presentation/widgets/variant_selector.dart';
import 'package:fastway/features/product_details/presentation/widgets/product_details_shared.dart';
import 'package:fastway/features/product_details/presentation/widgets/product_image_gallery.dart';
import 'package:fastway/features/product_details/presentation/widgets/notify_me_button.dart';
import 'package:fastway/core/widgets/wishlist_heart_button.dart';
import 'package:fastway/core/widgets/share_product_button.dart';
import 'package:fastway/core/widgets/discount_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fastway/core/widgets/sar_symbol.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:fastway/core/widgets/loyalty_points_bar.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MAIN WIDGET
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class ProductDetailsWeb extends StatelessWidget {
  final ProductDetailsEntity product;
  final String productId;
  final int quantity;
  final List<dynamic> questions;
  final bool questionsLoading;
  final void Function(String) onVariantSwitch;

  const ProductDetailsWeb({
    super.key,
    required this.product,
    required this.productId,
    required this.quantity,
    this.questions = const [],
    this.questionsLoading = false,
    required this.onVariantSwitch,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs     = Theme.of(context).colorScheme;
    final isAr   = context.locale.languageCode == 'ar';
    final discountPercent = product.originalPrice != null &&
        product.originalPrice! > product.price
        ? (((product.originalPrice! - product.price) / product.originalPrice!) * 100)
        .round()
        : null;

    return SimpleWebShell(
      forceWhiteBackground: true,
      content: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 900;
          final hPad    = isNarrow ? 16.0 : constraints.maxWidth < 1600 ? 32.0 : constraints.maxWidth * 0.12;
          final imgH    = isNarrow ? 300.0 : 500.0;
          const maxW    = double.infinity;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxW),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Breadcrumb ────────────────────────────────────────
                        _ProductBreadcrumb(product: product, isDark: isDark),
                        const SizedBox(height: 16),

                        // ── MAIN LAYOUT: 2-col on wide, stacked on narrow ───
                        if (isNarrow)
                          // Narrow: image on top, info below
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: imgH,
                                child: _ImagePanel(images: product.galleryImages, isDark: isDark, isNarrow: isNarrow),
                              ),
                              if (product.variants.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                VariantSelector(
                                  variants: product.variants,
                                  currentProductId: product.id,
                                  currentProductSku: product.sku,
                                  isDark: isDark,
                                  isAr: isAr,
                                  groupLabel: isAr ? (product.variantGroupLabelAr ?? product.variantGroupLabel) : product.variantGroupLabel,
                                  chipWidth: 80,
                                  chipHeight: 90,
                                  onVariantSwitch: onVariantSwitch,
                                ),
                              ],
                              const SizedBox(height: 20),
                              _RightColumn(
                                product: product,
                                productId: productId,
                                quantity: quantity,
                                isDark: isDark,
                                isAr: isAr,
                                discountPercent: discountPercent,
                                cs: cs,
                                questions: questions,
                                questionsLoading: questionsLoading,
                              ),
                            ],
                          )
                        else
                          // Wide: side-by-side
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 10,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: imgH,
                                      child: _ImagePanel(images: product.galleryImages, isDark: isDark, isNarrow: isNarrow),
                                    ),
                                    if (product.variants.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      VariantSelector(
                                        variants: product.variants,
                                        currentProductId: product.id,
                                        currentProductSku: product.sku,
                                        isDark: isDark,
                                        isAr: isAr,
                                        groupLabel: isAr ? (product.variantGroupLabelAr ?? product.variantGroupLabel) : product.variantGroupLabel,
                                        chipWidth: 90,
                                        chipHeight: 104,
                                        onVariantSwitch: onVariantSwitch,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 28),
                              Expanded(
                                flex: 9,
                                child: _RightColumn(
                                  product: product,
                                  productId: productId,
                                  quantity: quantity,
                                  isDark: isDark,
                                  isAr: isAr,
                                  discountPercent: discountPercent,
                                  cs: cs,
                                  questions: questions,
                                  questionsLoading: questionsLoading,
                                ),
                              ),
                            ],
                          ),

                        // ── BUNDLE ─────────────────────────────────────────
                        if (product.isBundle && product.bundleComponents.isNotEmpty)
                          Builder(builder: (ctx) {
                            final dynamic bSavings = product.bundleSavings;
                            final double amount = bSavings != null
                                ? (bSavings is double ? bSavings : (bSavings.amount ?? 0.0))
                                : 0.0;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 40),
                                BundleSectionHeader(
                                  savingsAmount: amount,
                                  currencyLabel: 'product.currency'.tr(),
                                ),
                                const SizedBox(height: 16),
                                ProductBundleWidget(components: product.bundleComponents),
                                const SizedBox(height: 32),
                              ],
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
              // ── RELATED PRODUCTS ─────────────────────────────────────
              if (product.alsoBought.isNotEmpty || product.brandPicks.isNotEmpty || product.relatedProducts.isNotEmpty)
                Container(
                  width: double.infinity,
                  color: isDark ? ColorsManager.surfaceDarkCard : Colors.grey.shade50,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: maxW),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 48),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (product.alsoBought.isNotEmpty) ...[
                              _WebSectionTitle(
                                  icon: Icons.people_alt_rounded,
                                  label: 'product.customers_also_bought'.tr()),
                              const SizedBox(height: 14),
                              _WebProductRow(products: product.alsoBought, context: context, isAr: isAr),
                            ],
                            if (product.brandPicks.isNotEmpty) ...[
                              const SizedBox(height: 40),
                              _WebSectionTitle(
                                label: _webMoreFromLabel(product.brand),
                              ),
                              const SizedBox(height: 16),
                              _WebCenteredProductGrid(products: product.brandPicks, context: context, isAr: isAr),
                            ],
                            if (product.relatedProducts.isNotEmpty) ...[
                              const SizedBox(height: 40),
                              _WebSectionTitle(
                                  label: 'product.you_might_also_like'.tr()),
                              const SizedBox(height: 16),
                              _WebCenteredProductGrid(products: product.relatedProducts, context: context, isAr: isAr),
                            ],
                          ],
                        ),
                      ),
                    ),  // ConstrainedBox
                  ),    // Center
                ),      // Container
            ],
          );
        },
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ① IMAGE PANEL
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _ImagePanel extends StatefulWidget {
  final List<String> images;
  final bool isDark;
  final bool isNarrow;
  const _ImagePanel({required this.images, required this.isDark, this.isNarrow = false});

  @override
  State<_ImagePanel> createState() => _ImagePanelState();
}

class _ImagePanelState extends State<_ImagePanel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: widget.isDark ? const Color(0xFF2C2C2E) : ColorsManager.gray100,
          child: Center(
            child: Icon(Icons.image_not_supported_outlined, size: 48, color: widget.isDark ? Colors.grey[600] : Colors.grey[400]),
          ),
        ),
      );
    }

    if (widget.isNarrow) {
      return SizedBox(
        height: 370,
        child: ProductImageGallery(images: widget.images),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: Colors.white,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Vertical Thumbnails
              if (widget.images.length > 1) ...[
                SizedBox(
                  width: 80,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: widget.images.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final isSelected = _currentIndex == index;
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => setState(() => _currentIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: isSelected ? ColorsManager.primaryColor : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: widget.images[index],
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ));
                      },
                    ),
                  ),
                ),
                SizedBox(width: constraints.maxWidth * 0.02),
              ],

              // Main Image
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _MagnifierImage(
                    key: ValueKey<String>(widget.images[_currentIndex]),
                    imageUrl: widget.images[_currentIndex],
                    isNarrow: widget.isNarrow,
                    allImages: widget.images,
                    currentIndex: _currentIndex,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ② RIGHT COLUMN  (compact info  +  accordions as plain widgets)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _RightColumn extends StatelessWidget {
  final ProductDetailsEntity product;
  final String productId;
  final int quantity;
  final bool isDark;
  final bool isAr;
  final int? discountPercent;
  final ColorScheme cs;
  final List<dynamic> questions;
  final bool questionsLoading;

  const _RightColumn({
    required this.product,
    required this.productId,
    required this.quantity,
    required this.isDark,
    required this.isAr,
    required this.discountPercent,
    required this.cs,
    required this.questions,
    required this.questionsLoading,
  });

  @override
  Widget build(BuildContext context) {
    final reviewsKey = GlobalKey();

    void scrollToReviews() {
      final ctx = reviewsKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // (Breadcrumb moved above image)

        // ── Brand Card (Moved to top) ─────────────────────────────────────
        if (product.brand != null && product.brand!.isNotEmpty) ...[
          _BrandCard(
            brand: product.brand!,
            brandLogoUrl: product.brandLogoUrl,
            isDark: isDark,
            onViewAll: () => AppNavigator.pushNamed(
              context,
              '${Routes.brand}/${product.brandId ?? ''}',
              arguments: {
                'brandName': product.brand,
                'brandLogoUrl': product.brandLogoUrl,
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── Best Seller badge (below brand card) ──────────────────────
        if (product.isFeatured) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [_WebBestSellerBadge(isDark: isDark)],
          ),
          const SizedBox(height: 14),
        ],

        // ── Product Labels / Badges ───────────────────────────────────────
        if (product.isNew || product.isExpressEligible || product.requiresColdShipping || product.hasPromotion)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (product.isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorsManager.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('product.badges.new'.tr(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                // if (product.isExpressEligible)
                //   Container(
                //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                //     decoration: BoxDecoration(
                //       color: Colors.teal.shade500,
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     child: const Text('شحن سريع', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                //   ),
                if (product.hasPromotion)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade500,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('product.badges.special_offer'.tr(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

        // ── Product name + wishlist ───────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Selectable(
                child: Text(
                  isAr ? (product.nameAr ?? product.name) : product.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    color: isDark ? Colors.white : ColorsManager.surfaceDarkElevated,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ShareProductButton(
              productId: productId,
              productName: isAr ? (product.nameAr ?? product.name) : product.name,
              noBackground: true,
              iconSize: 22,
            ),
            WishlistHeartButton(
              productId: productId,
              noBackground: true,
              iconSize: 22,
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Rating ───────────────────────────────────────────────────────
        MouseRegion(
          cursor: product.reviews.isNotEmpty ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: product.reviews.isNotEmpty ? scrollToReviews : null,
            child: _CompactStars(
                rating: product.rating ?? 0.0,
                reviewCount: product.reviewCount,
                isDark: isDark,
                isClickable: product.reviews.isNotEmpty),
          ),
        ),
        const SizedBox(height: 14),

        // ── Price ────────────────────────────────────────────────────────
        // Price row is pure text (SarText only, no gestures) — safe to wrap whole.
        Selectable(
          child: _CompactPriceRow(
            price: product.price,
            originalPrice: product.originalPrice,
            discountPercent: discountPercent,
            isExpress: product.isExpressEligible,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 4),
        Selectable(
          child: Text(
            'product.vat_inclusive'.tr(),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (product.pointsToEarn != null && product.pointsToEarn! > 0) ...[
          LoyaltyPointsBar(points: product.pointsToEarn!),
          const SizedBox(height: 12),
        ],

        // ── Cold Shipping / Express meta card ──
        _ProductMetaCard(
          requiresColdShipping: product.requiresColdShipping,
          isExpressEligible: product.isExpressEligible,
          isDark: isDark,
        ),
        if (product.requiresColdShipping)
          const SizedBox(height: 16),

        // ── BNPL ─────────────────────────────────────────────────────────
        _CompactBNPLRow(price: product.price, isDark: isDark),
        const SizedBox(height: 14),

        // ── Qty + Cart ────────────────────────────────────────────────────
        if (product.isAvailable) ...[
          AnimatedCartButtonFull(productId: productId, isAvailable: true),
        ] else
          NotifyMeButton(productId: productId, height: 46),
        const SizedBox(height: 16),

        // (SKU / Expiry moved to accordion)

        // ── ACCORDIONS — plain widgets, no scroll box ─────────────────────
        if (product.description.isNotEmpty)
          ProductAccordion(
            title: 'tab_description'.tr(),
            icon: Icons.subject_rounded,
            initiallyExpanded: false,
            child: SizedBox(
              width: double.infinity,
              child: Selectable(
                child: HtmlWidget(
                  isAr ? (product.descriptionAr ?? product.description) : product.description,
                  textStyle: TextStyle(
                    fontSize: 15.0,
                    height: 1.85,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        if ((product.sku != null && product.sku!.isNotEmpty) || (product.expiryDate != null && product.expiryDate!.isNotEmpty))
          ProductAccordion(
            title: 'product.features'.tr(),
            icon: Icons.info_outline_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.sku != null && product.sku!.isNotEmpty) ...[
                  Text('product.sku'.tr(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
                  const SizedBox(height: 2),
                  Selectable(
                    child: Text(product.sku!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onSurface, letterSpacing: 1.2, fontFamily: 'monospace')),
                  ),
                  if (product.expiryDate != null && product.expiryDate!.isNotEmpty) const SizedBox(height: 16),
                ],
                if (product.expiryDate != null && product.expiryDate!.isNotEmpty) ...[
                  Text('product.best_before'.tr(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
                  const SizedBox(height: 2),
                  Selectable(
                    child: Text(product.expiryDate!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onSurface)),
                  ),
                ],
              ],
            ),
          ),

        if (product.nutritionFacts != null)
          ProductAccordion(
            title: 'tab_nutrition'.tr(),
            icon: Icons.bolt_rounded,
            // Pure text table, no gestures inside — safe to wrap whole.
            child: Selectable(
              child: ProductNutritionWidget(facts: product.nutritionFacts!),
            ),
          ),
        if (product.ingredients.isNotEmpty)
          ProductAccordion(
            title: 'tab_ingredients'.tr(),
            icon: Icons.science_outlined,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (isAr && product.ingredientsAr.isNotEmpty ? product.ingredientsAr : product.ingredients)
                  .map((i) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorsManager.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: ColorsManager.primaryColor
                          .withValues(alpha: 0.2)),
                ),
                child: Text(i,
                    style: const TextStyle(
                        fontSize: 12,
                        color: ColorsManager.primaryColor,
                        fontWeight: FontWeight.w500)),
              ))
                  .toList(),
            ),
          ),
        if (product.usage.isNotEmpty)
          ProductAccordion(
            title: 'product.usage'.tr(),
            icon: Icons.info_outline_rounded,
            child: Text(
              isAr ? (product.usageAr ?? product.usage) : product.usage,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: TextStyle(
                  fontSize: 13.5, height: 1.75, color: cs.onSurfaceVariant),
            ),
          ),
        if (product.reviews.isNotEmpty)
          ProductAccordion(
            key: reviewsKey,
            title: 'tab_reviews'.tr(),
            icon: Icons.reviews_outlined,
            child: ProductReviewsWidget(reviews: product.reviews),
          ),
        if (product.showQuestions)
          ProductAccordion(
            title: 'product.qa.title'.tr(),
            icon: Icons.help_outline_rounded,
            child: questionsLoading
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
                : ProductQAWidget(
              questions: List<ProductQuestion>.from(questions),
              productId: productId,
              isAuthenticated: context.read<UserCubit>().isLoggedIn,
              onSubmitQuestion: (q) => context
                  .read<ProductDetailsCubit>()
                  .submitQuestion(productId, q),
            ),
          ),


      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// COMPACT BRAND HEADER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// ── Brand Card ────────────────────────────────────────────────────────────────
class _BrandCard extends StatelessWidget {
  final String brand;
  final String? brandLogoUrl;
  final bool isDark;
  final VoidCallback onViewAll;
  const _BrandCard({
    required this.brand,
    this.brandLogoUrl,
    required this.isDark,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;
    final bg = isDark ? const Color(0xFF1E1E2A) : Colors.white;

    final logoWidget = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: brandLogoUrl != null && brandLogoUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: brandLogoUrl!,
              width: 56,
              height: 40,
              fit: BoxFit.contain,
              errorWidget: (_, __, ___) => _BrandLogoFallback(brand: brand, isDark: isDark),
            )
          : _BrandLogoFallback(brand: brand, isDark: isDark),
    );

    final divider = Container(width: 1, height: 40, color: borderColor);

    // Only the brand TEXT is selectable — deliberately not the whole card, which
    // carries the "view all" button (a Selectable over it would give that button
    // the text cursor).
    final Widget brandInfo = Selectable(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          textAlign: TextAlign.start,
          TextSpan(
            children: [
              TextSpan(text: brand),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Transform.translate(
                  offset: const Offset(0, -1.0),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(Icons.verified_rounded, size: 12, color: Color(0xFF1D9BF0)),
                  ),
                ),
              ),
            ],
          ),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'product.brand_original'.tr(),
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
      ),
    );

    final button = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onViewAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white : Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'product.brand_view_all'.tr(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.black : Colors.white,
          ),
        ),
      ),
    ));

    // Always: [Logo] → divider → brand name / 100% original → spacer → [View All]
    // Flutter Directionality handles LTR/RTL text rendering automatically.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          logoWidget,
          const SizedBox(width: 12),
          divider,
          const SizedBox(width: 12),
          brandInfo,
          const Spacer(),
          button,
        ],
      ),
    );
  }
}

class _BrandLogoFallback extends StatelessWidget {
  final String brand;
  final bool isDark;
  const _BrandLogoFallback({required this.brand, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    width: 52, height: 38,
    decoration: BoxDecoration(
      color: isDark ? Colors.white10 : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
    ),
    alignment: Alignment.center,
    child: Text(
      brand.substring(0, brand.length > 2 ? 2 : brand.length).toUpperCase(),
      style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.w900,
        color: ColorsManager.primaryColor,
      ),
    ),
  );
}

// ── Best Seller badge widget (web) ────────────────────────────────────────────
class _WebBestSellerBadge extends StatelessWidget {
  final bool isDark;
  const _WebBestSellerBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF323673),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Transform.translate(
        offset: const Offset(0, 2.0), // Visually nudge down to center
        child: Text(
          'product.badge_best_seller'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// COMPACT STARS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


class _CompactStars extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final bool isDark;
  final bool isClickable;
  const _CompactStars(
      {required this.rating, this.reviewCount, required this.isDark, this.isClickable = false});

  @override
  Widget build(BuildContext context) {
    final filled  = rating.floor();
    final partial = rating - filled;
    final empty   = math.max(0, 5 - filled - (partial > 0.1 ? 1 : 0));

    return MouseRegion(
      cursor: isClickable ? SystemMouseCursors.click : MouseCursor.defer,
      child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (reviewCount != null)
          Text('($reviewCount)',
              style: TextStyle(
                  fontSize: 11,
                  decoration: isClickable ? TextDecoration.underline : null,
                  color: isDark ? Colors.grey[400] : Colors.grey[500])),
        const SizedBox(width: 4),
        Text(rating.toStringAsFixed(1),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                decoration: isClickable ? TextDecoration.underline : null,
                color: isDark ? Colors.white : ColorsManager.surfaceDarkElevated)),
        const SizedBox(width: 4),
        ...List.generate(filled,
                (_) => const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFBBF24))),
        if (partial > 0.1)
          const Icon(Icons.star_half_rounded, size: 13, color: Color(0xFFFBBF24)),
        ...List.generate(empty,
                (_) => Icon(Icons.star_outline_rounded, size: 13, color: Colors.grey[350])),
      ],
    ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// COMPACT PRICE ROW
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _CompactPriceRow extends StatelessWidget {
  final double price;
  final double? originalPrice;
  final int? discountPercent;
  final bool isExpress;
  final bool isDark;

  const _CompactPriceRow({
    required this.price,
    this.originalPrice,
    this.discountPercent,
    required this.isExpress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = originalPrice != null && originalPrice! > price;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SarText(
          price: price.toStringAsFixed(2),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: ColorsManager.primaryColor,
            height: 1,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 8),
          SarText(
            price: originalPrice!.toStringAsFixed(2),
            strikeThrough: false,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
          const SizedBox(width: 8),
          if (discountPercent != null && discountPercent! > 0)
            DiscountBadge(percent: discountPercent!, scale: 0.9),
        ],
        const Spacer(),
        if (isExpress) ...[
          CustomIcon(
            assetPath: Localizations.localeOf(context).languageCode == 'ar' 
                ? Assets.shippingExpressAR 
                : Assets.shippingExpress, 
            size: 28,
            noColor: true
          ),
        ],
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// COMPACT QUANTITY STEPPER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _CompactStepper extends StatelessWidget {
  final int quantity;
  const _CompactStepper({required this.quantity});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MiniBtn(
            icon: Icons.remove_rounded,
            onPressed: quantity > 1
                ? () => context.read<ProductDetailsCubit>().decrementQuantity()
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11),
            child: Text('$quantity',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800)),
          ),
          _MiniBtn(
            icon: Icons.add_rounded,
            onPressed: () =>
                context.read<ProductDetailsCubit>().incrementQuantity(),
          ),
        ],
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _MiniBtn({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 38,
      child: IconButton(
        padding: EdgeInsets.zero,
        splashRadius: 16,
        icon: Icon(icon, size: 15),
        onPressed: onPressed,
        color: onPressed == null ? Colors.grey[400] : null,
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// COMPACT BNPL ROW
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _CompactBNPLRow extends StatelessWidget {
  final double price;
  final bool isDark;
  const _CompactBNPLRow({required this.price, required this.isDark});

  void _showModal(BuildContext context, String provider) {
    final isTabby      = provider == 'tabby';
    final brandColor   = isTabby ? const Color(0xFF3DBFAD) : const Color(0xFF5E35B1);
    final installments = isTabby ? 4 : 3;
    final amount       = (price / installments).toStringAsFixed(2);
    final cs           = Theme.of(context).colorScheme;
    final dialogWidth  =
    (MediaQuery.sizeOf(context).width - 48).clamp(0.0, 440.0);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: dialogWidth),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                          provider == 'tabby' ? Assets.tabbyIcon : Assets.tamaraIcon, height: 100),
                      const SizedBox(height: 16),
                      Text(
                        'product.installments.pay_in_installments'.tr(args: [installments.toString()]),
                        style: TextStyle(fontSize: 17,
                            fontWeight: FontWeight.w800, color: cs.onSurface),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      SarText(
                        price: '$installments x $amount',
                        symbolFirst: false,
                        style: TextStyle(fontSize: 28,
                            fontWeight: FontWeight.w900, color: cs.onSurface),
                      ),
                      const SizedBox(height: 6),
                      Text('product.installments.no_fees'.tr(),
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 12),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 32),
                      _PaymentStepper(
                          installments: installments, amount: amount,
                          cs: cs, cardColor: Theme.of(context).cardColor),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandColor,
                            foregroundColor: Colors.white, elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                              'product.installments.continue_with'.tr(args: [isTabby ? 'Tabby' : 'Tamara']),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: -8, right: -8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => Navigator.pop(context),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.close_rounded,
                              color: cs.onSurfaceVariant, size: 20),
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.payment_rounded, color: ColorsManager.primaryColor, size: 18),
          const SizedBox(width: 8),
          Text('Secure Payment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(12)),
            child: const CustomIcon(assetPath: Assets.visaIcon, size: 30, noColor: true, isImage: false),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(12)),
            child: const CustomIcon(assetPath: Assets.mastercardIcon, size: 30, noColor: true, isImage: false),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(12)),
            child: const CustomIcon(assetPath: Assets.madaIcon, size: 30, noColor: true, isImage: false),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(12)),
            child: const CustomIcon(assetPath: Assets.applePayIcon, size: 30, noColor: true, isImage: false),
          ),
        ]),
        const SizedBox(height: 14),
        Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade100),
        const SizedBox(height: 14),
        Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: IntrinsicHeight(
              child: Row(
                children: [
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF7F7F7),
                    borderRadius: const BorderRadius.horizontal(right: Radius.zero),
                  ),
                  child: Center(
                    child: Text(
                      'product.installments.want_installments'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              VerticalDivider(width: 1, thickness: 1, color: isDark ? Colors.white12 : Colors.grey.shade300),
              Expanded(
                flex: 2,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _showModal(context, 'tabby'),
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(Assets.tabbyIcon, height: 20),
                        const SizedBox(width: 4),
                        Icon(Icons.info_outline_rounded, size: 14, color: isDark ? Colors.white54 : Colors.grey.shade400),
                      ],
                    ),
                  ),
                )),
              ),
              VerticalDivider(width: 1, thickness: 1, color: isDark ? Colors.white12 : Colors.grey.shade300),
              Expanded(
                flex: 2,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _showModal(context, 'tamara'),
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(Assets.tamaraIcon, height: 16),
                        const SizedBox(width: 4),
                        Icon(Icons.info_outline_rounded, size: 14, color: isDark ? Colors.white54 : Colors.grey.shade400),
                      ],
                    ),
                  ),
                )),
              ),
              ],
            ),
          ),
            ),
          ),
        ),
      ],
    ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SHARED DIVIDER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _Div extends StatelessWidget {
  final bool isDark;
  const _Div({required this.isDark});
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// WEB META CARD  (SKU + Expiry)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _WebMetaCard extends StatelessWidget {
  final String? sku;
  final String? expiryDate;
  final bool isDark;
  const _WebMetaCard({this.sku, this.expiryDate, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hasSku    = sku != null && sku!.isNotEmpty;
    final hasExpiry = expiryDate != null && expiryDate!.isNotEmpty;
    if (!hasSku && !hasExpiry) return const SizedBox.shrink();
    final divColor =
    isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: divColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasSku)
              _MetaRow(
                isDark: isDark,
                dot: isDark ? Colors.grey[600]! : const Color(0xFFB4B2A9),
                label: 'SKU', value: sku!, mono: true,
                trailing: _CopyButton(value: sku!, isDark: isDark),
              ),
            if (hasSku && hasExpiry)
              Divider(height: 0.5, thickness: 0.5, color: divColor),
            if (hasExpiry)
              _MetaRow(
                isDark: isDark,
                dot: _expiryDot(expiryDate!, isDark),
                label: 'Best before', value: expiryDate!,
                trailing: _ExpiryBadge(expiryDate: expiryDate!, isDark: isDark),
              ),
          ],
        ),
      ),
    );
  }

  static Color _expiryDot(String d, bool isDark) {
    final date = DateTime.tryParse(d);
    if (date == null) return Colors.grey;
    final m = date.difference(DateTime.now()).inDays / 30;
    return m < 3
        ? const Color(0xFFEF9F27)
        : (isDark ? Colors.grey[600]! : const Color(0xFFB4B2A9));
  }
}

class _MetaRow extends StatelessWidget {
  final bool isDark;
  final Color dot;
  final String label, value;
  final bool mono;
  final Widget? trailing;

  const _MetaRow({
    required this.isDark, required this.dot,
    required this.label, required this.value,
    this.mono = false, this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      child: Row(
        children: [
          Container(width: 6, height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 9.5,
                        color: isDark ? Colors.grey[600] : Colors.grey[500],
                        letterSpacing: 0.3)),
                Text(value,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        fontFamily: mono ? 'monospace' : null),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// EXPIRY BADGE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _ExpiryBadge extends StatelessWidget {
  final String expiryDate;
  final bool isDark;
  const _ExpiryBadge({required this.expiryDate, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(expiryDate);
    final String text;
    final bool warn;
    if (date == null) { text = expiryDate; warn = false; }
    else {
      final days = date.difference(DateTime.now()).inDays;
      if (days < 0)       { text = 'Expired';    warn = true; }
      else if (days < 30) { text = '$days days'; warn = true; }
      else { final m = (days / 30).round(); text = '$m months'; warn = m < 3; }
    }
    final bg = warn
        ? (isDark ? const Color(0xFF2C1F07) : const Color(0xFFFAEEDA))
        : (isDark ? const Color(0xFF222220) : const Color(0xFFF1EFE8));
    final color = warn
        ? (isDark ? const Color(0xFFEF9F27) : const Color(0xFF854F0B))
        : (isDark ? Colors.grey[400]! : const Color(0xFF5F5E5A));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// COPY BUTTON
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _CopyButton extends StatefulWidget {
  final String value;
  final bool isDark;
  const _CopyButton({required this.value, required this.isDark});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  void _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _copy,
      child: Container(
        width: 22, height: 22,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade200,
          ),
        ),
        child: Icon(
          _copied ? Icons.check_rounded : Icons.copy_rounded,
          size: 11,
          color: _copied ? Colors.green : Colors.grey[500],
        ),
      ),
    ));
  }
}


// ── Helper: resolve "More from X" label safely ────────────────────────────────
String _webMoreFromLabel(String? brand) {
  final name = brand?.trim();
  if (name == null || name.isEmpty) return 'product.more_from_brand_generic'.tr();
  if (RegExp(r'^\d+$').hasMatch(name)) return 'product.more_from_brand_generic'.tr();
  return 'product.more_from_brand'.tr(args: [name]);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// WEB SECTION TITLE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _WebSectionTitle extends StatelessWidget {
  final IconData? icon;
  final String label;
  const _WebSectionTitle({this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(children: [
      Text(label,
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
    ]);
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CENTERED PRODUCT GRID (max 5, no scroll)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _WebCenteredProductGrid extends StatelessWidget {
  final List<dynamic> products;
  final BuildContext context;
  final bool isAr;
  const _WebCenteredProductGrid({required this.products, required this.context, required this.isAr});

  @override
  Widget build(BuildContext ctx) {
    return LayoutBuilder(
      builder: (_, box) {
        final items = products.take(6).toList();
        return DragScroll(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(items.length, (i) {
                final p = items[i];
                final localizedName = isAr ? (p.nameAr ?? p.name) : p.name;
                return Padding(
                  padding: EdgeInsetsDirectional.only(end: i < items.length - 1 ? 14 : 0),
                  child: SizedBox(
                    width: 180,
                    height: 319,
                    child: ProductCard(
                      productId: p.id, name: localizedName, imageUrl: p.imageUrl,
                      price: p.price, originalPrice: p.originalPrice,
                      rating: p.rating, reviewCount: p.reviewCount,
                      isNew: p.isNew ?? false, isAvailable: p.isAvailable ?? true,
                      isExpressEligible: p.isExpressEligible, isFeatured: p.isFeatured,
                      stockWarning: p.stockWarning, pointsToEarn: p.pointsToEarn,
                      brandName: p.localizedBrandName(context.locale.languageCode),
                      onTap: () => AppNavigator.pushNamed(context,
                          '${Routes.productDetails}/${SlugUtils.slugify(p.name, p.id)}'),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// WEB PRODUCT ROW (kept for alsoBought / brandPicks)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _WebProductRow extends StatelessWidget {
  final List<dynamic> products;
  final BuildContext context;
  final bool isAr;
  const _WebProductRow({required this.products, required this.context, required this.isAr});

  @override
  Widget build(BuildContext ctx) {
    return LayoutBuilder(
      builder: (_, box) {
        final items = products.take(6).toList();
        return DragScroll(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(items.length, (i) {
                final p = items[i];
                final localizedName = isAr ? (p.nameAr ?? p.name) : p.name;
                return Padding(
                  padding: EdgeInsetsDirectional.only(end: i < items.length - 1 ? 14 : 0),
                  child: SizedBox(
                    width: 180,
                    height: 319,
                    child: ProductCard(
                      productId: p.id, name: localizedName, imageUrl: p.imageUrl,
                      brandName: p.localizedBrandName(context.locale.languageCode), // Added brandName
                      price: p.price, originalPrice: p.originalPrice,
                      rating: p.rating, reviewCount: p.reviewCount,
                      isNew: p.isNew ?? false, isAvailable: p.isAvailable ?? true,
                      isExpressEligible: p.isExpressEligible, isFeatured: p.isFeatured,
                      stockWarning: p.stockWarning, pointsToEarn: p.pointsToEarn,
                      onTap: () => AppNavigator.pushNamed(context,
                          '${Routes.productDetails}/${SlugUtils.slugify(p.name, p.id)}'),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}


// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PAYMENT STEPPER (inside BNPL modal)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _PaymentStepper extends StatelessWidget {
  final int installments;
  final String amount;
  final ColorScheme cs;
  final Color cardColor;

  const _PaymentStepper({
    required this.installments, required this.amount,
    required this.cs, required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 16, left: 32, right: 32,
            child: Container(height: 1.5,
                color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(installments, (i) {
              return Expanded(
                child: Column(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                        color: cardColor, shape: BoxShape.circle,
                        border: Border.all(color: cs.outline, width: 1.5)),
                    child: Center(
                      child: Text('${i + 1}',
                          style: TextStyle(color: cs.onSurface,
                              fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FittedBox(fit: BoxFit.scaleDown,
                      child: Text(i == 0 ? 'Today' : '+${i * 30}d',
                          style: TextStyle(fontSize: 11,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600))),
                  const SizedBox(height: 2),
                  FittedBox(fit: BoxFit.scaleDown,
                      child: Text(amount,
                          style: TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w800, color: cs.onSurface))),
                ]),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _WebDiscountBadge extends StatelessWidget {
  final int percent;
  const _WebDiscountBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -3.0),
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: ClipPath(
          clipper: _TagRightClipper(),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 18, 6), // Stable symmetric padding
            decoration: const BoxDecoration(
              color: Color(0xFFE87C82), // Pink from image
            ),
            child: Transform.translate(
              offset: const Offset(0, 2.0), // Visually nudge text down into center
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$percent',
                    style: const TextStyle(
                      fontSize: 20, // Larger for details page
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 2.0),
                     Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('%',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.0)),
                        Transform.translate(
                          offset: const Offset(0, -2.0), // Tighten vertical gap
                          child: const Text('OFF', // ALL CAPS
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.0)),
                        ),
                      ],
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TagRightClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width - 8, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width - 8, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}


// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BREADCRUMB
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _ProductBreadcrumb extends StatelessWidget {
  final ProductDetailsEntity product;
  final bool isDark;

  const _ProductBreadcrumb({required this.product, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final dimColor = isDark ? Colors.white38 : Colors.black38;
    final activeColor = isDark ? Colors.white : Colors.black87;
    const linkColor = ColorsManager.primaryColor;
    final isAr = context.locale.languageCode == 'ar';

    Widget separator() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(Icons.chevron_right_rounded, size: 16, color: dimColor),
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Home
        SafeMouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: () => AppNavigator.pushNamed(context, Routes.dashBoard),
            child: Text('dashboard.home'.tr(), style: const TextStyle(
              fontSize: 13, color: linkColor, fontWeight: FontWeight.w600,
            )),
          ),
        ),
        
        // Category
        if (product.categoryName != null && product.categoryName!.isNotEmpty) ...[
          separator(),
          SafeMouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
              onTap: () {
                if (product.category != null) {
                  final cat = CategoryEntity(
                    id: product.category!,
                    name: product.categoryName!,
                    nameAr: product.categoryNameAr ?? product.categoryName!,
                    iconUrl: '',
                  );
                  AppNavigator.pushNamed(
                    context, 
                    '${Routes.categoryProducts}/${SlugUtils.slugify(product.categoryName!, product.category!)}',
                    arguments: cat,
                  );
                }
              },
              child: Text(
                isAr ? (product.categoryNameAr ?? product.categoryName!) : product.categoryName!,
                style: TextStyle(
                  fontSize: 13, color: product.subcategoryName != null ? linkColor : activeColor, fontWeight: FontWeight.w600,
                )),
            ),
          ),
        ],

        // Subcategory
        if (product.subcategoryName != null && product.subcategoryName!.isNotEmpty) ...[
          separator(),
          SafeMouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
              onTap: () {
                if (product.subcategoryId != null) {
                  final subCat = CategoryEntity(
                    id: product.subcategoryId!,
                    name: product.subcategoryName!,
                    nameAr: product.subcategoryNameAr ?? product.subcategoryName!,
                    iconUrl: '',
                  );
                  AppNavigator.pushNamed(
                    context, 
                    '${Routes.categoryProducts}/${SlugUtils.slugify(product.subcategoryName!, product.subcategoryId!)}',
                    arguments: subCat,
                  );
                }
              },
              child: Text(
                isAr ? (product.subcategoryNameAr ?? product.subcategoryName!) : product.subcategoryName!,
                style: TextStyle(
                  fontSize: 13, color: activeColor, fontWeight: FontWeight.w600,
                )),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meta Cards (Cold Shipping / Express)
// ─────────────────────────────────────────────────────────────────────────────

class _ProductMetaCard extends StatelessWidget {
  final bool requiresColdShipping;
  final bool isExpressEligible;
  final bool isDark;

  const _ProductMetaCard({
    required this.requiresColdShipping,
    required this.isExpressEligible,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (!requiresColdShipping) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (requiresColdShipping) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.ac_unit_rounded, color: Color(0xFF0EA5E9), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'product.cold_chain_shipping'.tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0EA5E9),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'product.cold_chain_desc'.tr(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MAGNIFIER IMAGE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _MagnifierImage extends StatefulWidget {
  final String imageUrl;
  final bool isNarrow;
  final List<String> allImages;
  final int currentIndex;

  const _MagnifierImage({
    super.key, 
    required this.imageUrl,
    this.isNarrow = false,
    this.allImages = const [],
    this.currentIndex = 0,
  });

  @override
  State<_MagnifierImage> createState() => _MagnifierImageState();
}

class _MagnifierImageState extends State<_MagnifierImage> {
  Offset? _mousePosition;

  void _openFullScreen() {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: FullScreenGallery(
              images: widget.allImages,
              initialIndex: widget.currentIndex,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isNarrow) {
      return GestureDetector(
        onTap: widget.allImages.isNotEmpty ? _openFullScreen : null,
        child: Hero(
          tag: widget.imageUrl,
          child: CachedNetworkImage(
            key: const ValueKey('normal'),
            imageUrl: widget.imageUrl,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          cursor: SystemMouseCursors.zoomIn,
          onEnter: (e) => setState(() => _mousePosition = e.localPosition),
          onHover: (e) => setState(() => _mousePosition = e.localPosition),
          onExit: (e) => setState(() => _mousePosition = null),
          child: ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _mousePosition == null
                  ? CachedNetworkImage(
                      key: const ValueKey('normal'),
                      imageUrl: widget.imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : Transform.scale(
                      scale: 2.0,
                      alignment: FractionalOffset(
                        (_mousePosition!.dx / constraints.maxWidth).clamp(0.0, 1.0),
                        (_mousePosition!.dy / constraints.maxHeight).clamp(0.0, 1.0),
                      ),
                      child: CachedNetworkImage(
                        key: const ValueKey('zoomed'),
                        imageUrl: widget.imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
