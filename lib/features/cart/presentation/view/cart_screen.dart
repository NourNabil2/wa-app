import 'package:fastway/core/layout/simple_web_shell.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/widgets/drag_scroll.dart';
import 'package:fastway/core/widgets/selectable.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fastway/features/cart/presentation/widgets/shake_animation.dart';
import 'package:fastway/core/utils/slug_utils.dart';
// lib/features/cart/presentation/view/cart_screen.dart
import 'package:fastway/core/cubit/delivery_location/delivery_location_cubit.dart';
import 'package:fastway/core/cubit/delivery_location/delivery_location_state.dart';

import 'package:fastway/core/routes/app_navigator.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:fastway/core/layout/web_nav_controller.dart';
import 'package:fastway/core/responsive/responsive_layout.dart';
import 'package:fastway/core/widgets/app_buton.dart';
import 'package:fastway/core/widgets/custom_app_bar.dart';
import 'package:fastway/core/widgets/empty_state_widget.dart';
import 'package:fastway/core/widgets/safe_mouse_region.dart';
import 'package:fastway/core/utils/assets.dart';
import 'package:fastway/core/widgets/custom_lottie_icon.dart';
import 'package:fastway/core/widgets/skeletons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../features/user_data/auth_guard.dart';
import '../../../../core/widgets/custom_snack_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/widgets/sar_symbol.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/order_summary.dart';
import '../widgets/coupon_section.dart';
import '../../../wishlist/presentation/widgets/cart_wishlist_reminder.dart';
import '../../../wishlist/presentation/cubit/wishlist_cubit.dart';
import '../../../home/domain/entities/product_entity.dart';
import '../../../home/presentation/widget/card/product_card.dart';
import '../../domain/entities/cart_entity.dart';
import '../../../user_data/user_cubit.dart';
import 'package:fastway/core/widgets/loyalty_points_bar.dart';

class CartScreen extends StatefulWidget {
  final bool isTab;
  /// When opened from a "discount" push notification, the coupon code to apply
  /// automatically once the cart has loaded.
  final String? applyCouponCode;
  const CartScreen({super.key, this.isTab = false, this.applyCouponCode});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with AutomaticKeepAliveClientMixin {
  CartEntity? _lastKnownCart;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    context.read<CartCubit>().loadCart();
    // Only load wishlist for authenticated users — guests will get a 401 otherwise
    if (context.read<UserCubit>().isLoggedIn) {
      context.read<WishlistCubit>().loadWishlist();
    }
  }

  // One-shot guard so the discount-push coupon is auto-applied exactly once,
  // after the cart has finished loading (avoids a race where loadCart's response
  // lands after applyCoupon and overwrites the applied-coupon state).
  bool _autoCouponApplied = false;

  void _maybeAutoApplyCoupon(CartState state) {
    if (_autoCouponApplied) return;
    final code = widget.applyCouponCode?.trim();
    if (code == null || code.isEmpty) return;
    if (state is! CartLoaded) return;
    _autoCouponApplied = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CartCubit>().applyCoupon(code);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    int currentIndex = -1;
    try {
      currentIndex = context.watch<WebNavController>().currentIndex;
    } catch (_) {}
    final bool animateShake = widget.isTab ? currentIndex == 2 : true;

    final isWeb = isWebLayout(context);

    // Reload cart whenever the selected delivery address changes.
    // Express eligibility per item depends on which warehouse covers the address.
    final cartBody = BlocListener<DeliveryLocationCubit, DeliveryLocationState>(
      listenWhen: (prev, curr) {
        final prevId = (prev is DeliveryLocationResolved) ? prev.selectedAddress?.id : null;
        final currId = (curr is DeliveryLocationResolved) ? curr.selectedAddress?.id : null;
        return prevId != currId;
      },
      listener: (context, _) => context.read<CartCubit>().loadCart(),
      child: BlocConsumer<CartCubit, CartState>(
          listener: (context, state) {
            // Auto-apply a coupon delivered via a discount push notification,
            // once the cart is loaded.
            _maybeAutoApplyCoupon(state);
            if (state is AddedToCart) {
              CustomSnackBar.show(context, message: state.message);
            } else if (state is CouponApplied) {
              CustomSnackBar.show(context, message: state.message);
            } else if (state is CouponError) {
              CustomSnackBar.show(
                  context, message: state.message, type: SnackBarType.error);
            } else if (state is CartToastError) {
              // Non-fatal error (e.g. express toggle rejected) — show alert, keep cart
              CustomSnackBar.show(
                  context, message: state.message, type: SnackBarType.error);
            }
          },
          builder: (context, state) {
            if (state is CartLoaded) {
              _lastKnownCart = state.cart;
            } else if (state is CouponApplied) {
              _lastKnownCart = state.cart;
            }

            if (state is CartLoading && _lastKnownCart == null) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    CartItemSkeleton(),
                    CartItemSkeleton(),
                    CartItemSkeleton(),
                  ],
                ),
              );
            }

            if (state is CartError && _lastKnownCart == null) {
              return ErrorStateWidget(
                failure: state.failure,
                onRetry: () => context.read<CartCubit>().loadCart(),
              );
            }

            final cart = _lastKnownCart;

            if (cart == null) return const SizedBox.shrink();

            if (cart.items.isEmpty) {
              return EmptyStateWidget(
                enableBackButton: false,
                icon: Icons.shopping_cart_outlined,
                title: 'cart.empty_title'.tr(),
                subtitle: 'cart.empty_subtitle'.tr(),
                actionLabel: 'cart.start_shopping'.tr(),
                onActionPressed: () {
                  try {
                    context.read<WebNavController>().navigateTo(0);
                  } catch (_) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, Routes.dashBoard, (_) => false);
                  }
                },
              );
            }

            final isProcessing = state is AddingToCart ||
                state is ApplyingCoupon ||
                (state is CartLoading && _lastKnownCart != null);

            if (isWeb) {
              return _WebCartContent(cart: cart, isProcessing: isProcessing, animateShake: animateShake);
            }
            return _MobileCartContent(cart: cart, isProcessing: isProcessing, animateShake: animateShake);
          },
        ),
      );

    if (isWeb) {
      // When rendered as a Dashboard tab, the parent WebShell already provides
      // the header/footer — wrapping again causes a double header.
      if (widget.isTab) return cartBody;
      return SimpleWebShell(content: cartBody);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFF8F8F8),
      appBar: CustomAppBar(
        title: 'cart.title'.tr(),
        showBackIcon: !widget.isTab,
      ),
      body: cartBody,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOBILE CART CONTENT
// ═══════════════════════════════════════════════════════════════════════════════
class _MobileCartContent extends StatelessWidget {
  final CartEntity cart;
  final bool isProcessing;
  final bool animateShake;

  const _MobileCartContent(
      {required this.cart, this.isProcessing = false, this.animateShake = true});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _FreeShippingBar(subtotal: cart.subtotal),
                ),
              ),
              if (cart.coldRecommendation)
                SliverToBoxAdapter(child: _ColdItemsWarningBar()),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final item = cart.items[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Slidable(
                          key: ValueKey('cart_item_${item.id}'),
                          startActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            extentRatio: 0.45,
                            children: [
                              SlidableAction(
                                onPressed: (context) {
                                  context.read<WishlistCubit>().toggleProduct(item.productId);
                                  context.read<CartCubit>().removeItem(item.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('cart.saved_for_later'.tr()),
                                      backgroundColor: ColorsManager.primaryColor,
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                backgroundColor: const Color(0xFFFDE8F1),
                                foregroundColor: Colors.red,
                                icon: Icons.favorite,
                              ),
                              SlidableAction(
                                onPressed: (context) {
                                  context.read<CartCubit>().removeItem(item.id);
                                },
                                backgroundColor: const Color(0xFFEBEBEB),
                                foregroundColor: Colors.grey[700],
                                icon: Icons.delete_outline,
                              ),
                            ],
                          ),
                          child: ShakeAnimation(
                            animate: index == 0 && animateShake,
                            child: CartItemCard(
                              isProcessing: isProcessing,
                              item: item,
                              onIncrement: () =>
                                  context.read<CartCubit>().incrementQuantity(item.id),
                              onDecrement: () =>
                                  item.quantity == 1 
                                      ? context.read<CartCubit>().removeItem(item.id) 
                                      : context.read<CartCubit>().decrementQuantity(item.id),
                              onRemove: () =>
                                  context.read<CartCubit>().removeItem(item.id),
                              onUpdateQuantity: (q) =>
                                  context.read<CartCubit>().updateQuantity(item.id, q),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: cart.items.length,
                  ),
                ),
              ),

              // 👈 سيكشن الكوبون رجع تاني هنا في الموبايل!
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: BlocBuilder<CartCubit, CartState>(
                    builder: (context, state) {
                      return CouponSection(
                        onApply: (code) => context.read<CartCubit>().applyCoupon(code),
                        onRemove: () => context.read<CartCubit>().removeCoupon(),
                        appliedCoupon: cart.couponCode,
                        isLoading: state is ApplyingCoupon,
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 16.h)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: OrderSummary(cart: cart),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 16.h)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 16.h, left: 16.w, right: 16.w),
                  child: const CartWishlistReminder(),
                ),
              ),
              if (cart.suggestions != null && cart.suggestions!.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 24.h, left: 16.w, right: 16.w),
                    child: _SuggestionsRow(suggestions: cart.suggestions!),
                  ),
                ),
              SliverToBoxAdapter(
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.only(top: 24.h, bottom: 48.h),
                    child: _CheckoutButton(cart: cart, isProcessing: isProcessing),
                  ),
                ),
              ),
            ],
          );
  }

  Widget _buildDismissBackground(
    BuildContext context, {
    required AlignmentGeometry alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24.sp),
          SizedBox(height: 4.h),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WEB CART CONTENT
// ═══════════════════════════════════════════════════════════════════════════════
class _WebCartContent extends StatelessWidget {
  final CartEntity cart;
  final bool isProcessing;
  final bool animateShake;

  const _WebCartContent({
    required this.cart,
    this.isProcessing = false,
    this.animateShake = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        final hPad = isNarrow ? constraints.maxWidth * 0.04 : 32.0;

        // Items list — right column in RTL, left column in LTR
        final itemsList = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...cart.items.asMap().entries.map<Widget>((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ShakeAnimation(
                  animate: index == 0 && animateShake,
                  child: CartItemCard(
                    isProcessing: isProcessing,
                    item: item,
                    onIncrement: () => context.read<CartCubit>().incrementQuantity(item.id),
                    onDecrement: () => item.quantity == 1 ? context.read<CartCubit>().removeItem(item.id) : context.read<CartCubit>().decrementQuantity(item.id),
                    onRemove: () => context.read<CartCubit>().removeItem(item.id),
                    onUpdateQuantity: (qty) => context.read<CartCubit>().updateQuantity(item.id, qty),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            const CartWishlistReminder(),
            if (cart.suggestions != null && cart.suggestions!.isNotEmpty) ...[
              const SizedBox(height: 48),
              _SuggestionsRow(suggestions: cart.suggestions!),
            ],
          ],
        );

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isNarrow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: _FreeShippingBar(subtotal: cart.subtotal),
                            ),
                            if (cart.coldRecommendation) ...[
                              _ColdItemsWarningBar(),
                              const SizedBox(height: 12),
                            ],
                            itemsList,
                            const SizedBox(height: 24),
                            _WebOrderSummaryCard(
                              cart: cart,
                              isProcessing: isProcessing,
                            ),
                            const SizedBox(height: 40),
                          ],
                        )
                      // Items first → right in RTL, left in LTR
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (cart.coldRecommendation) ...[
                                    _ColdItemsWarningBar(),
                                    const SizedBox(height: 12),
                                  ],
                                  itemsList,
                                ],
                              ),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              flex: 4,
                              child: Column(
                                children: [
                                  _FreeShippingBar(subtotal: cart.subtotal),
                                  _WebOrderSummaryCard(
                                    cart: cart,
                                    isProcessing: isProcessing,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WEB ORDER SUMMARY CARD
// ═══════════════════════════════════════════════════════════════════════════════
class _WebOrderSummaryCard extends StatefulWidget {
  final CartEntity cart;
  final bool isProcessing;

  const _WebOrderSummaryCard(
      {required this.cart, this.isProcessing = false});

  @override
  State<_WebOrderSummaryCard> createState() => _WebOrderSummaryCardState();
}

class _WebOrderSummaryCardState extends State<_WebOrderSummaryCard> {
  final _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = widget.cart;

    final vatEnabled  = AppSettingsService.instance.vatEnabled;
    final vatRate     = AppSettingsService.instance.vatRate;
    final taxable     = cart.subtotal - (cart.couponDiscount ?? 0);
    final exclVat     = vatEnabled ? taxable / (1 + vatRate / 100) : taxable;
    final vatAmount   = vatEnabled ? taxable - exclVat : 0.0;

    final divColor = isDark ? Colors.white12 : Colors.grey.shade200;
    final labelStyle = TextStyle(
      fontSize: 13,
      color: isDark ? Colors.grey[400] : const Color(0xFF888888),
    );
    final valueStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
    );
    final totalLabelStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
    );
    final totalValueStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w900,
      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Title ──────────────────────────────────────────────────────
            Text(
              'cart.order_summary'.tr(),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: divColor, height: 1),
            const SizedBox(height: 14),

            // ── Subtotal (ex-VAT) ───────────────────────────────────────────
            // Each totals row is wrapped on its own: they are pure text (no
            // buttons), unlike the coupon field below, and a per-row Selectable
            // lets the label + amount be copied together in one drag.
            Selectable(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // label first → appears on RIGHT in RTL
                  Text('checkout.subtotal_products'.tr(), style: labelStyle),
                  // value last → appears on LEFT in RTL
                  SarText(
                    price: exclVat.toStringAsFixed(2),
                    style: valueStyle,
                  ),
                ],
              ),
            ),

            // ── Total Savings ───────────────────────────────────────────
            if (cart.totalSavings > 0) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${'cart.savings_banner_prefix'.tr()}${'cart.savings_banner_suffix'.tr()}', style: labelStyle),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('- ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ColorsManager.errorFill)),
                      SarText(
                        price: cart.totalSavings.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ColorsManager.errorFill,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],

            // ── Coupon discount ──────────────────────────────────────────
            if (cart.couponDiscount != null && cart.couponDiscount! > 0) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // label first → RIGHT in RTL
                  Text('cart.coupon_discount'.tr(), style: labelStyle),
                  // value last → LEFT in RTL
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('- ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ColorsManager.successFill)),
                      SarText(
                        price: cart.couponDiscount!.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ColorsManager.successFill),
                      ),
                    ],
                  ),
                ],
              ),
            ],

            // ── Points discount ──────────────────────────────────────────
            if (cart.pointsDiscount != null && cart.pointsDiscount! > 0) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('cart.summary.points_discount'.tr(args: [cart.pointsUsed.toString()]), style: labelStyle),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('- ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ColorsManager.primaryColor)),
                      SarText(
                        price: cart.pointsDiscount!.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ColorsManager.primaryColor),
                      ),
                    ],
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            Divider(color: divColor, height: 1),
            const SizedBox(height: 14),

            // ── Coupon label ────────────────────────────────────────────────
            Text(
              'cart.coupon_title'.tr(),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : const Color(0xFF888888),
              ),
            ),
            const SizedBox(height: 8),

            // ── Coupon input or applied badge ───────────────────────────────
            if (cart.couponCode != null)
              _AppliedCouponBadgeWeb(
                code: cart.couponCode!,
                onRemove: () => context.read<CartCubit>().removeCoupon(),
              )
            else
              BlocBuilder<CartCubit, CartState>(
                builder: (context, state) {
                  final isLoading = state is ApplyingCoupon;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Input field first → RIGHT in RTL (where user types)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: TextField(
                                controller: _couponController,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'cart.coupon_hint_text'.tr(),
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                                  ),
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  hoverColor: Colors.transparent,
                                  filled: false,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                onSubmitted: isLoading
                                    ? null
                                    : (_) => context.read<CartCubit>().applyCoupon(_couponController.text),
                              ),
                            ),
                          ),
                          // Divider
                          Container(width: 1, height: double.infinity, color: isDark ? Colors.white12 : Colors.grey.shade300),
                          // Apply button last → LEFT in RTL
                          GestureDetector(
                            onTap: isLoading ? null : () => context.read<CartCubit>().applyCoupon(_couponController.text),
                            child: Container(
                              width: 90,
                              color: isLoading
                                  ? ColorsManager.primaryColor.withValues(alpha: 0.5)
                                  : ColorsManager.primaryColor,
                              alignment: Alignment.center,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      'cart.apply'.tr(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 16),
            Divider(color: divColor, height: 1),
            const SizedBox(height: 14),

            // ── VAT ─────────────────────────────────────────────────────────
            if (vatEnabled) ...[
              Selectable(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // label first → RIGHT in RTL
                    Text('checkout.vat'.tr(namedArgs: {'rate': vatRate.toStringAsFixed(0)}), style: labelStyle),
                    // value last → LEFT in RTL
                    SarText(
                      price: vatAmount.toStringAsFixed(2),
                      style: labelStyle.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Total ────────────────────────────────────────────────────────
            Selectable(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // label first → RIGHT in RTL
                  Text('cart.total'.tr(), style: totalLabelStyle),
                  // value last → LEFT in RTL
                  SarText(
                    price: cart.total.toStringAsFixed(2),
                    style: totalValueStyle,
                  ),
                ],
              ),
            ),

            // ── VAT inclusive note ───────────────────────────────────────────
            if (vatEnabled) ...[
              const SizedBox(height: 6),
              Text(
                '* ${'cart.vatIncluded'.tr()}',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
            ],

            // ── Points earned box ────────────────────────────────────────────
            if (cart.pointsEarned > 0) ...[
              const SizedBox(height: 16),
              LoyaltyPointsBar(
              bonusPercent: cart.tierBonusPercent,
                points: cart.pointsEarned,
                titleOverride: 'cart.summary.points_earned'.tr(),
                subtitleOverride: 'cart.summary.points_encourage'.tr(),
              ),
            ],

            const SizedBox(height: 20),

            // ── Checkout button ──────────────────────────────────────────────
            if (widget.isProcessing)
              _ProcessingButton()
            else
              _CheckoutInkButton(cart: cart),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WEB COUPON FIELD
// ═══════════════════════════════════════════════════════════════════════════════
class _WebCouponField extends StatelessWidget {
  final CartEntity cart;
  final TextEditingController controller;
  final bool isVisible;
  final VoidCallback onToggle;

  const _WebCouponField({
    required this.cart,
    required this.controller,
    required this.isVisible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (cart.couponCode != null) {
      return _AppliedCouponBadgeWeb(
        code: cart.couponCode!,
        onRemove: () => context.read<CartCubit>().removeCoupon(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'cart.coupon_title'.tr(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: BlocBuilder<CartCubit, CartState>(
            builder: (context, state) {
              final isLoading = state is ApplyingCoupon;
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'cart.coupon_hint_text'.tr(),
                          hintStyle: TextStyle(
                            fontSize: 13,
                            letterSpacing: 0,
                            fontWeight: FontWeight.w400,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onSubmitted: isLoading
                            ? null
                            : (_) => context.read<CartCubit>().applyCoupon(controller.text),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: isLoading
                            ? Container(
                                key: const ValueKey('loading'),
                                width: 80,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: ColorsManager.primaryColor,
                                    ),
                                  ),
                                ),
                              )
                            : GestureDetector(
                                key: const ValueKey('apply'),
                                onTap: () => context.read<CartCubit>().applyCoupon(controller.text),
                                child: Container(
                                  width: 80,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: ColorsManager.primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'cart.apply'.tr(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// APPLIED COUPON BADGE (Web)
// ═══════════════════════════════════════════════════════════════════════════════
class _AppliedCouponBadgeWeb extends StatelessWidget {
  final String code;
  final VoidCallback onRemove;

  const _AppliedCouponBadgeWeb(
      {required this.code, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ColorsManager.primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: ColorsManager.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: ColorsManager.primaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check,
                color: ColorsManager.primaryColor, size: 13),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('cart.coupon_applied'.tr(),
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500)),
                Text(code,
                    style: const TextStyle(
                        fontSize: 14,
                        color: ColorsManager.primaryColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child:
              Icon(Icons.close, size: 14, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROCESSING BUTTON PLACEHOLDER
// ═══════════════════════════════════════════════════════════════════════════════
class _ProcessingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: Colors.white),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CHECKOUT BUTTON (Mobile)
// ═══════════════════════════════════════════════════════════════════════════════
class _CheckoutButton extends StatelessWidget {
  final CartEntity cart;
  final bool isProcessing;

  const _CheckoutButton({required this.cart, this.isProcessing = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: isProcessing ? _ProcessingButton() : _CheckoutInkButton(cart: cart),
    );
  }
}

class _CheckoutInkButton extends StatelessWidget {
  final CartEntity cart;

  const _CheckoutInkButton({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: () {
            if (AuthGuard.isGuest(context)) {
              // Guest trying to checkout — redirect to login
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Text(
                  'auth.loginRequired'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                content: Text(
                  'auth.checkoutLoginMessage'.tr(),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  maxLines: 5,
                  overflow: TextOverflow.visible,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('common.cancel'.tr()),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      AppNavigator.pushNamed(context, Routes.auth);
                    },
                    child: Text('auth.login'.tr()),
                  ),
                ],
              ),
            );
            return;
          }
          AppNavigator.pushNamed(context, Routes.checkout);
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: ColorsManager.primary2Color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ButtonBody(),
            ],
          ),
        ),
      ),
    )
    );
  }
}

class _ButtonBody extends StatelessWidget {
  const _ButtonBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          'cart.checkout'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CART COUNT BADGE
// ═══════════════════════════════════════════════════════════════════════════════
class _CartCountBadge extends StatelessWidget {
  const _CartCountBadge();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        if (state is CartLoaded && state.cart.items.isNotEmpty) {
          return Container(
            margin: EdgeInsetsDirectional.only(end: 16.w),
            width: 24.w,
            height: 24.w,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: ColorsManager.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${state.cart.items.length}',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.0, // Ensures perfect vertical centering
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUGGESTIONS ROW
// ═══════════════════════════════════════════════════════════════════════════════
class _SuggestionsRow extends StatelessWidget {
  final List<ProductEntity> suggestions;
  const _SuggestionsRow({required this.suggestions});

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'cart.suggestions_title'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        DragScroll(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(suggestions.length, (i) {
                final product = suggestions[i];
              return Padding(
                padding: EdgeInsetsDirectional.only(end: i < suggestions.length - 1 ? 14 : 0),
                child: SizedBox(
                  width: 180,
                  height: 319,
                  child: ProductCard(
                    productId: product.id,
                    name: product.name,
                    imageUrl: product.imageUrl,
                    categoryName: product.categoryId,
                    brandName: product.localizedBrandName(context.locale.languageCode),
                    price: product.price,
                    originalPrice: product.originalPrice,
                    rating: product.rating,
                    reviewCount: product.reviewCount,
                    isNew: product.isNew,
                    isAvailable: product.isAvailable,
                    isExpressEligible: product.isExpressEligible,
                    isFeatured: product.isFeatured,
                    stockWarning: product.stockWarning,
                    pointsToEarn: product.pointsToEarn,
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

// ═══════════════════════════════════════════════════════════════════════════════
// COLD ITEMS WARNING BAR
// ═══════════════════════════════════════════════════════════════════════════════
class _ColdItemsWarningBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWeb = isWebLayout(context);

    return Container(
      margin: isWeb 
          ? EdgeInsets.zero
          : EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A2236) : const Color(0xFFE0F4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF0EA5E9).withValues(alpha: isDark ? 0.4 : 0.3)),
      ),
      child: Row(
        children: [
          const Text('\u2744\ufe0f', style: TextStyle(fontSize: 18)),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              isWeb 
                  ? 'checkout.coldChainWarning'.tr()
                  : 'checkout.coldChainWarning'.tr().replaceAll('. ', '.\n'),
              maxLines: isWeb ? 1 : 2,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FREE SHIPPING BAR
// ═══════════════════════════════════════════════════════════════════════════════
class _FreeShippingBar extends StatelessWidget {
  final double subtotal;
  const _FreeShippingBar({required this.subtotal});

  @override
  Widget build(BuildContext context) {
    final threshold = AppSettingsService.instance.freeShippingThreshold;
    if (threshold <= 0) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (subtotal / threshold).clamp(0.0, 1.0);
    final remaining = threshold - subtotal;
    final isFree = remaining <= 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isFree ? 'cart.shipping.free_shipping_congrats'.tr() : 'cart.shipping.remaining_prefix'.tr(),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
              if (!isFree) ...[
                const SizedBox(width: 4),
                SarText(
                  price: remaining.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'cart.shipping.remaining_suffix'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        width: double.infinity,
                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                      ),
                      Positioned.fill(
                        child: Shimmer.fromColors(
                          baseColor: isFree 
                              ? ColorsManager.successFill 
                              : ColorsManager.primaryColor,
                          highlightColor: isFree 
                              ? ColorsManager.successFill.withValues(alpha: 0.5) 
                              : ColorsManager.primaryColor.withValues(alpha: 0.4),
                          period: const Duration(seconds: 2),
                          direction: Directionality.of(context) == TextDirection.rtl
                              ? ShimmerDirection.rtl 
                              : ShimmerDirection.ltr,
                          child: LinearProgressIndicator(
                            value: isFree ? 1.0 : progress,
                            minHeight: 8,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isFree ? ColorsManager.successFill : ColorsManager.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SarText(
                price: threshold.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
