// lib/core/widgets/wishlist_full_button.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/wishlist/presentation/cubit/wishlist_cubit.dart';
import '../../features/wishlist/presentation/cubit/wishlist_state.dart';
import '../../features/user_data/user_cubit.dart';
import '../routes/routes.dart';
import '../routes/app_navigator.dart';

/// A full-width "Add to Wishlist" / "Saved to Wishlist" button.
/// Used on out-of-stock product pages instead of the disabled cart button.
/// Shares the same height and border-radius as [AnimatedCartButtonFull].
class WishlistFullButton extends StatelessWidget {
  final String productId;
  final double height;

  const WishlistFullButton({
    super.key,
    required this.productId,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final outerCtx = context;

    return BlocBuilder<WishlistCubit, WishlistState>(
      builder: (ctx, state) {
        final cubit = ctx.read<WishlistCubit>();

        // ── Resolve current wishlisted status ──────────────────────────────
        bool isWishlisted = false;
        if (state is WishlistLoaded) {
          isWishlisted =
              state.wishlist.items.any((i) => i.productId == productId);
        } else if (state is WishlistItemAdded && state.productId == productId) {
          isWishlisted = true;
        } else if (state is WishlistItemRemoved &&
            state.productId == productId) {
          isWishlisted = false;
        } else if (state is WishlistItemToggling &&
            state.productId == productId) {
          // Keep last known state during toggle — read from cubit cache
          isWishlisted = cubit.isProductWishlisted(productId) ?? false;
        }

        final isToggling =
            state is WishlistItemToggling && state.productId == productId;

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = Theme.of(context).colorScheme.primary;

        return SizedBox(
          height: height,
          width: double.infinity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: isWishlisted
                  ? null
                  : LinearGradient(
                      colors: [
                        primaryColor.withValues(alpha: 0.85),
                        primaryColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: isWishlisted
                  ? (isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF5F5F7))
                  : null,
              borderRadius: BorderRadius.zero,
              border: isWishlisted
                  ? Border.all(
                      color: primaryColor.withValues(alpha: 0.4),
                      width: 1.5,
                    )
                  : null,
              boxShadow: isWishlisted
                  ? null
                  : [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.zero,
                onTap: isToggling
                    ? null
                    : () {
                        final user = outerCtx.read<UserCubit>().state;
                        if (user == null) {
                          AppNavigator.pushNamed(outerCtx, Routes.auth);
                          return;
                        }
                        cubit.toggleProduct(productId);
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: child,
                        ),
                        child: isToggling
                            ? SizedBox(
                                key: const ValueKey('loading'),
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isWishlisted
                                      ? primaryColor
                                      : Colors.white,
                                ),
                              )
                            : Icon(
                                key: ValueKey(isWishlisted),
                                isWishlisted
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isWishlisted
                                    ? primaryColor
                                    : Colors.white,
                                size: 22,
                              ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          key: ValueKey(isWishlisted),
                          isWishlisted
                              ? 'wishlist.saved'.tr()
                              : 'wishlist.add_to_wishlist'.tr(),
                          style: TextStyle(
                            color: isWishlisted ? primaryColor : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
      },
    );
  }
}
