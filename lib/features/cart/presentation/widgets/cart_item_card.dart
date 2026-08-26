// lib/features/cart/presentation/widgets/cart_item_card.dart

import 'package:fastway/core/theme/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/utils/slug_utils.dart';
import 'package:fastway/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:fastway/features/wishlist/presentation/cubit/wishlist_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/utils/assets.dart';
import '../../../../core/widgets/wishlist_heart_button.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/custom_network_image.dart';
import '../../../../core/widgets/sar_symbol.dart';
import 'package:fastway/core/responsive/responsive_layout.dart';
import '../../domain/entities/cart_entity.dart';

class CartItemCard extends StatelessWidget {
  final bool isProcessing;
  final CartItemEntity item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final void Function(int) onUpdateQuantity;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onUpdateQuantity,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktopWeb = isWebLayout(context) && MediaQuery.of(context).size.width >= 800;
    if (isDesktopWeb) {
      return _buildWebLayout(context);
    }
    return _buildMobileLayout(context);
  }

  Widget _buildWebLayout(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? ColorsManager.surfaceDarkCard : Colors.white;
    final h = AppSizeHorizontal.instance;
    final v = AppSizeVertical.instance;

    // Web parity with the mobile card: tapping the item opens its product page.
    // The inner controls (qty +/-, remove, express toggle) have their own
    // GestureDetectors and sit deeper in the tree, so they win the gesture arena
    // over their own hit areas and never trigger this navigation.
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => AppNavigator.pushNamed(
          context,
          '${Routes.productDetails}/${SlugUtils.slugify(item.name, item.productId)}',
        ),
        child: LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;

        if (isNarrow) {
          // ── Narrow (mobile-width browser) — horizontal card ──────────────
          return Container(
            padding: EdgeInsets.all(h.s12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                CustomNetworkImage.rounded(
                  imageUrl: item.imageUrl,
                  width: 80,
                  height: 80,
                  borderRadius: 12,
                  fit: BoxFit.cover,
                  backgroundColor: isDark ? const Color(0xFF2C2C2E) : ColorsManager.backgroundCard,
                ),
                const SizedBox(width: 12),
                
                // Details (Name, Price, Stepper)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.localizedBrandName(locale) != null && item.localizedBrandName(locale)!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            item.localizedBrandName(locale)!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF00BFA5),
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Text(
                        item.localizedName(locale),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: isDark ? Colors.white : ColorsManager.defaultText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // A granted line costs nothing. Saying "Free" is clearer
                          // than a 0.00, and the retail price beside it is struck
                          // through so the customer sees what it is worth.
                          if (item.isGift)
                            Flexible(
                              child: Text(
                                'cart.gift_free'.tr(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: ColorsManager.successFill,
                                ),
                              ),
                            )
                          else
                          Flexible(
                            child: SarText(
                              price: item.price.toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: ColorsManager.primaryColor,
                              ),
                            ),
                          ),
                          if (item.originalPrice != null) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: SarText(
                                price: item.originalPrice!.toStringAsFixed(2),
                                strikeThrough: item.isGift,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      _GiftBadge(item: item),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // A gift's quantity is derived from the offer, so a
                          // stepper would only be corrected on the next cart
                          // change. Show the count instead.
                          if (item.isGift)
                            _GiftQuantity(quantity: item.quantity)
                          else
                            _EditableQuantityWidget(
                              quantity: item.quantity,
                              maxQuantity: item.maxQuantity,
                              isProcessing: isProcessing,
                              onIncrement: onIncrement,
                              onDecrement: onDecrement,
                              onUpdateQuantity: onUpdateQuantity,
                            ),
                          _ExpressBadge(item: item),
                        ],
                        ),
                      ],
                    ),
                  ),
                
                  const SizedBox(width: 8),
                
                  // Actions (Delete, Total)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      WishlistHeartButton(
                        productId: item.productId,
                        noBackground: true,
                        hideTooltip: true,
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.delete_outline, size: 22),
                        color: ColorsManager.errorFill,
                        splashRadius: 20,
                        padding: EdgeInsets.all(h.s6),
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${'cart.subtotal'.tr()}:',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 4),
                      SarText(
                        price: item.totalPrice.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                          color: ColorsManager.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          // ── Wide (desktop/tablet) — horizontal row ──────────────────────
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image
                  CustomNetworkImage.rounded(
                    imageUrl: item.imageUrl,
                    width: 100,
                    height: 100,
                    borderRadius: 12,
                    fit: BoxFit.cover,
                    backgroundColor: isDark ? const Color(0xFF2C2C2E) : ColorsManager.backgroundCard,
                  ),
                  const SizedBox(width: 20),

                  // Name + price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (item.localizedBrandName(locale) != null && item.localizedBrandName(locale)!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              item.localizedBrandName(locale)!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF00BFA5),
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        Text(
                          item.localizedName(locale),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.normal,
                            color: isDark ? Colors.white : ColorsManager.defaultText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // A granted line costs nothing. Saying "Free" is clearer
                            // than a 0.00, and the retail price beside it is struck
                            // through so the customer sees what it is worth.
                            if (item.isGift)
                              Flexible(
                                child: Text(
                                  'cart.gift_free'.tr(),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: ColorsManager.successFill,
                                  ),
                                ),
                              )
                            else
                            Flexible(
                              child: SarText(
                                price: item.price.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.normal,
                                  color: ColorsManager.primaryColor,
                                ),
                              ),
                            ),
                            if (item.originalPrice != null) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: SarText(
                                  price: item.originalPrice!.toStringAsFixed(2),
                                  strikeThrough: item.isGift,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        _GiftBadge(item: item),
                        const SizedBox(height: 10),
                        _ExpressBadge(item: item),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Vertical divider
                  SizedBox(
                    height: 50,
                    child: VerticalDivider(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Stepper — replaced by a plain count on a granted line, whose
                  // quantity the offer owns.
                  if (item.isGift)
                    _GiftQuantity(quantity: item.quantity)
                  else
                    _EditableQuantityWidget(
                      quantity: item.quantity,
                      maxQuantity: item.maxQuantity,
                      isProcessing: isProcessing,
                      onIncrement: onIncrement,
                      onDecrement: onDecrement,
                      onUpdateQuantity: onUpdateQuantity,
                    ),
                  const SizedBox(width: 24),

                  // Total
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${'cart.subtotal'.tr()}:',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 3),
                      SarText(
                        price: item.totalPrice.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          color: ColorsManager.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Remove & Fav buttons
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      WishlistHeartButton(
                        productId: item.productId,
                        noBackground: true,
                        hideTooltip: true,
                      ),
                      const SizedBox(height: 12),
                      IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.delete_outline, size: 22),
                        color: ColorsManager.errorFill,
                        splashRadius: 20,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
          ),
        ),
      );
    }


    Widget _buildMobileLayout(BuildContext context) {
      final locale = Localizations.localeOf(context).languageCode;
      final h = AppSizeHorizontal.instance;
      final v = AppSizeVertical.instance;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final cardBg = isDark ? ColorsManager.surfaceDarkCard : Colors.white;

      return GestureDetector(
        onTap: () => AppNavigator.pushNamed(
          context,
          '${Routes.productDetails}/${SlugUtils.slugify(item.name, item.productId)}',
        ),
        child: Container(
          padding: EdgeInsets.all(h.s12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              CustomNetworkImage.rounded(
                imageUrl: item.imageUrl,
                width: 80,
                height: 80,
                borderRadius: 12,
                fit: BoxFit.cover,
                backgroundColor: isDark ? const Color(0xFF2C2C2E) : ColorsManager.backgroundCard,
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.localizedBrandName(locale) != null && item.localizedBrandName(locale)!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          item.localizedBrandName(locale)!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF00BFA5),
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Text(
                      item.localizedName(locale),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: isDark ? Colors.white : ColorsManager.defaultText,
                      ),
                    ),
                    SizedBox(height: v.s4),
                    Row(
                      children: [
                        // A granted line costs nothing — say so, rather than showing a
                        // 0.00 that reads like a pricing error.
                        if (item.isGift)
                          Flexible(
                            child: Text(
                              'cart.gift_free'.tr(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: ColorsManager.successFill,
                              ),
                            ),
                          )
                        else
                        Flexible(
                          child: SarText(
                            price: item.totalPrice.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: ColorsManager.primaryColor,
                            ),
                          ),
                        ),
                        if (item.originalPrice != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: SarText(
                              price: (item.originalPrice! * item.quantity).toStringAsFixed(2),
                              strikeThrough: item.isGift,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey[500] : ColorsManager.inputBorder,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    _GiftBadge(item: item),
                    SizedBox(height: v.s8),

                    // Stepper and Badges in the same row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // The offer owns a gift's quantity, so no stepper here.
                        if (item.isGift)
                          _GiftQuantity(quantity: item.quantity)
                        else
                          _EditableQuantityWidget(
                            quantity: item.quantity,
                            maxQuantity: item.maxQuantity,
                            isProcessing: isProcessing,
                            onIncrement: onIncrement,
                            onDecrement: onDecrement,
                            onUpdateQuantity: onUpdateQuantity,
                          ),

                        // Badges on the left
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (item.isExpressEligible)
                            SvgPicture.asset(
                              Localizations.localeOf(context).languageCode == 'ar'
                                  ? Assets.shippingExpressAR
                                  : Assets.shippingExpress,
                              height: 28,
                            ),

                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EDITABLE QUANTITY WIDGET
// ═══════════════════════════════════════════════════════════════════════════════
class _EditableQuantityWidget extends StatefulWidget {
  final int quantity;
  final int maxQuantity;
  final bool isProcessing;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final void Function(int) onUpdateQuantity;

  const _EditableQuantityWidget({
    required this.quantity,
    required this.maxQuantity,
    required this.isProcessing,
    required this.onIncrement,
    required this.onDecrement,
    required this.onUpdateQuantity,
  });

  @override
  State<_EditableQuantityWidget> createState() => _EditableQuantityWidgetState();
}

class _EditableQuantityWidgetState extends State<_EditableQuantityWidget> {
  late TextEditingController _ctrl;
  late FocusNode _focusNode;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.quantity}');
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_EditableQuantityWidget old) {
    super.didUpdateWidget(old);
    if (!_editing && widget.quantity != old.quantity) {
      _ctrl.text = '${widget.quantity}';
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _commitEdit();
      setState(() => _editing = false);
    }
  }

  void _commitEdit() {
    final raw = int.tryParse(_ctrl.text.trim());
    if (raw == null || raw < 1) {
      _ctrl.text = '${widget.quantity}';
      return;
    }
    if (raw > widget.maxQuantity) {
      _ctrl.text = '${widget.quantity}';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'cart.max_quantity_exceeded'.tr(
                namedArgs: {'max': '${widget.maxQuantity}'},
              ),
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    if (raw != widget.quantity) {
      widget.onUpdateQuantity(raw);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QuantityButton(
          icon: Icons.remove,
          onPressed: !widget.isProcessing ? widget.onDecrement : null,
        ),
        GestureDetector(
          onTap: () {
            if (widget.isProcessing) return;
            setState(() => _editing = true);
            _ctrl.selection = TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
            _focusNode.requestFocus();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _editing ? (isDark ? Colors.white12 : Colors.grey.shade100) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _editing
                ? TextField(
                    controller: _ctrl,
                    focusNode: _focusNode,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: isDark ? Colors.white : ColorsManager.defaultText,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      hoverColor: Colors.transparent,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    cursorColor: isDark ? Colors.white : ColorsManager.defaultText,
                    onSubmitted: (_) => _focusNode.unfocus(),
                  )
                : Text(
                    '${widget.quantity}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: isDark ? Colors.white : ColorsManager.defaultText,
                    ),
                  ),
          ),
        ),
        _QuantityButton(
          icon: Icons.add,
          onPressed: (!widget.isProcessing && widget.quantity < widget.maxQuantity) ? widget.onIncrement : null,
        ),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QuantityButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isActive = onPressed != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      cursor: isActive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 32,
          height: 38,
          color: Colors.transparent,
          child: Icon(
            icon,
            size: 20,
            color: isActive
                ? (isDark ? Colors.white : ColorsManager.defaultText)
                : (isDark ? Colors.white24 : Colors.grey.shade400),
          ),
        ),
      ),
    );
  }
}

/// A gift's quantity, shown as a plain count.
///
/// Replaces the stepper on a granted line: the offer owns that number, so an
/// edit would be silently corrected on the next cart change. Showing a disabled
/// stepper would be worse — it invites a tap that does nothing.
class _GiftQuantity extends StatelessWidget {
  final int quantity;
  const _GiftQuantity({required this.quantity});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '×$quantity',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white70 : ColorsManager.defaultText,
        ),
      ),
    );
  }
}

/// Names the offer that put this line in the cart, e.g. "🎁 Buy 1 Get 1".
///
/// Without it a free product simply appears and reads as a bug. The label is
/// the campaign's own name, so the customer sees the same wording marketing used.
class _GiftBadge extends StatelessWidget {
  final CartItemEntity item;
  const _GiftBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    if (!item.isGift) return const SizedBox.shrink();

    final label = item.localizedGiftLabel(context.locale.languageCode);

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColorsManager.successFill.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.card_giftcard_rounded, size: 13, color: ColorsManager.successFill),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label?.isNotEmpty == true ? label! : 'cart.gift_badge'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: ColorsManager.successFill,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpressBadge extends StatelessWidget {
  final CartItemEntity item;
  const _ExpressBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    if (!item.isExpressEligible) return const SizedBox.shrink();
    return SvgPicture.asset(
      Localizations.localeOf(context).languageCode == 'ar'
          ? Assets.shippingExpressAR
          : Assets.shippingExpress,
      height: 28,
    );
  }
}