import 'package:fastway/core/routes/app_navigator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/utils/slug_utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../../domain/entities/wishlist_entity.dart';
import '../../presentation/cubit/wishlist_cubit.dart';
import '../../presentation/cubit/wishlist_state.dart';
import 'package:fastway/features/home/presentation/widget/card/product_card.dart';
import 'package:fastway/features/home/presentation/widget/card/products_row.dart';
import 'package:fastway/features/home/domain/entities/product_entity.dart';

class CartWishlistReminder extends StatelessWidget {
  const CartWishlistReminder({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WishlistCubit, WishlistState>(
      builder: (context, wishlistState) {
        if (wishlistState is! WishlistLoaded) return const SizedBox.shrink();
        final wishlistItems = wishlistState.wishlist.items;
        if (wishlistItems.isEmpty) return const SizedBox.shrink();

        return BlocBuilder<CartCubit, CartState>(
          builder: (context, cartState) {
            final cartProductIds = <String>{};
            if (cartState is CartLoaded) {
              cartProductIds.addAll(cartState.cart.items.map((i) => i.productId));
            }

            final notInCart = wishlistItems
                .where((w) => !cartProductIds.contains(w.productId))
                .toList();

            if (notInCart.isEmpty) return const SizedBox.shrink();

            return _WishlistReminderStrip(items: notInCart);
          },
        );
      },
    );
  }
}

class _WishlistReminderStrip extends StatelessWidget {
  final List<WishlistItemEntity> items;
  const _WishlistReminderStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    final products = items.map((item) => ProductEntity(
      id: item.productId,
      name: item.productName,
      nameAr: item.productNameAr,
      imageUrl: item.imageUrl ?? '',
      price: item.price,
      originalPrice: item.originalPrice,
      rating: item.rating,
      reviewCount: item.reviewCount,
      isAvailable: item.isAvailable,
    )).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.favorite, color: Colors.red.shade400, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'wishlist.reminder_title'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => AppNavigator.pushNamed(context, Routes.wishlist),
                behavior: HitTestBehavior.opaque,
                child: Text(
                  'wishlist.reminder_see_all'.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ColorsManager.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Opt the mouse back in as a drag device: AppScrollBehavior excludes it
        // app-wide so that click-dragging selects text instead of scrolling.
        // A carousel has no selectable text and users expect to drag it.
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            },
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(products.length, (i) {
              final product = products[i];
              return Padding(
                padding: EdgeInsetsDirectional.only(end: i < products.length - 1 ? 14 : 0),
                child: SizedBox(
                  width: 180,
                  height: 319,
                  child: ProductCard(
                    productId: product.id,
                    name: product.name,
                    imageUrl: product.imageUrl,
                    price: product.price,
                    originalPrice: product.originalPrice,
                    rating: product.rating,
                    reviewCount: product.reviewCount,
                    isNew: product.isNew ?? false,
                    isAvailable: product.isAvailable ?? true,
                    isExpressEligible: product.isExpressEligible,
                    isFeatured: product.isFeatured,
                    stockWarning: product.stockWarning,
                    pointsToEarn: product.pointsToEarn,
                    brandName: product.localizedBrandName(context.locale.languageCode),
                    onTap: () => AppNavigator.pushNamed(
                        context, '${Routes.productDetails}/${SlugUtils.slugify(product.name, product.id)}'),
                  ),
                ),
              );
            }),
            ),
          ),
        ),
      ],
    );
  }
}
