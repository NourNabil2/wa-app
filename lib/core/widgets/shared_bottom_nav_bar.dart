import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fastway/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:fastway/features/cart/presentation/cubit/cart_state.dart';

class SharedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;

  const SharedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    context.locale; // Force rebuild on language change
    const activeColor = ColorsManager.primary2Color;
    final bg = isDark ? ColorsManager.surfaceDarkCard : Colors.white;
    final inactiveColor = isDark ? Colors.grey[500]! : Colors.grey[400]!;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: SharedNavBtn(svgIcon: 'assets/icons/home-icon.svg', 
                  active: currentIndex == 0, activeColor: activeColor, inactiveColor: inactiveColor,
                  onTap: () => onTap(0))),
              Expanded(child: SharedNavBtn(svgIcon: 'assets/icons/category-icon.svg', 
                  active: currentIndex == 1, activeColor: activeColor, inactiveColor: inactiveColor,
                  onTap: () => onTap(1))),

              // Center button (Siri animated ball, inline)
              Expanded(
                child: Center(
                  child: SharedSiriAnimatedFab(
                    isDark: isDark,
                    onPressed: () {}, // Center button acts as decoration only
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Image.asset('assets/images/logo-mobile.png', fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),

              // CART BUTTON (Middle) - Now a normal tab
              Expanded(
                child: BlocBuilder<CartCubit, CartState>(
                  builder: (context, state) {
                    int cartCount = 0;
                    if (state is CartLoaded) {
                      cartCount = state.cart.items.fold(0, (sum, item) => sum + item.quantity);
                    }
                    return SharedNavBtn(
                      svgIcon: 'assets/icons/cart-icons-nav.svg', 
                      active: currentIndex == 2, 
                      activeColor: activeColor, 
                      inactiveColor: inactiveColor,
                      badgeCount: cartCount,
                      onTap: () => onTap(2),
                    );
                  },
                ),
              ),

              Expanded(child: SharedNavBtn(svgIcon: 'assets/icons/profile.svg', 
                  active: currentIndex == 3, activeColor: activeColor, inactiveColor: inactiveColor,
                  onTap: () => onTap(3))),
            ],
          ),
        ),
      ),
    );
  }
}

class SharedNavBtn extends StatelessWidget {
  final dynamic faIcon;
  final String? svgIcon;
  final bool active;
  final Color activeColor, inactiveColor;
  final VoidCallback onTap;
  final int badgeCount;

  const SharedNavBtn({
    super.key,
    this.faIcon, 
    this.svgIcon,
    required this.active,
    required this.activeColor, 
    required this.inactiveColor, 
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children: [
        // Top indicator line
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 3,
          width: 32,
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
          ),
        ),
        
        Expanded(
          child: Center(
            child: Badge(
              isLabelVisible: badgeCount > 0,
              label: Transform.translate(
                offset: const Offset(0, 1),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              backgroundColor: ColorsManager.primary2Color,
              alignment: Alignment.topRight,
              offset: svgIcon != null ? const Offset(-6, 0) : const Offset(8, -8),
              child: svgIcon != null
                  ? SvgPicture.asset(
                      svgIcon!,
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(
                        active ? activeColor : inactiveColor,
                        BlendMode.srcIn,
                      ),
                    )
                  : FaIcon(
                      faIcon ?? FontAwesomeIcons.house,
                      size: 22,
                      color: active ? activeColor : inactiveColor,
                    ),
            ),
          ),
        ),
        
        const SizedBox(height: 5),
    ]),
  );
}

class SharedSiriAnimatedFab extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool isDark;

  const SharedSiriAnimatedFab({super.key, required this.onPressed, required this.child, required this.isDark});

  @override
  State<SharedSiriAnimatedFab> createState() => _SharedSiriAnimatedFabState();
}

class _SharedSiriAnimatedFabState extends State<SharedSiriAnimatedFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * 2 * math.pi;
          return Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ColorsManager.primary2Color.withValues(alpha: 0.3),
                  blurRadius: 10 + 4 * math.sin(angle),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Inner background with subtle animation
                ClipOval(
                  child: Container(
                    width: 56,
                    height: 56,
                    color: widget.isDark ? ColorsManager.surfaceDarkCard : Colors.white,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Transform.rotate(
                            angle: -angle, // 1.0 multiplier ensures a perfect seamless loop
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: SweepGradient(
                                  colors: [
                                    ColorsManager.primaryColor.withValues(alpha: 0.2),
                                    ColorsManager.primary2Color.withValues(alpha: 0.1),
                                    Colors.transparent,
                                    ColorsManager.primary2Color.withValues(alpha: 0.2),
                                    ColorsManager.primaryColor.withValues(alpha: 0.1),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Add a blur filter to soften the gradient into curved clouds instead of straight lines
                        Positioned.fill(
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                        Center(child: widget.child),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
