// lib/core/widgets/animated_cart_button.dart
// ✅ تحسينات الموبايل والـ UX

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/utils/assets.dart';
import 'package:fastway/core/widgets/CustomIcon.dart';
import 'package:fastway/features/cart/domain/entities/cart_entity.dart';
import 'package:fastway/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:fastway/features/cart/presentation/cubit/cart_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Compact version for ProductCard grid - محسّن للموبايل
class AnimatedCartButtonCompact extends StatefulWidget {
  final String productId;
  final String productName;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final bool isAvailable;
  final bool expandWidth;
  final bool autoCollapse;

  const AnimatedCartButtonCompact({
    super.key,
    required this.productId,
    required this.productName,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    this.isAvailable = true,
    this.expandWidth = false,
    this.autoCollapse = true,
  });

  @override
  State<AnimatedCartButtonCompact> createState() => _AnimatedCartButtonCompactState();
}

class _AnimatedCartButtonCompactState extends State<AnimatedCartButtonCompact> {
  /// Keep the last known item even when state transitions to AddingToCart / CartError.
  /// This prevents the button from flashing back to "Add" during a load.
  CartItemEntity? _cachedItem;

  CartItemEntity? _resolveItem(CartState state) {
    if (state is CartLoaded) {
      try {
        _cachedItem = state.cart.items.firstWhere((i) => i.productId == widget.productId);
      } catch (_) {
        _cachedItem = null;
      }
      return _cachedItem;
    }
    // During AddingToCart / CartError retain the previous value
    return _cachedItem;
  }

  bool _expanded = false;
  Timer? _collapseTimer;

  void _expand() {
    setState(() => _expanded = true);
    if (widget.autoCollapse) {
      _collapseTimer?.cancel();
      _collapseTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _expanded = false);
      });
    }
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      // ✅ Only rebuild this card when:
      //   • the full cart is refreshed (quantities changed)
      //   • this specific product is being loaded / finished loading
      // This prevents every card from animating when ONE product is touched.
      buildWhen: (previous, current) {
        if (current is CartLoaded || current is AddedToCart || current is CartToastError) return true;
        if (current is AddingToCart) return current.productId == widget.productId;
        return false;
      },
      builder: (context, state) {
        final cartItem = _resolveItem(state);
        final quantity = cartItem?.quantity ?? 0;
        // Loading only for the button that was pressed
        final isLoading = state is AddingToCart && state.productId == widget.productId;

        if (!widget.isAvailable) {
          return _UnavailableButton();
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axis: Axis.horizontal,
                axisAlignment: 1.0,
                child: child,
              ),
            );
          },
          child: quantity == 0
              ? Align(
                  key: const ValueKey('add'),
                  alignment: AlignmentDirectional.bottomEnd,
                  child: _AddButton(
                    isLoading: isLoading,
                    isDisabled: false,
                    expandWidth: widget.expandWidth,
                    onTap: () => _addToCart(context),
                  ),
                )
              : (_expanded || !widget.autoCollapse)
                  ? Align(
                      key: const ValueKey('counter'),
                      alignment: Alignment.bottomCenter,
                      child: _CounterButton(
                        quantity: quantity,
                        maxQuantity: cartItem!.maxQuantity,
                        isDisabled: isLoading,
                        onIncrement: () => _increment(context, cartItem),
                        onDecrement: () => _decrement(context, cartItem),
                        onUpdateQuantity: (qty) =>
                            context.read<CartCubit>().updateQuantity(cartItem.id, qty),
                        expandWidth: widget.expandWidth,
                      ),
                    )
                  : Align(
                      key: const ValueKey('collapsed_qty'),
                      alignment: AlignmentDirectional.bottomEnd,
                      child: _CollapsedQuantityButton(
                        quantity: quantity,
                        isLoading: isLoading,
                        onTap: _expand,
                        expandWidth: widget.expandWidth,
                      ),
                    ),
        );
      },
    );
  }

  void _addToCart(BuildContext context) {
    context.read<CartCubit>().addToCart(
      productId: widget.productId,
      quantity: 1,
    );
    _expand();
  }

  void _increment(BuildContext context, CartItemEntity item) {
    context.read<CartCubit>().incrementQuantity(item.id);
    _expand();
  }

  void _decrement(BuildContext context, CartItemEntity item) {
    if (item.quantity <= 1) {
      context.read<CartCubit>().removeItem(item.id);
      // Auto collapses when removed
    } else {
      context.read<CartCubit>().decrementQuantity(item.id);
      _expand();
    }
  }
}

class _CollapsedQuantityButton extends StatelessWidget {
  final int quantity;
  final bool isLoading;
  final VoidCallback onTap;
  final bool expandWidth;

  const _CollapsedQuantityButton({
    required this.quantity,
    required this.isLoading,
    required this.onTap,
    this.expandWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: expandWidth ? double.infinity : 38,
        height: 38,
        decoration: BoxDecoration(
          color: ColorsManager.primary2Color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.primary2Color.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : Center(
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
      ),
    );
  }
}

// ── Add button (filled circle) - Pro style ───────────────────────────────
/// زر "أضف للسلة" — always a small filled circle with white + icon
class _AddButton extends StatefulWidget {
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;
  final bool expandWidth;

  const _AddButton({
    required this.isLoading,
    this.isDisabled = false,
    required this.onTap,
    this.expandWidth = false,
  });

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isFilled = widget.expandWidth;
    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isLoading && !widget.isDisabled) {
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (!widget.isLoading && !widget.isDisabled) {
          widget.onTap();
        }
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: Opacity(
        opacity: widget.isDisabled ? 0.5 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.expandWidth ? double.infinity : 38,
          height: widget.expandWidth ? 50 : 38,
          decoration: BoxDecoration(
            color: isFilled
                ? (_isPressed
                    ? ColorsManager.primary2Color.withValues(alpha: 0.85)
                    : ColorsManager.primary2Color)
                : (_isPressed
                    ? ColorsManager.primary2Color.withValues(alpha: 0.08)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: isFilled
                ? null
                : Border.all(
                    color: ColorsManager.primary2Color,
                    width: 1.5,
                  ),
          ),
          child: widget.isLoading
              ? Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isFilled ? Colors.white : ColorsManager.primary2Color,
                    ),
                  ),
                )
              : widget.expandWidth
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CustomIcon(
                              assetPath: Assets.navCartIcon, 
                              color: Colors.white, 
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                'product.add_to_cart'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const CustomIcon(
                      assetPath: Assets.navCartIcon, 
                      color: ColorsManager.primary2Color, 
                      size: 22,
                    ),
        ),
      ),
    );
  }
}

// ── +/- counter - محسّن ────────────────────────────────────────────
/// زر العداد: -/+  مع حجم أكبر وأسهل للضغط
class _CounterButton extends StatefulWidget {
  final int quantity;
  final int maxQuantity;
  final bool isDisabled;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<int> onUpdateQuantity;
  final bool expandWidth;

  const _CounterButton({
    super.key,
    required this.quantity,
    required this.maxQuantity,
    this.isDisabled = false,
    required this.onIncrement,
    required this.onDecrement,
    required this.onUpdateQuantity,
    this.expandWidth = false,
  });

  @override
  State<_CounterButton> createState() => _CounterButtonState();
}

class _CounterButtonState extends State<_CounterButton> {
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
  void didUpdateWidget(_CounterButton old) {
    super.didUpdateWidget(old);
    // Keep display in sync unless the user is actively typing
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
      // Reset to current quantity if input is invalid
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
    final atMax = widget.quantity >= widget.maxQuantity;

    // Outlined style for expanded mode, filled for compact
    final bool outlined = widget.expandWidth;
    final Color bgColor = outlined ? Colors.transparent : ColorsManager.primary2Color;
    final Color iconColor = outlined
        ? (isDark ? Colors.white : ColorsManager.primary2Color)
        : Colors.white;
    final Color countColor = outlined
        ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
        : Colors.white;
    final Color dimIconColor = outlined
        ? iconColor.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.4);

    return Opacity(
      opacity: widget.isDisabled ? 0.5 : 1.0,
      child: IgnorePointer(
        ignoring: widget.isDisabled,
        child: Container(
          width: widget.expandWidth ? double.infinity : null,
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: widget.expandWidth ? 4 : 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8), // Match AddButton radius
            border: outlined
                ? Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : ColorsManager.primary2Color.withValues(alpha: 0.3),
                    width: 1.5,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: widget.expandWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: widget.expandWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              // ── Decrement / Delete ──
              _Btn(
                icon: widget.quantity == 1
                    ? Icons.delete_outline
                    : Icons.remove,
                onTap: widget.onDecrement,
                size: 20,
                padding: 4,
                color: iconColor,
              ),

              if (widget.expandWidth) const SizedBox(width: 24),

              // ── Editable quantity ──
              _buildQuantityCenter(countColor),

              if (widget.expandWidth) const SizedBox(width: 24),

              // ── Increment ──
              _Btn(
                icon: Icons.add,
                onTap: atMax ? () {} : widget.onIncrement,
                size: 20,
                padding: 4,
                color: atMax ? dimIconColor : iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityCenter(Color textColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool outlined = widget.expandWidth;
    final Color circleBg = outlined
        ? Colors.transparent
        : Colors.white.withValues(alpha: 0.2);

    return GestureDetector(
      onTap: () {
        setState(() => _editing = true);
        _ctrl.selection =
            TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
        _focusNode.requestFocus();
      },
      child: AnnotatedRegion<MouseCursor>(
        value: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.expandWidth ? 48 : 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: circleBg,
            borderRadius: BorderRadius.zero,
          ),
          child: _editing
              ? Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                      cursorColor: textColor,
                      selectionColor: textColor.withValues(alpha: 0.15),
                      selectionHandleColor: textColor,
                    ),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focusNode,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    cursorColor: textColor,
                    style: TextStyle(
                      fontSize: widget.expandWidth ? 16 : 14,
                      fontWeight: FontWeight.w500, // Slightly bolder so it looks identical to normal state
                      color: textColor,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onSubmitted: (_) {
                      _focusNode.unfocus();
                    },
                  ),
                )
              : _AnimatedCount(
                  quantity: widget.quantity,
                  color: textColor,
                  fontSize: widget.expandWidth ? 16 : 14,
                ),
        ),
      ),
    );
  }
}

/// زر واحد (-/+) مع تحسينات الـ press feedback
class _Btn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double padding;
  final Color color;

  const _Btn({
    required this.icon,
    required this.onTap,
    this.size = 16,
    this.padding = 6,
    this.color = Colors.white,
  });

  @override
  State<_Btn> createState() => _BtnState();
}

class _BtnState extends State<_Btn> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        decoration: BoxDecoration(
          color: _isPressed
              ? widget.color.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.zero,
        ),
        child: Center(
          child: Icon(
            widget.icon,
            size: widget.size,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

/// عدد المنتجات مع animation
class _AnimatedCount extends StatelessWidget {
  final int quantity;
  final Color color;
  final double fontSize;

  const _AnimatedCount({required this.quantity, this.color = Colors.white, this.fontSize = 16});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: child,
      ),
      child: Text(
        '$quantity',
        key: ValueKey<int>(quantity),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w300,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// زر غير متاح
class _UnavailableButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      // ✅ نفس الحجم للـ consistency
      width: 44.r,
      height: 44.r,
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.zero,
      ),
    );
  }
}

// ── Full version for Product Details ──────────────────────────────────────
/// نسخة زر "أضف للسلة" بعرض كامل لشاشة تفاصيل المنتج مع أنيميشن Swipe
class AnimatedCartButtonFull extends StatefulWidget {
  final String productId;
  final bool isAvailable;

  const AnimatedCartButtonFull({
    super.key,
    required this.productId,
    this.isAvailable = true,
  });

  @override
  State<AnimatedCartButtonFull> createState() => _AnimatedCartButtonFullState();
}

class _AnimatedCartButtonFullState extends State<AnimatedCartButtonFull> {
  CartItemEntity? _cachedItem;

  CartItemEntity? _resolveItem(CartState state) {
    if (state is CartLoaded) {
      try {
        _cachedItem = state.cart.items.firstWhere((i) => i.productId == widget.productId);
      } catch (_) {
        _cachedItem = null;
      }
      return _cachedItem;
    }
    // Retain last item during AddingToCart / CartError / other transient states
    return _cachedItem;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      // ✅ Same scoped rebuild as the compact button:
      //   only rebuild for CartLoaded / AddedToCart / this product's AddingToCart
      buildWhen: (previous, current) {
        if (current is CartLoaded || current is AddedToCart || current is CartToastError) return true;
        if (current is AddingToCart) return current.productId == widget.productId;
        return false;
      },
      builder: (context, state) {
        final cartItem = _resolveItem(state);
        final quantity = cartItem?.quantity ?? 0;
        final isLoading = state is AddingToCart && state.productId == widget.productId;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        if (!widget.isAvailable) {
          return SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: Text('product.unavailable'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black54)),
            ),
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(0.0, 0.4),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: offsetAnimation,
                child: child,
              ),
            );
          },
          child: quantity == 0
              ? _FullAddButton(
                  key: const ValueKey('add_full'),
                  isLoading: isLoading,
                  onTap: () => context.read<CartCubit>().addToCart(productId: widget.productId, quantity: 1),
                )
              : _FullCounterButton(
                  key: const ValueKey('counter_full'),
                  quantity: quantity,
                  maxQuantity: cartItem!.maxQuantity,
                  itemId: cartItem.id,
                  isLoading: isLoading,
                  isDark: isDark,
                  onIncrement: () => context.read<CartCubit>().incrementQuantity(cartItem.id),
                  onDecrement: () {
                    if (cartItem.quantity == 1) {
                      context.read<CartCubit>().removeItem(cartItem.id);
                    } else {
                      context.read<CartCubit>().decrementQuantity(cartItem.id);
                    }
                  },
                  onUpdateQuantity: (qty) =>
                      context.read<CartCubit>().updateQuantity(cartItem.id, qty),
                ),
        );
      },
    );
  }
}

class _FullAddButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _FullAddButton({super.key, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsManager.primary2Color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onTap,
        child: isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text('product.actions.add_to_cart'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }
}

class _FullCounterButton extends StatefulWidget {
  final int quantity;

  final int maxQuantity;
  final String itemId;
  final bool isLoading;
  final bool isDark;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final void Function(int) onUpdateQuantity;

  const _FullCounterButton({
    super.key,
    required this.quantity,
    required this.maxQuantity,
    required this.itemId,
    required this.isLoading,
    required this.isDark,
    required this.onIncrement,
    required this.onDecrement,
    required this.onUpdateQuantity,
  });

  @override
  State<_FullCounterButton> createState() => _FullCounterButtonState();
}

class _FullCounterButtonState extends State<_FullCounterButton> {
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
  void didUpdateWidget(_FullCounterButton old) {
    super.didUpdateWidget(old);
    // Keep display in sync unless the user is actively typing
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
      // Reset to current quantity if input is invalid
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
    final atMax = widget.quantity >= widget.maxQuantity;

    return Container(
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: ColorsManager.primary2Color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Decrement / Delete ──────────────────────────────
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: widget.isLoading ? null : widget.onDecrement,
              child: SizedBox(
                width: 64,
                height: 52,
                child: Icon(
                  widget.quantity == 1
                      ? Icons.delete_outline_rounded
                      : Icons.remove_rounded,
                  color: ColorsManager.primary2Color,
                  size: 24,
                ),
              ),
            ),
          ),

          // ── Editable quantity ───────────────────────────────
          GestureDetector(
            onTap: () {
              setState(() => _editing = true);
              _ctrl.selection =
                  TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
              _focusNode.requestFocus();
            },
            child: AnnotatedRegion<MouseCursor>(
              value: SystemMouseCursors.text,
              child: Container(
                width: 64,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _editing
                      ? (widget.isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : ColorsManager.primary2Color.withValues(alpha: 0.08))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _editing
                    ? TextField(
                        controller: _ctrl,
                        focusNode: _focusNode,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: widget.isDark
                              ? Colors.white
                              : ColorsManager.primary2Color,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onSubmitted: (_) {
                          _focusNode.unfocus();
                        },
                      )
                    : AnimatedSwitcher(
                         duration: const Duration(milliseconds: 200),
                         transitionBuilder: (child, anim) =>
                             ScaleTransition(scale: anim, child: child),
                         child: Text(
                           '${widget.quantity}',
                           key: ValueKey(widget.quantity),
                           style: TextStyle(
                             fontSize: 18,
                             fontWeight: FontWeight.w800,
                             color: widget.isDark ? Colors.white : Colors.black87,
                           ),
                         ),
                       ),
              ),
            ),
          ),

          // ── Increment ───────────────────────────────────────
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: atMax || widget.isLoading ? null : widget.onIncrement,
              child: SizedBox(
                width: 64,
                height: 52,
                child: Icon(
                  Icons.add_rounded,
                  color: atMax
                      ? Colors.grey.shade400
                      : ColorsManager.primary2Color,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}