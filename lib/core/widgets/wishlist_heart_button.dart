import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/wishlist/presentation/cubit/wishlist_cubit.dart';
import '../../features/wishlist/presentation/cubit/wishlist_state.dart';
import '../../features/user_data/user_cubit.dart';
import '../../core/routes/routes.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// A heart icon button that is fully self-aware:
/// - Resolves `isWishlisted` from [WishlistCubit] without any prop drilling.
/// - Uses the cubit's [WishlistCubit.isProductWishlisted] sync getter during
///   [WishlistLoading] so the icon never flickers to unfilled during reloads.
/// - Handles [WishlistItemAdded] / [WishlistItemRemoved] transient states for
///   per-product optimistic display while the server round-trip completes.
class WishlistHeartButton extends StatelessWidget {
  final String productId;
  final bool noBackground;
  final double? iconSize;
  final bool hideTooltip;

  const WishlistHeartButton({
    super.key,
    required this.productId,
    this.noBackground = false,
    this.iconSize,
    this.hideTooltip = false,
  });

  @override
  Widget build(BuildContext context) {
    // Capture the outer context — guaranteed to have Navigator in scope.
    // The BlocBuilder's inner `ctx` may not in deep widget trees (web layouts).
    return BlocBuilder<WishlistCubit, WishlistState>(
      // Only rebuild when this product's specific wishlist status could change.
      // Without buildWhen, ALL heart buttons rebuild on every WishlistLoaded
      // emission (e.g. on page entry), causing mass simultaneous repaints.
      buildWhen: (previous, current) {
        if (current is WishlistLoaded) return true;
        if (current is WishlistItemToggling) return current.productId == productId;
        if (current is WishlistItemAdded) return current.productId == productId;
        if (current is WishlistItemRemoved) return current.productId == productId;
        return false;
      },
      builder: (ctx, state) {
        final cubit = ctx.read<WishlistCubit>();
        final isToggling =
            state is WishlistItemToggling && state.productId == productId;

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
        } else if (state is WishlistLoading || state is WishlistItemToggling) {
          isWishlisted = cubit.isProductWishlisted(productId) ?? false;
        } else if (state is WishlistItemAdded || state is WishlistItemRemoved) {
          isWishlisted = cubit.isProductWishlisted(productId) ?? false;
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;

        final iconButton = IconButton(
          padding: noBackground ? const EdgeInsets.all(6) : const EdgeInsets.all(4.0),
          iconSize: iconSize ?? 24.0,
          constraints: noBackground ? const BoxConstraints() : null,
          hoverColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
          highlightColor: Theme.of(context).primaryColor.withValues(alpha: 0.25),
          splashColor: Theme.of(context).primaryColor.withValues(alpha: 0.25),
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          tooltip: hideTooltip 
              ? null 
              : (isWishlisted
                  ? 'wishlist.remove_success'.tr()
                  : 'wishlist.add_success'.tr()),
          onPressed: isToggling
              ? null
              : () {
                  // Use outer context for navigation — more reliable scope
                  final userCubit = context.read<UserCubit>();
                  if (!userCubit.isLoggedIn) {
                    // Navigate to login using the root navigator key as
                    // ultimate fallback in case context is stale
                    final nav = Navigator.maybeOf(context) ??
                        Navigator.of(context, rootNavigator: true);
                    nav.pushNamed(Routes.login);
                    return;
                  }
                  cubit.toggleProduct(productId);
                },
          icon: isToggling
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: child,
                  ),
                  child: FaIcon(
                    isWishlisted ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                    key: ValueKey(isWishlisted),
                    size: iconSize ?? 18,
                    color: isWishlisted
                        ? Colors.red
                        : (isDark && !noBackground ? Colors.white : (noBackground ? (isDark ? Colors.white : Colors.black87) : Colors.black87)),
                  ),
                ),
        );

        if (noBackground) return iconButton;

        return Container(
          margin: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.3) 
                : Colors.white.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: iconButton,
        );
      },
    );
  }
}

