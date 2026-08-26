
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:fastway/core/utils/slug_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fastway/core/widgets/safe_mouse_region.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/layout/simple_web_shell.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_snack_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/skeletons.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../features/home/presentation/widget/card/product_card.dart';
import '../cubit/wishlist_cubit.dart';
import '../cubit/wishlist_state.dart';
import '../../domain/entities/wishlist_entity.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../../../../features/user_data/user_cubit.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}



class _WishlistScreenState extends State<WishlistScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!context.read<UserCubit>().isLoggedIn) return;
    final current = context.read<WishlistCubit>().state;
    if (current is! WishlistLoaded) {
      context.read<WishlistCubit>().loadWishlist();
    }
  }

  void _removeWithUndo(BuildContext ctx, WishlistItemEntity item) {
    context.read<WishlistCubit>().removeItem(
          item.wishlistItemId,
          productId: item.productId,
        );
    ScaffoldMessenger.of(ctx).clearSnackBars();
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('wishlist.remove_success'.tr()),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'common.cancel'.tr(),
          onPressed: () async {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text('wishlist.undo_restoring'.tr()),
              duration: const Duration(seconds: 2),
            ));
            await context.read<WishlistCubit>().toggleProduct(item.productId);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final onWeb = isWebLayout(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<CartCubit, CartState>(
          listener: (context, state) {
            if (state is AddedToCart) {
              CustomSnackBar.show(context, message: state.message);
            } else if (state is CartError) {
              CustomSnackBar.show(context,
                  message: state.failure.message, type: SnackBarType.error);
            }
          },
        ),
        BlocListener<WishlistCubit, WishlistState>(
          listener: (context, state) {
            if (state is WishlistError) {
              CustomSnackBar.show(context,
                  message: 'wishlist.toggle_error'.tr(),
                  type: SnackBarType.error);
            }
            if (state is WishlistItemAdded) {
              CustomSnackBar.show(context,
                  message: 'wishlist.add_success'.tr());
            }
          },
        ),
      ],
      child: onWeb ? _buildWeb(context) : _buildMobile(context),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WEB layout — SimpleWebShell with Amazon/Noon style product grid
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildWeb(BuildContext context) {
    return SimpleWebShell(
      content: BlocBuilder<WishlistCubit, WishlistState>(
        buildWhen: (p, c) {
          if (c is WishlistItemToggling ||
              c is WishlistItemAdded ||
              c is WishlistItemRemoved) {
            return false;
          }
          if (c is WishlistLoading &&
              (p is WishlistItemRemoved ||
                  p is WishlistItemAdded ||
                  p is WishlistItemToggling)) {
            return false;
          }
          return true;
        },
        builder: (context, state) {
          if (state is WishlistLoading) return _WebSkeleton();
          if (state is WishlistError) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: ErrorStateWidget(
                failure: state.failure,
                onRetry: () => context.read<WishlistCubit>().loadWishlist(),
              ),
            );
          }
          if (state is WishlistLoaded) {
            final items = state.wishlist.items;
            if (items.isEmpty) {
              return _WebEmptyState();
            }
            return _WebBody(
              items: items,
              onRemove: (item) => _removeWithUndo(context, item),
            );
          }
          // Guest / initial
          return _WebGuestState();
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MOBILE layout — unchanged Scaffold + list
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMobile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F8F8);

    return Scaffold(
      backgroundColor: bg,
      appBar: CustomAppBar(
        title: 'wishlist.title'.tr(),
        extraActions: [
          BlocBuilder<WishlistCubit, WishlistState>(
            builder: (context, state) => IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'common.retry'.tr(),
              onPressed: state is WishlistLoading
                  ? null
                  : () => context.read<WishlistCubit>().loadWishlist(),
            ),
          ),
        ],
      ),
      body: BlocBuilder<WishlistCubit, WishlistState>(
        buildWhen: (p, c) {
          if (c is WishlistItemToggling ||
              c is WishlistItemAdded ||
              c is WishlistItemRemoved) {
            return false;
          }
          if (c is WishlistLoading &&
              (p is WishlistItemRemoved ||
                  p is WishlistItemAdded ||
                  p is WishlistItemToggling)) {
            return false;
          }
          return true;
        },
        builder: (context, state) {
          if (state is WishlistLoading) {
            return Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CartItemSkeleton(),
                  SizedBox(height: 12.h),
                  const CartItemSkeleton(),
                  SizedBox(height: 12.h),
                  const CartItemSkeleton(),
                ],
              ),
            );
          }
          if (state is WishlistError) {
            return ErrorStateWidget(
              failure: state.failure,
              onRetry: () => context.read<WishlistCubit>().loadWishlist(),
            );
          }
          if (state is WishlistLoaded) {
            final items = state.wishlist.items;
            if (items.isEmpty) {
              return EmptyStateWidget(
                enableBackButton: false,
                icon: Icons.favorite_border,
                title: 'wishlist.empty_title'.tr(),
                subtitle: 'wishlist.empty_subtitle'.tr(),
                actionLabel: 'wishlist.start_shopping'.tr(),
                onActionPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routes.dashBoard,
                  (_) => false,
                ),
              );
            }

            final availableItems = items.where((i) => i.isAvailable).toList();
            final hasHeader = availableItems.isNotEmpty;
            final headerOffset = hasHeader ? 1 : 0;

            return RefreshIndicator(
              onRefresh: () => context.read<WishlistCubit>().loadWishlist(),
              child: CustomScrollView(
                slivers: [
                  // "Add All to Cart" button
                  if (availableItems.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                        child: BlocBuilder<CartCubit, CartState>(
                          builder: (context, cartState) {
                            final isLoading = cartState is AddingToCart;
                            return SizedBox(
                              height: 48.h,
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        for (final it in availableItems) {
                                          context.read<CartCubit>().addToCart(
                                                productId: it.productId,
                                                quantity: 1,
                                              );
                                          context
                                              .read<WishlistCubit>()
                                              .removeItem(
                                                it.wishlistItemId,
                                                productId: it.productId,
                                              );
                                        }
                                      },
                                child: isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : Text('wishlist.add_all_to_cart'.tr()),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorsManager.primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  textStyle: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Product grid — same ProductCard as home
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = items[index];
                          final locale =
                              Localizations.localeOf(context).languageCode;
                          return ProductCard(
                            productId: item.productId,
                            name: locale == 'ar'
                                ? item.productNameAr
                                : item.productName,
                            imageUrl: item.imageUrl,
                            price: item.price,
                            originalPrice: item.originalPrice,
                            rating: item.rating,
                            reviewCount: item.reviewCount,
                            isAvailable: item.isAvailable,
                            onAddToCart: () {
                              context.read<WishlistCubit>().removeItem(
                                    item.wishlistItemId,
                                    productId: item.productId,
                                  );
                            },
                            onTap: () => AppNavigator.pushNamed(
                              context,
                              '${Routes.productDetails}/${item.productId}',
                            ),
                          );
                        },
                        childCount: items.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: kProductCardAspectRatio,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return EmptyStateWidget(
            enableBackButton: false,
            icon: Icons.favorite_border_rounded,
            title: 'wishlist.login_required_title'.tr(),
            subtitle: 'wishlist.login_required_subtitle'.tr(),
            actionLabel: 'auth.login'.tr(),
            onActionPressed: () =>
                AppNavigator.pushNamed(context, Routes.login),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WEB: Main body with toolbar + responsive product grid
// ─────────────────────────────────────────────────────────────────────────────

class _WebBody extends StatelessWidget {
  final List<WishlistItemEntity> items;
  final void Function(WishlistItemEntity) onRemove;

  const _WebBody({required this.items, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5);
    final availableItems = items.where((i) => i.isAvailable).toList();

    return Container(
      color: bg,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.88),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Breadcrumb ──────────────────────────────────────────
                _Breadcrumb(),
                const SizedBox(height: 24),

                // ── Toolbar ─────────────────────────────────────────────
                _WebToolbar(
                  count: items.length,
                  availableItems: availableItems,
                  isDark: isDark,
                ),
                const SizedBox(height: 24),

                // ── Product grid ────────────────────────────────────────
                _WebGrid(items: items, onRemove: onRemove, isDark: isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Breadcrumb
// ─────────────────────────────────────────────────────────────────────────────

class _Breadcrumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? Colors.white38 : Colors.black38;
    final active = isDark ? Colors.white70 : Colors.black87;

    Widget crumb(String label, {VoidCallback? onTap}) {
      Widget child = GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: onTap != null ? ColorsManager.primaryColor : active,
            fontWeight:
                onTap != null ? FontWeight.w500 : FontWeight.w700,
            decoration: onTap != null ? TextDecoration.none : null,
          ),
        ),
      );

      if (onTap != null) {
        child = SafeMouseRegion(
          cursor: SystemMouseCursors.click,
          child: child,
        );
      }

      return child;
    }

    Widget sep() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.chevron_right_rounded, size: 16, color: muted),
        );

    return Row(
      children: [
        crumb('dashboard.home'.tr(),
            onTap: () =>
                AppNavigator.pushNamed(context, Routes.dashBoard)),
        sep(),
        crumb('wishlist.title'.tr()),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toolbar: item count + "Add All to Cart"
// ─────────────────────────────────────────────────────────────────────────────

class _WebToolbar extends StatelessWidget {
  final int count;
  final List<WishlistItemEntity> availableItems;
  final bool isDark;

  const _WebToolbar({
    required this.count,
    required this.availableItems,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06);

    return LayoutBuilder(builder: (context, cs) {
      final isNarrow = cs.maxWidth < 500;
      return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isNarrow
          // ── Narrow: stack title row + button row ──────────────
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.favorite_rounded, color: Colors.red[400], size: 20),
                  const SizedBox(width: 8),
                  Text('wishlist.title'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white54 : Colors.black38, size: 18),
                    tooltip: 'common.retry'.tr(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => context.read<WishlistCubit>().loadWishlist(),
                  ),
                  const Spacer(),
                  if (availableItems.isNotEmpty)
                    BlocBuilder<CartCubit, CartState>(
                      builder: (context, cartState) {
                        final isLoading = cartState is AddingToCart;
                        return SizedBox(
                          height: 36,
                          child: ElevatedButton.icon(
                            onPressed: isLoading ? null : () {
                              for (final it in availableItems) {
                                context.read<CartCubit>().addToCart(productId: it.productId, quantity: 1);
                                context.read<WishlistCubit>().removeItem(it.wishlistItemId, productId: it.productId);
                              }
                            },
                            icon: isLoading ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.shopping_cart_outlined, size: 14),
                            label: Text('wishlist.add_all_to_cart'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(backgroundColor: ColorsManager.primaryColor, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 12)),
                          ),
                        );
                      },
                    ),
                ]),
              ],
            )
          // ── Wide: original single row ─────────────────────────
          : Row(
              children: [
                Icon(Icons.favorite_rounded, color: Colors.red[400], size: 22),
                const SizedBox(width: 10),
                Text('wishlist.title'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                const Spacer(),
                if (availableItems.isNotEmpty)
                  BlocBuilder<CartCubit, CartState>(
                    builder: (context, cartState) {
                      final isLoading = cartState is AddingToCart;
                      return SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () {
                            for (final it in availableItems) {
                              context.read<CartCubit>().addToCart(productId: it.productId, quantity: 1);
                              context.read<WishlistCubit>().removeItem(it.wishlistItemId, productId: it.productId);
                            }
                          },
                          child: isLoading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('wishlist.add_all_to_cart'.tr(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(backgroundColor: ColorsManager.primaryColor, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16)),
                        ),
                      );
                    },
                  ),
              ],
            ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Responsive product grid
// ─────────────────────────────────────────────────────────────────────────────

class _WebGrid extends StatelessWidget {
  final List<WishlistItemEntity> items;
  final void Function(WishlistItemEntity) onRemove;
  final bool isDark;

  const _WebGrid(
      {required this.items, required this.onRemove, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = width > 1100
            ? 5
            : width > 860
                ? 4
                : width > 600
                    ? 3
                    : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: kProductCardAspectRatio,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ProductCard(
              productId: item.productId,
              name: locale == 'ar' ? item.productNameAr : item.productName,
              imageUrl: item.imageUrl,
              price: item.price,
              originalPrice: item.originalPrice,
              rating: item.rating,
              reviewCount: item.reviewCount,
              isAvailable: item.isAvailable,
              onAddToCart: () {
                context.read<WishlistCubit>().removeItem(
                      item.wishlistItemId,
                      productId: item.productId,
                    );
              },
              onTap: () => AppNavigator.pushNamed(
                context,
                '${Routes.productDetails}/${SlugUtils.slugify(item.productName, item.productId)}',
              ),
            );
          },
        );
      },
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Web Empty / Guest / Skeleton states
// ─────────────────────────────────────────────────────────────────────────────

class _WebEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(vertical: 120),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border_rounded,
                size: 72, color: Colors.red[200]),
            const SizedBox(height: 20),
            Text(
              'wishlist.empty_title'.tr(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'wishlist.empty_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black45),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () =>
                  AppNavigator.pushNamed(context, Routes.dashBoard),
              icon: const Icon(Icons.storefront_rounded, size: 16),
              label: Text('wishlist.start_shopping'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebGuestState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(vertical: 120),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 64, color: ColorsManager.primaryColor.withValues(alpha: 0.5)),
            const SizedBox(height: 20),
            Text(
              'wishlist.login_required_title'.tr(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'wishlist.login_required_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black45),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () =>
                  AppNavigator.pushNamed(context, Routes.login),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('auth.login'.tr(),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmer =
        isDark ? const Color(0xFF252540) : const Color(0xFFEEEEEE);
    return Container(
      color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.88),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
            itemCount: 8,
            itemBuilder: (_, __) => Container(
              decoration: BoxDecoration(
                color: shimmer,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
