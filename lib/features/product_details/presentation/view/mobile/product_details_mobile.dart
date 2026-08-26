import 'package:fastway/core/layout/web_nav_controller.dart';
import 'package:fastway/core/utils/assets.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:fastway/core/utils/slug_utils.dart';
// lib/features/product_details/presentation/view/mobile/product_details_mobile.dart
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/widgets/CustomIcon.dart';
import 'package:fastway/features/home/presentation/widget/card/animated_cart_button.dart';
import 'package:fastway/features/home/presentation/widget/card/product_card.dart';
import 'package:fastway/features/product_details/domain/entities/product_details_entity.dart';
import 'package:fastway/features/product_details/presentation/cubit/product_details_cubit.dart';
import 'package:fastway/core/widgets/shared_bottom_nav_bar.dart';
import 'package:fastway/features/user_data/user_cubit.dart';
import 'package:fastway/features/product_details/presentation/widgets/product_bundle_widget.dart';
import 'package:fastway/features/product_details/presentation/widgets/variant_selector.dart';
import 'package:fastway/features/product_details/presentation/widgets/product_details_shared.dart';
import 'package:fastway/features/product_details/presentation/widgets/product_image_gallery.dart';
import 'package:fastway/features/product_details/presentation/widgets/product_info_section.dart';
import 'package:fastway/features/product_details/presentation/widgets/notify_me_button.dart';
import 'package:fastway/core/widgets/wishlist_heart_button.dart';
import 'package:fastway/core/widgets/share_product_button.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fastway/core/widgets/sar_symbol.dart';
import 'package:fastway/core/widgets/loyalty_points_bar.dart';
import 'package:fastway/core/routes/app_navigator.dart';
import 'dart:ui' as ui;

class ProductDetailsMobile extends StatelessWidget {
  final ProductDetailsEntity product;
  final String productId;
  final int quantity;
  final List<dynamic> questions;
  final bool questionsLoading;
  final void Function(String) onVariantSwitch;

  const ProductDetailsMobile({
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
    final cs = Theme.of(context).colorScheme;
    final isAr = context.locale.languageCode == 'ar';
    final discountPercent = product.originalPrice != null && product.originalPrice! > product.price
        ? (((product.originalPrice! - product.price) / product.originalPrice!) * 100).round() : null;

    final reviewsKey = GlobalKey();
    void scrollToReviews() {
      final ctx = reviewsKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            product.isAvailable
                ? _BottomBar(product: product, quantity: quantity)
                : _OutOfStockBar(productId: productId),
            SharedBottomNavBar(
              currentIndex: -1, // No tab active since we are deep in product details
              onTap: (index) {
                try {
                  context.read<WebNavController>().navigateTo(index);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                } catch (_) {
                  WebNavController.instance.navigateTo(index);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              isDark: isDark,
            ),
          ],
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
              elevation: 0,
              leadingWidth: 72,
              leading: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black54 : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black54 : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: ShareProductButton(
                            productId: productId,
                            productName: isAr ? (product.nameAr ?? product.name) : product.name,
                            noBackground: true,
                            iconSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black54 : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: WishlistHeartButton(
                            productId: productId,
                            noBackground: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 370,
                child: ProductImageGallery(images: product.galleryImages),
              ),
            ),

            SliverToBoxAdapter(
              child: Container(
                color: isDark ? Colors.transparent : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // ── Variant / Flavor selector ──────────────────────────
                    if (product.variants.isNotEmpty) ...[
                      VariantSelector(
                        variants: product.variants,
                        currentProductId: productId,
                        currentProductSku: product.sku,
                        isDark: isDark,
                        isAr: isAr,
                        groupLabel: isAr ? (product.variantGroupLabelAr ?? product.variantGroupLabel) : product.variantGroupLabel,
                        onVariantSwitch: onVariantSwitch,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Badges (Best Seller, New) ──────────────────────────────────────
                    if (product.isFeatured || (product.isNew ?? false)) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product.isFeatured)
                            Padding(
                              padding: EdgeInsets.only(bottom: (product.isNew ?? false) ? 8.0 : 0.0),
                              child: _BestSellerBadge(isDark: isDark, isAr: isAr),
                            ),
                          if (product.isNew ?? false)
                            _NewBadge(isDark: isDark, isAr: isAr),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Brand Card (Moved to top) ──────────────────────
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

                    // Product info (name, price, rating, badges)
                    ProductInfoSection(
                      name: isAr ? (product.nameAr ?? product.name) : product.name,
                      brand: product.brand ?? '',
                      price: product.price,
                      originalPrice: product.originalPrice,
                      rating: product.rating,
                      reviewCount: product.reviewCount,
                      isAvailable: product.isAvailable,
                      isNew: product.isNew ?? false,
                      isExpressEligible: product.isExpressEligible,
                      isFeatured: product.isFeatured,
                      stockWarning: product.stockWarning,
                      pointsToEarn: product.pointsToEarn,
                      discountPercent: discountPercent,
                      hasPromotion: product.hasPromotion,
                      promotionEndsAt: product.promotionEndsAt,
                      requiresColdShipping: product.requiresColdShipping,
                      expiryDate: product.expiryDate,
                      onRatingTap: product.reviews.isNotEmpty ? scrollToReviews : null,
                    ),


                    // ── Loyalty Points Bar ──
                    if (product.pointsToEarn != null && product.pointsToEarn! > 0) ...[
                      LoyaltyPointsBar(points: product.pointsToEarn!),
                      const SizedBox(height: 16),
                    ],

                    // ── Cold Shipping / Express meta card ──
                    _ProductMetaCard(
                      requiresColdShipping: product.requiresColdShipping,
                      isExpressEligible: product.isExpressEligible,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // Payment methods with real icons + modal
                    _PaymentCard(isDark: isDark, price: product.price),
                    const SizedBox(height: 20),

                    // Bundle components (products in this bundle)
                    if (product.isBundle && product.bundleComponents.isNotEmpty) ...[
                      // ── extract savings amount safely ──
                      Builder(builder: (context) {
                        final dynamic bSavings = product.bundleSavings;
                        final double amount = bSavings != null
                            ? (bSavings is double ? bSavings : (bSavings.amount ?? 0.0))
                            : 0.0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // premium header (replaces _SectionLabel for bundle)
                            BundleSectionHeader(
                              savingsAmount: amount,
                              currencyLabel: 'product.currency'.tr(),
                            ),
                            const SizedBox(height: 16),

                            // the bundle card with animated border
                            ProductBundleWidget(components: product.bundleComponents),
                            const SizedBox(height: 28),
                          ],
                        );
                      }),
                    ],

                    // Accordions
                    if (product.description.isNotEmpty)
                      ProductAccordion(title: 'tab_description'.tr(), icon: Icons.subject_rounded, initiallyExpanded: false,
                          child: SizedBox(
                            width: double.infinity,
                            child: HtmlWidget(
                              isAr ? (product.descriptionAr ?? product.description) : product.description,
                              textStyle: TextStyle(fontSize: 15.0, height: 1.85, color: cs.onSurfaceVariant),
                            ),
                          )),

                    if ((product.sku != null && product.sku!.isNotEmpty) || (product.expiryDate != null && product.expiryDate!.isNotEmpty))
                      ProductAccordion(title: 'product.features'.tr(), icon: Icons.info_outline_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.sku != null && product.sku!.isNotEmpty) ...[
                                Text('product.sku'.tr(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
                                const SizedBox(height: 2),
                                Text(product.sku!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface, letterSpacing: 1.2, fontFamily: 'monospace')),
                                if (product.expiryDate != null && product.expiryDate!.isNotEmpty) const SizedBox(height: 16),
                              ],
                              if (product.expiryDate != null && product.expiryDate!.isNotEmpty) ...[
                                Text('product.best_before'.tr(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
                                const SizedBox(height: 2),
                                Text(product.expiryDate!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface)),
                              ],
                            ],
                          )),
                    if (product.nutritionFacts != null)
                      ProductAccordion(title: 'tab_nutrition'.tr(), icon: Icons.bolt_rounded,
                          child: ProductNutritionWidget(facts: product.nutritionFacts!)),
                    if (product.ingredients.isNotEmpty)
                      ProductAccordion(title: 'tab_ingredients'.tr(), icon: Icons.science_outlined,
                          child: Wrap(spacing: 8, runSpacing: 8, children: (isAr && product.ingredientsAr.isNotEmpty ? product.ingredientsAr : product.ingredients).map((i) =>
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: ColorsManager.primaryColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: ColorsManager.primaryColor.withValues(alpha: 0.2)),
                                ),
                                child: Text(i, style: const TextStyle(fontSize: 12, color: ColorsManager.primaryColor, fontWeight: FontWeight.w500)),
                              )).toList())),
                    if (product.usage.isNotEmpty)
                      ProductAccordion(title: 'product.usage'.tr(), icon: Icons.info_outline_rounded,
                          child: Text(
                            isAr ? (product.usageAr ?? product.usage) : product.usage,
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            style: TextStyle(fontSize: 14, height: 1.75, color: cs.onSurfaceVariant),
                          )),
                    if (product.reviews.isNotEmpty)
                      ProductAccordion(key: reviewsKey, title: 'tab_reviews'.tr(), icon: Icons.reviews_outlined,
                          child: ProductReviewsWidget(reviews: product.reviews)),
                    // Q&A accordion — live data from cubit
                    if (product.showQuestions)
                      ProductAccordion(title: 'product.qa.title'.tr(), icon: Icons.help_outline_rounded,
                          child: questionsLoading
                              ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                              : ProductQAWidget(
                            questions: List<ProductQuestion>.from(questions),
                            productId: productId,
                            isAuthenticated: context.read<UserCubit>().isLoggedIn,
                            onSubmitQuestion: (q) => context.read<ProductDetailsCubit>().submitQuestion(productId, q),
                          )),


                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
            
          SliverToBoxAdapter(
            child: Container(
              color: Colors.transparent,
                padding: const EdgeInsets.only(top: 24, bottom: 40),
                child: Column(
                  children: [
                    if (product.alsoBought.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _SectionLabel(label: 'product.customers_also_bought'.tr(), isDark: isDark),
                      ),
                      const SizedBox(height: 8),
                      _HProductRow(products: product.alsoBought, context: context),
                      const SizedBox(height: 28),
                    ],

                    if (product.brandPicks.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _SectionLabel(
                            label: _moreFromLabel(product.brand, isAr: context.locale.languageCode == 'ar'),
                            isDark: isDark),
                      ),
                      const SizedBox(height: 12),
                      _CenteredProductGrid(products: product.brandPicks, context: context),
                      const SizedBox(height: 28),
                    ],

                    if (product.relatedProducts.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _SectionLabel(label: 'product.you_might_also_like'.tr(), isDark: isDark),
                      ),
                      const SizedBox(height: 12),
                      _CenteredProductGrid(products: product.relatedProducts, context: context),
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

// ── Brand + Category + SKU row ────────────────────────────────────────────────
class _BrandCategoryRow extends StatelessWidget {
  final ProductDetailsEntity product;
  final bool isDark;
  const _BrandCategoryRow({required this.product, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (product.brand != null && product.brand!.isNotEmpty) {
      items.add(_InfoPill(icon: Icons.storefront_rounded, text: product.brand!, color: ColorsManager.primaryColor));
    }
    if (product.categoryName != null && product.categoryName!.isNotEmpty) {
      items.add(_InfoPill(icon: Icons.category_rounded, text: product.categoryName!, color: Colors.teal));
    }
    if (product.sku != null) {
      items.add(_InfoPill(icon: Icons.qr_code_rounded, text: 'SKU: ${product.sku}', color: Colors.grey));
    }
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 6, children: items);
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon; final String text; final Color color;
  const _InfoPill({required this.icon, required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
      ]),
    );
  }
}

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
      borderRadius: BorderRadius.circular(12),
      child: brandLogoUrl != null && brandLogoUrl!.isNotEmpty
          ? CachedNetworkImage(imageUrl: brandLogoUrl!,
              width: 56,
              height: 40,
              fit: BoxFit.contain,
              errorWidget: (_, __, ___) => _BrandLogoFallback(brand: brand, isDark: isDark),
            )
          : _BrandLogoFallback(brand: brand, isDark: isDark),
    );

    final divider = Container(width: 1, height: 40, color: borderColor);

    final brandInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          textAlign: TextAlign.start,
          TextSpan(
            children: [
              TextSpan(text: brand),
              const WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(Icons.verified_rounded, size: 14, color: Color(0xFF1D9BF0)),
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
    );

    final button = GestureDetector(
      onTap: onViewAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white : Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'product.brand_view_all'.tr(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.black : Colors.white,
          ),
        ),
      ),
    );

    // Always: [Logo] [divider] [Brand info] [spacer] [Button]
    // Flutter's Directionality handles LTR/RTL text automatically.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
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

// ── Best Seller badge widget ───────────────────────────────────────────────────
class _BestSellerBadge extends StatelessWidget {
  final bool isDark;
  final bool isAr;
  const _BestSellerBadge({required this.isDark, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF323673),
        borderRadius: BorderRadius.circular(12),
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

// ── New badge widget ───────────────────────────────────────────────────
class _NewBadge extends StatelessWidget {
  final bool isDark;
  final bool isAr;
  const _NewBadge({required this.isDark, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ColorsManager.primary2Color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Transform.translate(
        offset: const Offset(0, 2.0), // Visually nudge down to center
        child: Text(
          'product.badge_new'.tr(),
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

class _BrandLogoFallback extends StatelessWidget {
  final String brand;
  final bool isDark;
  const _BrandLogoFallback({required this.brand, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    width: 52, height: 38,
    decoration: BoxDecoration(
      color: isDark ? Colors.white10 : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    alignment: Alignment.center,
    child: Text(
      brand.substring(0, brand.length > 2 ? 2 : brand.length).toUpperCase(),
      style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.w500,
        color: ColorsManager.primaryColor,
      ),
    ),
  );
}

// ── Payment card with real SVGs + installment modal ──────────────────────────
class _PaymentCard extends StatelessWidget {
  final bool isDark;
  final double price;
  const _PaymentCard({required this.isDark, required this.price});

  void _showInstallmentModal(BuildContext context, String provider) {
    final isTabby = provider == 'tabby';
    final color = isTabby ? const Color(0xFF3DBFAD) : const Color(0xFF5E35B1);
    final installments = isTabby ? 4 : 3;
    final amount = (price / installments).toStringAsFixed(2);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.zero),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 20),
          Image.asset(provider == 'tabby' ? Assets.tabbyIcon : Assets.tamaraIcon, height: 125),
          const SizedBox(height: 20),
          Text('Pay in $installments interest-free installments',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          SarText(
            price: '$installments x $amount',
            symbolFirst: false,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 8),
          Text('No hidden fees. No interest.', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 24),
          // Timeline dots
          Row(
            children: List.generate(installments, (i) => Expanded(child: Column(children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.4))),
                  child: Center(child: Text('${i+1}', style: TextStyle(color: color, fontWeight: FontWeight.w800)))),
              const SizedBox(height: 6),
              Text(i == 0 ? 'Today' : '+${i * 30}d', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              SarText(
                price: amount,
                symbolFirst: false,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
              ),
            ]))),
          ),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Continue with ${isTabby ? 'Tabby' : 'Tamara'}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              )),
          const SizedBox(height: 8),
        ]),
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
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
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
        // Card icons row
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
                    child: GestureDetector(
                      onTap: () => _showInstallmentModal(context, 'tabby'),
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
                    ),
                  ),
                  VerticalDivider(width: 1, thickness: 1, color: isDark ? Colors.white12 : Colors.grey.shade300),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () => _showInstallmentModal(context, 'tamara'),
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
                    ),
                  ),
                ],
              ),
            ),
              ),
            ),
          ),
      ]),
    );
  }
}

class _CardBadge extends StatelessWidget {
  final String label; final Color bg, fg; final bool border;
  const _CardBadge({required this.label, required this.bg, required this.fg, this.border = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12),
        border: border ? Border.all(color: Colors.grey.shade300) : null),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: fg)),
  );
}

// ── Product Meta Card (Cold Shipping + Express) ─────────────────
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
    // Nothing to show? skip the card entirely
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

          // ── Cold Shipping ──
          if (requiresColdShipping) ...[
            _MetaRow(
              icon: Icons.ac_unit_rounded,
              iconColor: const Color(0xFF0EA5E9),
              iconBg: Colors.transparent,
              iconSize: 28,
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
        ],
     ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Widget child;
  final double? iconSize;

  const _MetaRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.child,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: iconSize ?? 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: child,
        )),
      ],
    );
  }
}

// Decorative barcode lines widget
class _BarcodeLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    // Generate a pseudo-random-looking but deterministic barcode pattern
    final widths = [2.0, 1.0, 3.0, 1.0, 2.0, 1.0, 1.0, 3.0, 2.0, 1.0, 3.0, 1.0, 2.0, 1.0, 2.0, 3.0, 1.0, 2.0, 1.0, 3.0];
    return SizedBox(
      height: 28,
      child: Row(
        children: widths.asMap().entries.map((e) {
          final isBar = e.key % 2 == 0;
          return Container(
            width: e.value * 3,
            height: 28,
            color: isBar ? barColor : Colors.transparent,
            margin: const EdgeInsets.only(right: 1),
          );
        }).toList(),
      ),
    );
  }
}

// ── Express badge removed as it was unused ───────────────────────────────────


// ── Helper: resolve "More from X" label safely ────────────────────────────────
// The API sometimes returns a brand name, sometimes a numeric ID in json['brand'].
// If it looks like a pure number (ID), fall back to the generic label.
String _moreFromLabel(String? brand, {required bool isAr}) {
  final name = brand?.trim();
  if (name == null || name.isEmpty) return 'product.more_from_brand_generic'.tr();
  // If the value is purely numeric it's an ID, not a name — hide it
  if (RegExp(r'^\d+$').hasMatch(name)) return 'product.more_from_brand_generic'.tr();
  return 'product.more_from_brand'.tr(args: [name]);
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final IconData? icon; final String label; final bool isDark; final Color? accent;
  const _SectionLabel({this.icon, required this.label, required this.isDark, this.accent});
  @override
  Widget build(BuildContext context) {
    final c = accent ?? ColorsManager.primaryColor;
    return Row(children: [
      if (icon != null) ...[
        Container(width: 32, height: 32,
            decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 16, color: c)),
        const SizedBox(width: 10),
      ],
      Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
    ]);
  }
}

// ── Centered product grid (max 5, no scroll) ──────────────────────────────────
class _CenteredProductGrid extends StatelessWidget {
  final List<dynamic> products;
  final BuildContext context;
  const _CenteredProductGrid({required this.products, required this.context});

  @override
  Widget build(BuildContext ctx) {
    final isAr = context.locale.languageCode == 'ar';
    final capped = products.take(5).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: capped.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            final localizedName = isAr ? (p.nameAr ?? p.name) : p.name;
            return Padding(
              padding: EdgeInsetsDirectional.only(end: i < capped.length - 1 ? 14 : 0),
              child: SizedBox(
                width: 155,
                height: 274,
                child: ProductCard(
                  productId: p.id, name: localizedName, imageUrl: p.imageUrl,
                  brandName: p.localizedBrandName(context.locale.languageCode),
                  price: p.price, originalPrice: p.originalPrice,
                  rating: p.rating, reviewCount: p.reviewCount,
                  isNew: p.isNew ?? false, isAvailable: p.isAvailable ?? true,
                  isExpressEligible: p.isExpressEligible, isFeatured: p.isFeatured,
                  stockWarning: p.stockWarning, pointsToEarn: p.pointsToEarn,
                  onTap: () => AppNavigator.pushNamed(context, '${Routes.productDetails}/${SlugUtils.slugify(p.name, p.id)}'),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _HProductRow extends StatelessWidget {
  final List<dynamic> products;
  final BuildContext context;
  const _HProductRow({required this.products, required this.context});
  @override
  Widget build(BuildContext ctx) {
    final isAr = context.locale.languageCode == 'ar';
    return SizedBox(
      height: 274, // = 155 / kProductCardAspectRatio — keeps the image box square
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final p = products[i];
          final localizedName = isAr ? (p.nameAr ?? p.name) : p.name;
          return SizedBox(width: 155, child: ProductCard(
            productId: p.id, name: localizedName, imageUrl: p.imageUrl,
            brandName: p.localizedBrandName(context.locale.languageCode), // Added brandName
            price: p.price, originalPrice: p.originalPrice,
            rating: p.rating, reviewCount: p.reviewCount,
            isNew: p.isNew ?? false, isAvailable: p.isAvailable ?? true,
            isExpressEligible: p.isExpressEligible, isFeatured: p.isFeatured,
            stockWarning: p.stockWarning, pointsToEarn: p.pointsToEarn,
            onTap: () => AppNavigator.pushNamed(context, '${Routes.productDetails}/${SlugUtils.slugify(p.name, p.id)}'),
          ));
        },
      ),
    );
  }
}

// ── Out of stock bar ──────────────────────────────────────────────────────────
class _OutOfStockBar extends StatelessWidget {
  final String productId;
  const _OutOfStockBar({required this.productId});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      border: const Border(top: BorderSide(color: Color(0x0F000000), width: 1)),
    ),
    child: NotifyMeButton(productId: productId, height: 50),
  );
}

// ── Bottom bar ────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final ProductDetailsEntity product; final int quantity;
  const _BottomBar({required this.product, required this.quantity});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      decoration: BoxDecoration(
        color: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
        border: const Border(top: BorderSide(color: Color(0x12000000), width: 1)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          height: 50,
          child: AnimatedCartButtonCompact(
            productId: product.id,
            productName: product.name,
            price: product.price,
            originalPrice: product.originalPrice,
            imageUrl: product.imageUrl,
            isAvailable: product.isAvailable,
            expandWidth: true,
            autoCollapse: false,
          ),
        ),
      ]),
    );
  }
}


