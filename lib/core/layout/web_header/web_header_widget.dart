import 'dart:ui' as ui;
import 'package:fastway/core/layout/web_nav_controller.dart';
import 'package:fastway/core/theme/text_theme.dart';
import 'package:fastway/core/utils/slug_utils.dart';
// lib/core/layout/web_header.dart
import 'package:fastway/core/routes/app_navigator.dart';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/utils/assets.dart';
import 'package:fastway/core/widgets/CustomIcon.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fastway/core/widgets/empty_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fastway/core/di/injection_container.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/features/user_data/user_repo.dart';
import 'package:fastway/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:fastway/features/cart/presentation/cubit/cart_state.dart';
import 'package:fastway/features/home/presentation/cubit/home_cubit.dart';
import 'package:fastway/features/home/presentation/cubit/home_state.dart';
import 'package:fastway/features/search/presentation/cubit/search_cubit.dart';
import 'package:fastway/features/search/presentation/view/search_sheet.dart';
import 'package:fastway/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:fastway/core/layout/web_header/notifications_dropdown.dart';
import 'package:fastway/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:fastway/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:fastway/core/cubit/delivery_location/delivery_location_cubit.dart';
import 'package:fastway/core/cubit/delivery_location/delivery_location_state.dart';
import 'package:fastway/features/user_data/user_cubit.dart';
import 'package:fastway/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:fastway/features/wishlist/presentation/cubit/wishlist_state.dart';
import 'package:fastway/features/home/presentation/widget/location_picker_sheet.dart';
import 'package:fastway/core/utils/platform_reload.dart';


import 'sub_header_buttons.dart';
import 'category_dropdown.dart';
import 'account_dropdown.dart';
import 'brands_mega_dropdown.dart';
import 'hover_expandable_action.dart';

class WebHeader extends StatefulWidget {
  final VoidCallback? onSearchTap;
  final ScrollController? scrollController;

  const WebHeader({super.key, this.onSearchTap, this.scrollController});

  @override
  State<WebHeader> createState() => _WebHeaderState();
}

class _WebHeaderState extends State<WebHeader> {
  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _searchOverlayEntry;

  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _searchBarKey = GlobalKey();

  late SearchCubit _searchCubit;

  // GlobalKeys for dropdown anchoring (web empty-state popovers)
  final GlobalKey _locationBtnKey    = GlobalKey();
  final GlobalKey _wishlistBtnKey    = GlobalKey();
  final GlobalKey _notifBtnKey       = GlobalKey();
  final GlobalKey _cartBtnKey        = GlobalKey();

  // Category hover dropdown — using Overlay so it escapes scroll clips
  dynamic _hoveredCategory;
  Timer? _dismissTimer;
  OverlayEntry? _categoryOverlayEntry;
  LayerLink? _activeLink;

  // Brands mega dropdown
  bool _brandsHovered = false;
  Timer? _brandsDismissTimer;
  OverlayEntry? _brandsOverlayEntry;
  LayerLink? _brandsLink;

  @override
  void initState() {
    super.initState();
    _searchCubit = sl<SearchCubit>();

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        _showSearchDropdown();
      } else {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_searchFocusNode.hasFocus) {
            _hideSearchDropdown();
          }
        });
      }
    });

    _searchController.addListener(() {
      setState(() {});
      _searchCubit.search(_searchController.text);
      if (_searchFocusNode.hasFocus) {
        if (_searchController.text.trim().isNotEmpty) {
          _showSearchDropdown();
        } else {
          _checkHideSearchDropdown();
        }
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _categoryOverlayEntry?.remove();
    _categoryOverlayEntry = null;
    _brandsDismissTimer?.cancel();
    _brandsOverlayEntry?.remove();
    _brandsOverlayEntry = null;
    _searchOverlayEntry?.remove();
    _searchOverlayEntry = null;
    _searchFocusNode.dispose();
    _searchController.dispose();
    _searchCubit.close();
    super.dispose();
  }


  // ── Category Dropdown (Overlay) ────────────────────────────────────────────

  /// Schedule a delayed hide. If the mouse re-enters the chip or dropdown
  /// before the timer fires, call [_cancelHide] to keep it open.
  void _scheduleHide() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(milliseconds: 50), () {
      if (mounted) _hideCategoryDropdown();
    });
  }

  void _cancelHide() {
    _dismissTimer?.cancel();
  }

  /// Called when a category chip is hovered. If it's already the active
  /// category we just cancel any pending dismiss. Otherwise we swap the
  /// dropdown content in-place (no remove→insert cycle).
  void _setHovered(dynamic cat, LayerLink link) {
    _dismissTimer?.cancel();

    if (_hoveredCategory == cat && _categoryOverlayEntry != null) {
      // Already showing this category — nothing to do.
      return;
    }

    _hoveredCategory = cat;
    _activeLink = link;

    if (_categoryOverlayEntry != null) {
      // Overlay already open — just rebuild it with the new category.
      _categoryOverlayEntry!.markNeedsBuild();
    } else {
      _showCategoryDropdown();
    }

    if (mounted) setState(() {});
  }

  void _showCategoryDropdown() {
    if (_categoryOverlayEntry != null || _hoveredCategory == null) return;
    final overlay = Overlay.of(context);

    _categoryOverlayEntry = OverlayEntry(
      builder: (ctx) {
        // Read current values each time the entry rebuilds.
        final cat = _hoveredCategory;
        final link = _activeLink;
        if (cat == null || link == null) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isRtl = Localizations.localeOf(context).languageCode == 'ar';

        return Stack(
          children: [
            // Full-screen barrier: tap to close, hover does NOT auto-close
            // (avoids triggering dismiss while crossing the gap between
            // chip and dropdown).
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _dismissTimer?.cancel();
                  _hideCategoryDropdown();
                },
              ),
            ),
            // The dropdown panel, anchored to the active chip.
            CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              targetAnchor: isRtl ? Alignment.bottomRight : Alignment.bottomLeft,
              followerAnchor: isRtl ? Alignment.topRight : Alignment.topLeft,
              offset: const Offset(0, 0), // Changed from Offset(0, 8) to be connected
              child: MouseRegion(
                onEnter: (_) => _cancelHide(),
                onExit: (_) => _scheduleHide(),
                child: InTreeCategoryDropdown(
                  category: cat,
                  isDark: isDark,
                  onEnter: _cancelHide,
                  onExit: _scheduleHide,
                  onNavigate: (navCat) {
                    _dismissTimer?.cancel();
                    _hideCategoryDropdown();
                    AppNavigator.pushNamed(context, '${Routes.categoryProducts}/${SlugUtils.slugify(navCat.name, navCat.id)}', arguments: navCat);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_categoryOverlayEntry!);
  }

  void _hideCategoryDropdown() {
    _dismissTimer?.cancel();
    _categoryOverlayEntry?.remove();
    _categoryOverlayEntry = null;
    _activeLink = null;
    final wasHovered = _hoveredCategory;
    _hoveredCategory = null;
    if (mounted && wasHovered != null) setState(() {});
  }

  // ── Brands Mega Dropdown (Overlay) ──────────────────────────────────────────

  void _scheduleBrandsHide() {
    _brandsDismissTimer?.cancel();
    _brandsDismissTimer = Timer(const Duration(milliseconds: 50), () {
      if (mounted) _hideBrandsDropdown();
    });
  }

  void _cancelBrandsHide() {
    _brandsDismissTimer?.cancel();
  }

  void _onBrandsHover(LayerLink link) {
    _brandsDismissTimer?.cancel();
    _brandsLink = link;
    _brandsHovered = true;

    if (_brandsOverlayEntry != null) {
      _brandsOverlayEntry!.markNeedsBuild();
    } else {
      _showBrandsDropdown();
    }

    if (mounted) setState(() {});
  }

  void _showBrandsDropdown() {
    if (_brandsOverlayEntry != null) return;
    final overlay = Overlay.of(context);

    _brandsOverlayEntry = OverlayEntry(
      builder: (ctx) {
        final link = _brandsLink;
        if (link == null) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isRtl = Localizations.localeOf(context).languageCode == 'ar';
        final screenWidth = MediaQuery.sizeOf(context).width;
        final hPad = screenWidth < 800 ? screenWidth * 0.04 : screenWidth < 1600 ? 32.0 : screenWidth * 0.12;

        // Get brands from HomeCubit
        final homeState = context.read<HomeCubit>().state;
        final brands = homeState is HomeLoaded ? homeState.brands : <dynamic>[];

        return Stack(
          children: [
            // Full-screen barrier
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _brandsDismissTimer?.cancel();
                  _hideBrandsDropdown();
                },
              ),
            ),
            // The mega dropdown, anchored to the brands button
            CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              targetAnchor: isRtl ? Alignment.bottomRight : Alignment.bottomLeft,
              followerAnchor: isRtl ? Alignment.topRight : Alignment.topLeft,
              offset: Offset(isRtl ? 0 : -hPad + 40, 0), // Changed from 4 to 0 to be connected
              child: MouseRegion(
                onEnter: (_) => _cancelBrandsHide(),
                onExit: (_) => _scheduleBrandsHide(),
                child: BrandsMegaDropdown(
                  brands: brands,
                  isDark: isDark,
                  megaWidth: screenWidth - (hPad * 2),
                  onNavigate: (brand) {
                    _brandsDismissTimer?.cancel();
                    _hideBrandsDropdown();
                    if (brand == null) {
                      AppNavigator.pushNamed(context, Routes.products);
                      return;
                    }
                    AppNavigator.pushNamed(
                      context,
                      '${Routes.brand}/${brand.id}',
                      arguments: {
                        'brandName': brand.name,
                        'brandLogoUrl': brand.logoUrl,
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_brandsOverlayEntry!);
  }

  void _hideBrandsDropdown() {
    _brandsDismissTimer?.cancel();
    _brandsOverlayEntry?.remove();
    _brandsOverlayEntry = null;
    _brandsLink = null;
    _brandsHovered = false;
    if (mounted) setState(() {});
  }


  Future<void> _showSearchDropdown() async {
    if (_searchOverlayEntry != null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList('recent_searches') ?? [];
    
    if (recent.isEmpty && _searchController.text.trim().isEmpty) {
      return;
    }
    
    if (!mounted || _searchOverlayEntry != null || !_searchFocusNode.hasFocus) return;

    _searchOverlayEntry = _createSearchOverlayEntry();
    Overlay.of(context).insert(_searchOverlayEntry!);
  }

  Future<void> _checkHideSearchDropdown() async {
    if (_searchController.text.trim().isNotEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList('recent_searches') ?? [];
    if (recent.isEmpty && mounted) {
      _hideSearchDropdown();
    }
  }

  void _hideSearchDropdown() {
    _searchOverlayEntry?.remove();
    _searchOverlayEntry = null;
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> recent = prefs.getStringList('recent_searches') ?? [];
    if (!recent.contains(query.trim())) {
      recent.insert(0, query.trim());
      if (recent.length > 6) recent.removeLast();
      await prefs.setStringList('recent_searches', recent);
    }
  }

  OverlayEntry _createSearchOverlayEntry() {
    RenderBox renderBox = _searchBarKey.currentContext!.findRenderObject() as RenderBox;
    var size = renderBox.size;

    HomeCubit? homeCubit;
    try {
      homeCubit = context.read<HomeCubit>();
    } catch (_) {}

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _hideSearchDropdown,
            ),
          ),
          Positioned(
            left: 0,
            width: size.width,
            child: CompositedTransformFollower(
              link: _searchLayerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 4),
              child: Material(
                elevation: 16,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 500),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                  ),
                  child: MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: _searchCubit),
                      if (homeCubit != null) BlocProvider.value(value: homeCubit),
                    ],
                    child: SearchSheet(
                      isWebDropdown: true,
                      onSearchSelect: (query) {
                        _searchController.text = query;
                        _searchCubit.search(query);
                        _saveRecentSearch(query);
                        _hideSearchDropdown();
                        _searchFocusNode.unfocus();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userRepo = UserRepository();
    final isLoggedIn = userRepo.isLoggedIn;
    final userName = userRepo.currentUser?.name ?? '';

    final headerBgColor = isDark ? ColorsManager.surfaceDarkHeader : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobileWeb = constraints.maxWidth < 900;
        final hPad = isMobileWeb ? 16.0 : constraints.maxWidth < 1600 ? 32.0 : constraints.maxWidth * 0.12;

        // ── COMPACT MOBILE-WEB HEADER ─────────────────────────────────────
        if (isMobileWeb) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Top bar ──
              Container(
                height: 56,
                width: double.infinity,
                color: headerBgColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Logo
                      InkWell(
                        onTap: () {
                          try {
                            context.read<WebNavController>().navigateTo(0);
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          } catch (_) {
                            // Not inside a Dashboard — reset the singleton
                            // index so the new Dashboard opens on Home.
                            WebNavController.instance.navigateTo(0);
                            AppNavigator.pushNamedAndRemoveAll(context, Routes.dashBoard);
                          }
                        },
                        child: Image.asset(isDark ? Assets.logoHeader : Assets.logoApp, height: 44, fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 12),

                      // Location — compact version
                      Expanded(child: Align(alignment: Alignment.center, child: _buildLocationBtn(textColor, isDark))),

                      // Search Icon
                      InkWell(
                        onTap: () {
                          if (widget.onSearchTap != null) {
                            widget.onSearchTap!();
                          } else {
                            AppNavigator.pushNamed(context, Routes.search);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.search_rounded, color: textColor, size: 24),
                        ),
                      ),

                      // Cart icon with badge
                      BlocBuilder<CartCubit, CartState>(
                        builder: (context, state) {
                          int count = state is CartLoaded ? state.cart.items.length : 0;
                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => AppNavigator.pushNamed(context, Routes.cart),
                              child: Badge(
                                isLabelVisible: count > 0,
                                label: Padding(
                                  padding: const EdgeInsets.only(top: 1.0),
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1),
                                  ),
                                ),
                                backgroundColor: Colors.red,
                                alignment: Alignment.topRight,
                                offset: const Offset(-2, 2),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: SvgPicture.asset('assets/icons/cart-icons-nav.svg', width: 22, height: 22, colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn)),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Hamburger — opens the MobileWebDrawer in WebShell's endDrawer
                      Builder(
                        builder: (ctx) => MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Scaffold.of(ctx).openEndDrawer(),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(Icons.menu_rounded, color: textColor, size: 26),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        } // end isMobileWeb


        // ── FULL DESKTOP HEADER ───────────────────────────────────────────
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 1. Main Header ──
            Container(
              height: 72,
              width: double.infinity,
              decoration: BoxDecoration(
                color: headerBgColor,
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1)),
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Row(
              children: [
                // ── Logo ──
                InkWell(
                  onTap: () {
                    try {
                      context.read<WebNavController>().navigateTo(0);
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    } catch (_) {
                      // Not inside a Dashboard — reset the singleton
                      // index so the new Dashboard opens on Home.
                      WebNavController.instance.navigateTo(0);
                      AppNavigator.pushNamedAndRemoveAll(context, Routes.dashBoard);
                    }
                  },
                  child: Image.asset(isDark ? Assets.logoHeader : Assets.logoApp, height: 44, fit: BoxFit.contain),
                ),
                const SizedBox(width: 24),

                // ── Location ──
                _buildLocationBtn(textColor, isDark),
                const SizedBox(width: 24),

                // ── Search Bar ──
                Expanded(
                  child: CompositedTransformTarget(
                    link: _searchLayerLink,
                    child: Container(
                      key: _searchBarKey,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Icon(Icons.search_rounded, color: _searchFocusNode.hasFocus ? ColorsManager.primaryColor : Colors.grey.shade600, size: 20),
                          const SizedBox(width: 12),

                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onSubmitted: (val) {
                                if (val.trim().isNotEmpty) {
                                  _searchFocusNode.unfocus();
                                  _saveRecentSearch(val);
                                  AppNavigator.pushNamed(
                                    context,
                                    Routes.products,
                                    arguments: {
                                      'searchQuery': val.trim(),
                                    },
                                  );
                                }
                              },
                              cursorColor: ColorsManager.primaryColor,
                              decoration: InputDecoration(
                                hintText: 'home.searchHint'.tr(),
                                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                isDense: true,
                                filled: false,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                hoverColor: Colors.transparent,
                              ),
                              style: TextStyle(fontSize: 14, color: textColor),
                            ),
                          ),

                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.cancel_rounded, size: 18, color: Colors.grey.shade500),
                              onPressed: () {
                                _searchController.clear();
                                _searchCubit.search('');
                                _searchFocusNode.requestFocus();
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),

                // ── Favorites & Notifications & Cart & Account ──
                _buildActionItems(context, textColor, isLoggedIn, userName, isDark),


              ],
            ),
          ),
        ),
      ),

            // ── 2. Sub Header — each category chip has its own LayerLink (no wrapper needed here)
            _buildSubHeader(isDark, borderColor, hPad),
          ],
        );
      },
    );
  }

  Widget _buildSubHeader(bool isDark, Color borderColor, double hPad) {
    final subBgColor = isDark ? const Color(0xFF222222) : const Color(0xFFFAFAFA);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 44), // bounded so children can use alignment
      decoration: BoxDecoration(
        color: subBgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: BlocBuilder<HomeCubit, HomeState>(
        buildWhen: (p, n) => (p is HomeLoaded ? p.categories : null) != (n is HomeLoaded ? n.categories : null),
        builder: (context, state) {
          final categories = state is HomeLoaded ? state.categories : <dynamic>[];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── "All Categories" button — always first ──
                SubHeaderCategoriesBtn(
                  isDark: isDark,
                  isActive: _hoveredCategory == 'all',
                  onHover: (link) => _setHovered('all', link),
                  onLeave: _scheduleHide,
                ),

                // ── "Brands" button ──
                SubHeaderBrandsBtn(
                  isDark: isDark,
                  isActive: _brandsHovered,
                  onHover: (link) => _onBrandsHover(link),
                  onLeave: _scheduleBrandsHide,
                ),

                // Thin divider
                Container(
                  width: 1, height: 18,
                  color: borderColor,
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                ),

                // ── Category chips ──
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        ui.PointerDeviceKind.touch,
                        ui.PointerDeviceKind.mouse,
                      },
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ...categories.asMap().entries.map((e) {
                            return SubHeaderCategoryItem(
                              category: e.value,
                              isDark: isDark,
                              animDelay: Duration(milliseconds: 60 + (e.key * 30)),
                              isActive: _hoveredCategory == e.value,
                              onHover: _setHovered,
                              onLeave: _scheduleHide,
                            );
                          }),
                          const SizedBox(width: 8),
                          _AllProductsMenuLink(isDark: isDark),
                        ],
                      ),
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


  Widget _buildLocationBtn(Color textColor, bool isDark) => BlocBuilder<DeliveryLocationCubit, DeliveryLocationState>(
    builder: (context, state) {
      String displayLabel = 'address.map.locating'.tr();
      bool isLoading = state is DeliveryLocationLoading || state is DeliveryLocationInitial;

      if (state is DeliveryLocationResolved) {
        String key = state.displayLabel.toLowerCase();
        String translated = 'home.locations.$key'.tr();
        displayLabel = translated.contains('home.locations') ? state.displayLabel : translated;
      } else if (state is DeliveryLocationDenied) {
        displayLabel = 'home.header.not_set'.tr();
      }

      return InkWell(
        key: _locationBtnKey,
        onTap: () {
          LocationPickerSheet.showDropdown(context, _locationBtnKey);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Location SVG icon
            if (isLoading)
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: textColor),
              )
            else
              CustomIcon(assetPath: Assets.locationIcon, size: 22, color: textColor),
            const SizedBox(width: 5),
            // City name
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'home.deliver_to'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor.withValues(alpha: 0.7),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Arrow
            Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: textColor),
          ],
        ),
      );
    },
  );


  // 🌟 هنا تم تفعيل الأنيميشن Hover 🌟
  Widget _buildActionItems(BuildContext context, Color textColor, bool isLoggedIn, String userName, bool isDark) {
    final headerBgColor = isDark ? ColorsManager.surfaceDarkHeader : Colors.white;
    return Row(
      children: [
        // Favorites — with live count badge
        BlocBuilder<WishlistCubit, WishlistState>(
          builder: (context, wishState) {
            final wishCount = wishState is WishlistLoaded
                ? wishState.wishlist.count
                : 0;
            return KeyedSubtree(
              key: _wishlistBtnKey,
              child: HoverExpandableAction(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    child: FaIcon(
                      wishCount > 0 ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                      size: 18,
                      color: wishCount > 0 ? Colors.red[400] : textColor,
                    ),
                  ),
                  if (wishCount > 0)
                    Positioned(
                      bottom: -1,
                      right: -1,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        padding: const EdgeInsets.all(3),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 1.0),
                          child: Text(
                            wishCount > 9 ? '+9' : '$wishCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: 'profile.favorites'.tr(),
              textColor: textColor,
              isDark: isDark,
              onTap: () {
                final isLoggedIn = context.read<UserCubit>().isLoggedIn;
                final hasItems = wishCount > 0;
                if (!isLoggedIn) {
                  EmptyModal.showDropdown(
                    context,
                    anchorKey: _wishlistBtnKey,
                    icon: Icons.favorite_border_rounded,
                    iconColor: Colors.red,
                    titleKey: 'wishlist.login_required_title',
                    subtitleKey: 'wishlist.login_required_subtitle',
                    actionLabelKey: 'auth.login',
                    onAction: () => AppNavigator.pushNamed(context, Routes.login),
                  );
                } else if (!hasItems) {
                  EmptyModal.showDropdown(
                    context,
                    anchorKey: _wishlistBtnKey,
                    icon: Icons.favorite_border_rounded,
                    iconColor: Colors.red,
                    titleKey: 'wishlist.empty_title',
                    subtitleKey: 'wishlist.empty_subtitle',
                    actionLabelKey: 'wishlist.start_shopping',
                    onAction: () =>
                        AppNavigator.pushNamedAndRemoveAll(context, Routes.dashBoard),
                  );
                } else {
                  AppNavigator.pushNamed(context, Routes.wishlist);
                }
              },
            ),
            );
          },
        ),
        const SizedBox(width: 4),

        // Notifications
        BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            final unreadCount = state is NotificationsLoaded ? state.unreadCount : 0;
            return KeyedSubtree(
              key: _notifBtnKey,
              child: HoverExpandableAction(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    child: SvgPicture.asset(
                      Assets.navNotificationIcon,
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        padding: const EdgeInsets.all(3),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 1.0),
                          child: Text(
                            unreadCount > 9 ? '+9' : unreadCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: 'profile.notifications'.tr(),
              textColor: textColor,
              isDark: isDark,
              onTap: () {
                // Client request: show the latest notifications inline in an
                // anchored dropdown (scrollable list) instead of navigating to a
                // separate page. The dropdown refreshes on open, handles its own
                // loading/empty states, and has a "view all" footer to the screen.
                NotificationsDropdown.show(
                  context,
                  anchorKey: _notifBtnKey,
                  cubit: context.read<NotificationsCubit>(),
                );
              },
            ),
            );
          },
        ),
        const SizedBox(width: 4),

        // Cart
        BlocBuilder<CartCubit, CartState>(
          builder: (context, state) {
            int itemCount = state is CartLoaded ? state.cart.items.length : 0;
            return KeyedSubtree(
              key: _cartBtnKey,
              child: HoverExpandableAction(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    child: SvgPicture.asset('assets/icons/cart_new.svg', width: 22, height: 22, colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn)),
                  ),
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        padding: const EdgeInsets.all(3),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 1.0),
                          child: Text(
                            itemCount > 9 ? '+9' : itemCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: 'cart.title'.tr(),
              textColor: textColor,
              isDark: isDark,
              onTap: () {
                final cartState = context.read<CartCubit>().state;
                final isEmpty = cartState is! CartLoaded ||
                    cartState.cart.items.isEmpty;
                if (isEmpty) {
                  EmptyModal.showDropdown(
                    context,
                    anchorKey: _cartBtnKey,
                    icon: Icons.shopping_cart_outlined,
                    titleKey: 'cart.empty_title',
                    subtitleKey: 'cart.empty_subtitle',
                    actionLabelKey: 'cart.start_shopping',
                    onAction: () =>
                        AppNavigator.pushNamedAndRemoveAll(context, Routes.dashBoard),
                  );
                } else {
                  AppNavigator.pushNamed(context, Routes.cart);
                }
              },
            ),
            );
          },
        ),
        const SizedBox(width: 8),

        // Language Toggle
        BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settings) {
            final isAr = settings.locale.languageCode == 'ar';
            return HoverExpandableAction(
              icon: Container(
                padding: const EdgeInsets.all(4),
                child: SvgPicture.asset(
                  'assets/icons/lang_new.svg',
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
                ),
              ),
              label: isAr ? 'English' : 'العربية',
              textColor: textColor,
              isDark: isDark,
              onTap: () async {
                final next = isAr ? 'en' : 'ar';
                await context.setLocale(Locale(next));
                if (!context.mounted) return;
                await context.read<SettingsCubit>().setLanguage(next);
                await Future.delayed(const Duration(milliseconds: 150));
                reloadApp();
              },
            );
          },
        ),
        const SizedBox(width: 8),

        // Account
        AccountDropdown(
          isLoggedIn: isLoggedIn,
          userName: userName,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _AllProductsMenuLink extends StatefulWidget {
  final bool isDark;
  const _AllProductsMenuLink({required this.isDark});

  @override
  State<_AllProductsMenuLink> createState() => _AllProductsMenuLinkState();
}

class _AllProductsMenuLinkState extends State<_AllProductsMenuLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final primary = ColorsManager.primaryColor;
    final color = _hovered ? primary : (widget.isDark ? Colors.white70 : Colors.black87);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => AppNavigator.pushNamed(context, Routes.products),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: AppTextTheme.fontFamily,
            ),
            child: Text('home.allProducts'.tr()),
          ),
        ),
      ),
    );
  }
}
