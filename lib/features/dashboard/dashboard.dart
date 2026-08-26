import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/di/injection_container.dart';
import 'package:fastway/core/layout/web_shell.dart';
import 'package:fastway/core/layout/web_nav_controller.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/theme/text_theme.dart';
import 'package:fastway/core/utils/assets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fastway/core/widgets/custom_snack_bar.dart';
import 'package:fastway/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:fastway/features/cart/presentation/cubit/cart_state.dart';
import 'package:fastway/features/home/presentation/view/home_tab_screen.dart';
import 'package:fastway/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:fastway/features/orders/presentation/screens/orders_list_screen.dart';
import 'package:fastway/features/points/presentation/cubit/points_cubit.dart';
import 'package:fastway/features/points/presentation/view/points_screen.dart';
import 'package:fastway/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:fastway/features/profile/presentation/view/profile_screen.dart';
import 'package:fastway/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:fastway/features/user_data/auth_guard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fastway/features/user_data/user_cubit.dart';
import '../../core/widgets/shared_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../core/routes/routes.dart';
import 'package:fastway/features/cart/presentation/view/cart_screen.dart';
import 'package:fastway/features/blog/presentation/cubit/blog_cubit.dart';
import 'package:fastway/features/blog/presentation/cubit/blog_state.dart';
import 'package:fastway/features/home/presentation/view/categories_screen.dart';
import 'package:fastway/features/announcements/presentation/widgets/announcements_banner.dart';
import 'package:fastway/core/utils/platform_reload.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:fastway/features/home/presentation/cubit/home_cubit.dart';
import 'package:fastway/features/home/presentation/cubit/home_state.dart';
import 'package:dio/dio.dart';
import 'package:fastway/features/popup_banner/popup_banner_service.dart';

class Dashboard extends StatefulWidget {
  final int? initialIndex;
  const Dashboard({super.key, this.initialIndex});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late final WebNavController _navController;

  @override
  void initState() {
    super.initState();
    _navController = WebNavController();
    if (widget.initialIndex != null) {
      _navController.navigateTo(widget.initialIndex!);
    }

    // Only show popup banner if the user is explicitly on the Home tab
    _navController.addListener(_checkPopupBanner);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPopupBanner();
    });
  }

  void _checkPopupBanner() {
    if (!mounted) return;
    if (_navController.currentIndex == 0) {
      _navController.removeListener(_checkPopupBanner);
      // Delay to let the home screen fully render first
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        // Ensure Dashboard is still the top-most route (not obscured by product details, cart, etc.)
        final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
        if (isCurrentRoute) {
          PopupBannerService.showIfNeeded(context, sl<Dio>());
        }
      });
    }
  }

  @override
  void dispose() {
    _navController.removeListener(_checkPopupBanner);
    // Do NOT call _navController.dispose() — it is a global singleton.
    // Disposing it would make it unusable when Dashboard is re-created
    // (e.g. after a browser refresh + logo click navigation).
    super.dispose();
  }

  void _onTabTap(int index) {
    // 👈 كل التابات دلوقتي محتاجة login ما عدا Home و Articles و الحساب
    const protectedTabs = [4]; // Orders is 4, Profile handles its own auth state

    if (protectedTabs.contains(index)) {
      if (!AuthGuard.check(context)) return;
    }

    _navController.navigateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<OrdersCubit>(create: (_) => sl<OrdersCubit>()),
      ],
      // ✅ Global CartToastError listener — covers every tab on Dashboard
      // (home, search, category, brand) that doesn't have its own listener.
      child: BlocListener<CartCubit, CartState>(
        listenWhen: (_, curr) => curr is CartToastError,
        listener: (context, state) {
          if (state is CartToastError) {
            CustomSnackBar.show(context, message: state.message, type: SnackBarType.error);
          }
        },
        child: ChangeNotifierProvider.value(
          value: _navController,
          // On web (any viewport width) → WebShell with header + footer.
          // On native app → floating mobile nav bar, no footer.
          child: kIsWeb
              ? _DesktopDashboard(onTabTap: _onTabTap)
              : _MobileDashboard(onTabTap: _onTabTap),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOBILE DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════════

class _MobileDashboard extends StatefulWidget {
  final ValueChanged<int> onTabTap;

  const _MobileDashboard({required this.onTabTap});

  @override
  State<_MobileDashboard> createState() => _MobileDashboardState();
}

class _MobileDashboardState extends State<_MobileDashboard> {
  bool _isVisible = true;
  DateTime? _lastPressedAt;

  @override
  Widget build(BuildContext context) {
    context.locale; // Force rebuild on language change
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: context.read<WebNavController>(),
      builder: (context, _) {
        final currentIndex = context.read<WebNavController>().currentIndex;
        final screens = [
          const HomeTabScreen(),           // Index 0
          const CategoriesScreen(),        // Index 1
          const CartScreen(isTab: true),   // Index 2
          const ProfileScreen(isTab: true), // Index 3
          const _AuthGatedTab(child: OrdersListScreen()), // Index 4 👈 جديد
        ];

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;

            if (currentIndex != 0) {
              widget.onTabTap(0);
              return;
            }

            final now = DateTime.now();
            final canExit = _lastPressedAt != null &&
                now.difference(_lastPressedAt!) < const Duration(seconds: 2);

            if (!canExit) {
              _lastPressedAt = now;
              CustomSnackBar.show(
                context,
                message: 'dashboard.press_back_again_to_exit'.tr(),
                type: SnackBarType.info,
              );
              return;
            }

            SystemNavigator.pop();
          },
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            extendBody: true,
            body: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (currentIndex == 0 || currentIndex == 1 || currentIndex == 2) return false; // Do not hide on Home, Categories, or Cart screens

              if (notification.metrics.axis == Axis.vertical) {
                // Do not hide if the screen content is too short to scroll
                if (notification.metrics.maxScrollExtent <= 0) {
                  if (!_isVisible) setState(() => _isVisible = true);
                  return false;
                }

                // Hide only when reaching the very bottom of the screen
                if (notification.metrics.extentAfter < 20) {
                  if (_isVisible) setState(() => _isVisible = false);
                } else {
                  if (!_isVisible) setState(() => _isVisible = true);
                }
              }
              return false; // let the notification bubble up
            },
            child: SafeArea(
              bottom: false,
              top: currentIndex != 0,
              child: Column(
                children: [
                  if (kIsWeb) const AnnouncementsTicker(),
                  Expanded(child: IndexedStack(index: currentIndex, children: screens)),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Builder(
            builder: (context) {
              if (kIsWeb) return const SizedBox.shrink();
              
              final homeState = context.watch<HomeCubit>().state;
              final isHomeLoading = homeState is HomeLoading || homeState is HomeInitial;
              
              // Hide the bottom navigation bar if the splash screen is showing
              if (currentIndex == 0 && isHomeLoading) {
                return const SizedBox.shrink();
              }

              return AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                offset: _isVisible ? Offset.zero : const Offset(0, 1.5), // slide down off-screen
                child: SharedBottomNavBar(
                  currentIndex: currentIndex,
                  onTap: (idx) {
                    if (!_isVisible) setState(() => _isVisible = true);
                    widget.onTabTap(idx);
                  },
                  isDark: isDark,
                ),
              );
            }
          ),
        ),
        );
      },
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════════
// DESKTOP DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════════

// lib/features/dashboard/dashboard.dart

/// A shared BlogCubit is provided at the desktop dashboard level so that
/// both the WebHeader nav bar (which shows category chips) and the BlogScreen
/// tab read from the same state — no double API call.
class _DesktopDashboard extends StatefulWidget {
  final ValueChanged<int> onTabTap;
  const _DesktopDashboard({required this.onTabTap});

  @override
  State<_DesktopDashboard> createState() => _DesktopDashboardState();
}

class _DesktopDashboardState extends State<_DesktopDashboard> {
  late final BlogCubit _blogCubit;

  @override
  void initState() {
    super.initState();
    // Get the singleton — do NOT store it as 'late final' since we won't close it
    _blogCubit = sl<BlogCubit>();
    // Kick off the initial load only if not already loaded
    if (_blogCubit.state is BlogInitial) {
      _blogCubit.loadPosts();
    }
  }

  @override
  void dispose() {
    // Do NOT close _blogCubit — it is a global singleton managed by GetIt
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BlogCubit>.value(
      value: _blogCubit,
      child: ListenableBuilder(
        listenable: context.read<WebNavController>(),
        builder: (context, _) {
          final currentIndex = context.read<WebNavController>().currentIndex;

          final screens = <Widget>[
            const HomeTabScreen(),           // Index 0
            const CategoriesScreen(),        // Index 1
            const CartScreen(isTab: true),   // Index 2
            const ProfileScreen(isTab: true), // Index 3
            _AuthGatedTab(
              child: BlocProvider<OrdersCubit>(
                create: (_) => sl<OrdersCubit>(),
                child: const OrdersListScreen(isTab: true),
              ),
            ), // Index 4
          ];

          return WebShell(
            selectedNavIndex: currentIndex,
            content: IndexedStack(
              index: currentIndex,
              children: screens,
            ),
          );
        },
      ),
    );
  }
}
class _AuthGatedTab extends StatelessWidget {
  final Widget child;
  const _AuthGatedTab({required this.child});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.read<UserCubit>().isLoggedIn;
    return isLoggedIn ? child : const SizedBox.shrink();
  }
}
