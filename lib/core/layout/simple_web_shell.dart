// lib/core/layout/simple_web_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../di/injection_container.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/user_data/user_cubit.dart';
import '../../features/user_data/user_repo.dart';
import 'package:fastway/core/responsive/responsive_layout.dart';
import 'package:fastway/features/announcements/presentation/widgets/announcements_banner.dart';
import 'package:fastway/features/home/presentation/widget/mobile_web_drawer.dart';
import 'web_footer.dart';
import 'web_header.dart';
import 'web_nav_controller.dart';
import 'web_shell.dart' show MobileWebCategoryBar;

/// A lightweight shell for standalone web pages (opened via direct URL / route,
/// not as a Dashboard tab).  It mirrors everything [WebShell] provides so the
/// header — including the category sub-bar — is always visible even after a
/// hard refresh.
///
/// Strategy: for every provider that [WebHeader] needs, we check whether an
/// ancestor already supplies it (because the page may also be rendered inside
/// the Dashboard).  If not, we create it here so the page is self-sufficient.
class SimpleWebShell extends StatefulWidget {
  final Widget content;
  final bool showFooter;
  final int selectedNavIndex;
  final VoidCallback? onSearchTap;
  final bool forceWhiteBackground;
  final ScrollController? scrollController;

  const SimpleWebShell({
    super.key,
    required this.content,
    this.showFooter = true,
    this.selectedNavIndex = -1,
    this.onSearchTap,
    this.forceWhiteBackground = false,
    this.scrollController,
  });

  @override
  State<SimpleWebShell> createState() => _SimpleWebShellState();
}

class _SimpleWebShellState extends State<SimpleWebShell> {
  late final ScrollController _scrollController;
  bool _ownsScrollController = false;

  // Providers we create only if they are absent from the ancestor tree.
  // We own them so we dispose them.
  // HomeCubit? _ownedHomeCubit;
  CartCubit? _ownedCartCubit;
  NotificationsCubit? _ownedNotificationsCubit;
  SettingsCubit? _ownedSettingsCubit;
  UserCubit? _ownedUserCubit;


  bool _showScrollToTop = false;
  ScrollPosition? _lastScrollPosition;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _ownsScrollController = true;
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final offset = notification.metrics.pixels;
      final show = offset > 400;
      if (show != _showScrollToTop) {
        setState(() => _showScrollToTop = show);
      }
      if (notification.metrics is ScrollPosition) {
        _lastScrollPosition = notification.metrics as ScrollPosition;
      }
    }
    return false;
  }

  void _scrollToTop() {
    const duration = Duration(milliseconds: 600);
    const curve = Curves.easeOutCubic;
    if (_scrollController.hasClients) {
      for (final pos in _scrollController.positions) {
        pos.animateTo(0, duration: duration, curve: curve);
      }
      return;
    }
    if (_lastScrollPosition != null && _lastScrollPosition!.hasPixels) {
      _lastScrollPosition!.animateTo(0, duration: duration, curve: curve);
    }
  }

  // ── Provider resolution helpers ────────────────────────────────────────────

  /// Returns true if [T] is already provided by an ancestor BlocProvider.
  bool _hasBlocProvider<T extends StateStreamableSource<Object?>>() {
    try {
      context.read<T>();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // HomeCubit — also loads categories needed by the sub-header bar
    // if (!_hasBlocProvider<HomeCubit>() && _ownedHomeCubit == null) {
    //   _ownedHomeCubit = sl<HomeCubit>()..loadHome();
    // }

    // CartCubit — cart badge in header
    if (!_hasBlocProvider<CartCubit>() && _ownedCartCubit == null) {
      _ownedCartCubit = sl<CartCubit>();
    }

    // NotificationsCubit — notification badge in header.
    // Trigger an initial load so the bell badge + dropdown are populated; the
    // header itself only READS the cubit state and never loads it, so without
    // this the web bell was always empty. Guard on login because the endpoint
    // is auth-only (a guest call would 401).
    if (!_hasBlocProvider<NotificationsCubit>() && _ownedNotificationsCubit == null) {
      _ownedNotificationsCubit = sl<NotificationsCubit>();
      if (UserRepository().isLoggedIn) {
        _ownedNotificationsCubit!.loadNotifications(refresh: true);
      }
    }

    // SettingsCubit — theme toggle in account dropdown
    if (!_hasBlocProvider<SettingsCubit>() && _ownedSettingsCubit == null) {
      _ownedSettingsCubit = sl<SettingsCubit>();
    }

    // UserCubit — used inside sub-header to gate auth-only items
    if (!_hasBlocProvider<UserCubit>() && _ownedUserCubit == null) {
      _ownedUserCubit = sl<UserCubit>();
    }

    // WebNavController intentionally NOT provided here.
    // This allows children like MobileWebDrawer to fall back to Navigator.pushNamed
    // since we are not inside a tabbed dashboard.
  }

  @override
  void dispose() {
    if (_ownsScrollController) {
      _scrollController.dispose();
    }
 //   _ownedHomeCubit?.close();
    _ownedCartCubit?.close();
    _ownedNotificationsCubit?.close();
    _ownedSettingsCubit?.close();
    _ownedUserCubit?.close();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobileWeb = isMobileLayout(context) || MediaQuery.sizeOf(context).width < 900;

    Widget body = Scaffold(
      backgroundColor: widget.forceWhiteBackground && Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : colorScheme.surface,
      endDrawer: isMobileWeb ? const MobileWebDrawer() : null,
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white24 
                  : const Color(0xFF222222),
              elevation: 4,
              mini: true,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              child: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 28),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: Column(
        children: [
          // ── Announcements Banner (desktop: fading | mobile-web: ticker) ──
          isMobileWeb ? const AnnouncementsTicker() : const AnnouncementsBanner(),

          // ── Header (with category sub-bar on desktop) ──────────────────
          WebHeader(onSearchTap: widget.onSearchTap),

          if (isMobileWeb) const MobileWebCategoryBar(),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              thickness: 6,
              radius: Radius.zero,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // content fills full width — do NOT use Align/Center here
                    // as it passes unconstrained width to children and breaks
                    // any SizedBox(width: double.infinity) or Stack inside.
                    widget.content,
                    if (widget.showFooter) const WebFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );

    // ── Wrap with any providers we own (innermost = last in list) ──────────
    // Order matters: BlocProviders that depend on others go inside.

    if (_ownedUserCubit != null) {
      body = BlocProvider<UserCubit>.value(value: _ownedUserCubit!, child: body);
    }
    if (_ownedSettingsCubit != null) {
      body = BlocProvider<SettingsCubit>.value(value: _ownedSettingsCubit!, child: body);
    }
    if (_ownedNotificationsCubit != null) {
      body = BlocProvider<NotificationsCubit>.value(value: _ownedNotificationsCubit!, child: body);
    }
    if (_ownedCartCubit != null) {
      body = BlocProvider<CartCubit>.value(value: _ownedCartCubit!, child: body);
    }
    // if (_ownedHomeCubit != null) {
    //   body = BlocProvider<HomeCubit>.value(value: _ownedHomeCubit!, child: body);
    // }

    // No WebNavController injected.

    return body;
  }
}