import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fastway/core/di/injection_container.dart';
import 'package:fastway/features/product_details/presentation/cubit/product_details_cubit.dart';
import 'package:fastway/features/product_details/presentation/cubit/product_details_state.dart';
import 'package:fastway/features/product_details/presentation/widgets/product_image_gallery.dart';
import 'package:fastway/core/widgets/sar_symbol.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/features/home/presentation/widget/card/animated_cart_button.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:easy_localization/easy_localization.dart';

void showQuickView(BuildContext context, String productId) {
  final isMobile = MediaQuery.of(context).size.width < 600;

  if (isMobile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider(
        create: (_) => sl<ProductDetailsCubit>()..loadProductDetails(productId),
        child: const _QuickViewBottomSheet(),
      ),
    );
  } else {
    showDialog(
      context: context,
      builder: (context) => BlocProvider(
        create: (_) => sl<ProductDetailsCubit>()..loadProductDetails(productId),
        child: const _QuickViewDialog(),
      ),
    );
  }
}

class _QuickViewBottomSheet extends StatelessWidget {
  const _QuickViewBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Flexible(child: _QuickViewContent()),
        ],
      ),
    );
  }
}

class _QuickViewDialog extends StatelessWidget {
  const _QuickViewDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 600, // Comfortable width for web
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Stack(
          children: [
            const _QuickViewContent(),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickViewContent extends StatelessWidget {
  const _QuickViewContent();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = context.locale.languageCode == 'ar';

    return BlocBuilder<ProductDetailsCubit, ProductDetailsState>(
      builder: (context, state) {
        if (state is ProductDetailsLoading || state is ProductDetailsInitial) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProductDetailsError) {
          return SizedBox(
            height: 300,
            child: Center(child: Text(state.message)),
          );
        }

        if (state is! ProductDetailsLoaded) {
          return const SizedBox.shrink();
        }

        final product = state.product;
        List<String> images = product.galleryImages.isNotEmpty 
            ? product.galleryImages 
            : [product.imageUrl];

        final brandName = product.brand ?? product.categoryName ?? '';
        final productName = isAr ? (product.nameAr ?? product.name) : product.name;
        final productDesc = isAr ? (product.descriptionAr ?? product.description) : product.description;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Gallery
              SizedBox(
                height: 300,
                width: double.infinity,
                child: ProductImageGallery(
                  images: images, 
                  isNew: product.isNew, 
                  discountPercent: product.originalPrice != null && product.originalPrice! > product.price 
                    ? (((product.originalPrice! - product.price) / product.originalPrice!) * 100).round() 
                    : null
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (brandName.isNotEmpty)
                      Text(
                        brandName,
                        style: TextStyle(
                          color: const Color(0xFF00BFA5),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    if (brandName.isNotEmpty) const SizedBox(height: 6),

                    Text(
                      productName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Price Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SarText(
                          price: product.price.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: product.isAvailable ? ColorsManager.primaryColor : Colors.grey,
                            height: 1.1,
                          ),
                        ),
                        if (product.originalPrice != null) ...[
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2.0),
                            child: SarText(
                              price: product.originalPrice!.toStringAsFixed(2),
                              strikeThrough: false,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (product.rating != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  product.rating!.toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 20),
                    
                    // Description without maxLines so it shows fully
                    Text(
                      isAr ? 'الوصف' : 'Description',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    HtmlWidget(
                      productDesc,
                      textStyle: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                        height: 1.6,
                        fontSize: 14,
                      ),
                    ),
                    
                    if (product.ingredients.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(isAr ? 'المكونات' : 'Ingredients', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 10),
                      Text(
                        (isAr && product.ingredientsAr.isNotEmpty ? product.ingredientsAr : product.ingredients).join(' • '),
                        maxLines: 100,
                        softWrap: true,
                        style: TextStyle(
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                          height: 1.5,
                        ),
                      ),
                    ],

                    if (product.benefits.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(isAr ? 'الفوائد' : 'Benefits', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 10),
                      Text(
                        (isAr && product.benefitsAr.isNotEmpty ? product.benefitsAr : product.benefits).join(' • '),
                        maxLines: 100,
                        softWrap: true,
                        style: TextStyle(
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                          height: 1.5,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    if (product.isAvailable)
                      SizedBox(
                        height: 50,
                        width: double.infinity,
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
                      )
                    else
                      Container(
                        height: 50,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          isAr ? 'نفذت الكمية' : 'Out of Stock',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
