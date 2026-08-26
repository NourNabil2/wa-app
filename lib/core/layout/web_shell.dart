import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fastway/core/responsive/responsive_layout.dart';
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/utils/slug_utils.dart';
import 'package:fastway/features/announcements/presentation/widgets/announcements_banner.dart';
import 'package:fastway/features/home/presentation/cubit/home_cubit.dart';
import 'package:fastway/features/home/presentation/cubit/home_state.dart';
import 'package:fastway/features/home/domain/entities/category_entity.dart';
import 'package:fastway/features/home/presentation/widget/mobile_web_drawer.dart';
import 'web_header.dart';
import 'package:fastway/core/widgets/safe_mouse_region.dart';

class WebShell extends StatefulWidget {
  final Widget content;
  final int selectedNavIndex;
  final bool showSidebar;
  final ScrollController? scrollController;
  final ValueChanged<int>? onNavItemSelected;
  final VoidCallback? onSearchTap;
  final bool hasHeroSlider;

  const WebShell({
    super.key,
    required this.content,
    required this.selectedNavIndex,
    this.showSidebar = true,
    this.scrollController,
    this.onNavItemSelected,
    this.onSearchTap,
    this.hasHeroSlider = false,
  });

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  late final ScrollController _scrollController;
  bool _showScrollToTop = false;
  ScrollPosition? _lastScrollPosition;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final offset = notification.metrics.pixels;
      final show = offset > 400;
      if (show != _showScrollToTop) {
        setState(() => _showScrollToTop = show);
      }
      // Only capture if it's actually a ScrollPosition (not PageMetrics etc.)
      if (notification.metrics is ScrollPosition) {
        _lastScrollPosition = notification.metrics as ScrollPosition;
      }
    }
    return false; // don't absorb
  }

  void _scrollToTop() {
    const duration = Duration(milliseconds: 600);
    const curve = Curves.easeOutCubic;
    // Animate every attached position (covers PrimaryScrollController clients)
    if (_scrollController.hasClients) {
      for (final pos in _scrollController.positions) {
        pos.animateTo(0, duration: duration, curve: curve);
      }
      return;
    }
    // Fallback: use the last ScrollPosition captured from notifications
    if (_lastScrollPosition != null && _lastScrollPosition!.hasPixels) {
      _lastScrollPosition!.animateTo(0, duration: duration, curve: curve);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobileWeb = isMobileLayout(context) || MediaQuery.sizeOf(context).width < 900;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F6FA),
      // Hamburger drawer — only wired up on narrow mobile-web viewports
      endDrawer: isMobileWeb ? const MobileWebDrawer() : null,
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              backgroundColor: isDark ? Colors.white24 : const Color(0xFF222222),
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

          // ── 1. Header (responsive: compact on mobile, full on desktop) ──
          WebHeader(onSearchTap: widget.onSearchTap),

          // ── 2. Mobile-web category sub-bar ─────────────────────────────
          if (isMobileWeb) const MobileWebCategoryBar(),

          // ── 3. Content ───────────────────────────────────────────────────
          Expanded(
            child: PrimaryScrollController(
              controller: _scrollController,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
                child: widget.content,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOBILE WEB CATEGORY BAR
// • "Categories" button → opens a left-side accordion panel as an OverlayEntry
// • Rest of bar: plain text names separated by | pipes — no chip backgrounds
// ─────────────────────────────────────────────────────────────────────────────

class MobileWebCategoryBar extends StatelessWidget {
  const MobileWebCategoryBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg  = isDark ? ColorsManager.surfaceDarkCard : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: barBg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // ── "Categories" button ─────────────────────────────────────────
          GestureDetector(
            onTap: () => _CategorySidePanel.show(context),
            child: Container(
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: barBg,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.menu_rounded, color: isDark ? Colors.white : Colors.black, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'dashboard.categories'.tr(),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Quick-access category names as pipe-separated plain links ───
          Expanded(
            child: BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                final categories = state is HomeLoaded
                    ? state.categories
                    : <CategoryEntity>[];

                if (categories.isEmpty) return const SizedBox.shrink();

                return ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      ui.PointerDeviceKind.touch,
                      ui.PointerDeviceKind.mouse,
                    },
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: categories.length * 2 - 1,
                  itemBuilder: (context, i) {
                    // odd indices → pipe separator
                    if (i.isOdd) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Center(
                          child: Text(
                            '|',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white24 : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      );
                    }
                    final cat = categories[i ~/ 2];
                    return _CategoryPipeLink(category: cat, isDark: isDark);
                  },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pipe-style plain text link (no background chip) ──────────────────────────
class _CategoryPipeLink extends StatefulWidget {
  final CategoryEntity category;
  final bool isDark;
  const _CategoryPipeLink({required this.category, required this.isDark});

  @override
  State<_CategoryPipeLink> createState() => _CategoryPipeLinkState();
}

class _CategoryPipeLinkState extends State<_CategoryPipeLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final name = widget.category.localizedName(isAr ? 'ar' : 'en');

    return SafeMouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _hovered = true);
      }),
      onExit: (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _hovered = false);
      }),
      child: GestureDetector(
        onTap: () {
          // Always navigate directly to the category page
          AppNavigator.pushNamed(
            context,
            '${Routes.categoryProducts}/${SlugUtils.slugify(widget.category.name, widget.category.id)}',
            arguments: widget.category,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Center(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _hovered
                    ? ColorsManager.primaryColor
                    : (widget.isDark ? Colors.white70 : const Color(0xFF333333)),
                decoration: _hovered ? TextDecoration.underline : TextDecoration.none,
                decorationColor: ColorsManager.primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY SIDE PANEL — accordion overlay from the left
// ─────────────────────────────────────────────────────────────────────────────

class _CategorySidePanel {
  static OverlayEntry? _entry;

  static void show(BuildContext context) {
    _dismiss();
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (_) => _CategorySidePanelWidget(
        onDismiss: _dismiss,
        homeCubit: context.read<HomeCubit>(),
      ),
    );
    overlay.insert(_entry!);
  }

  static void _dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

class _CategorySidePanelWidget extends StatefulWidget {
  final VoidCallback onDismiss;
  final HomeCubit homeCubit;
  const _CategorySidePanelWidget({required this.onDismiss, required this.homeCubit});

  @override
  State<_CategorySidePanelWidget> createState() => _CategorySidePanelWidgetState();
}

class _CategorySidePanelWidgetState extends State<_CategorySidePanelWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
      ..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _anim.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr   = context.locale.languageCode == 'ar';
    final bg     = isDark ? ColorsManager.surfaceDarkCard : Colors.white;
    final state  = widget.homeCubit.state;
    final cats   = state is HomeLoaded ? state.categories : <CategoryEntity>[];

    return Stack(
      children: [
        // ── Tap-outside to dismiss ─────────────────────────────────────
        GestureDetector(
          onTap: _close,
          child: Container(color: Colors.black.withValues(alpha: 0.35)),
        ),

        // ── Side panel ────────────────────────────────────────────────
        AnimatedBuilder(
          animation: _anim,
          builder: (_, child) {
            final dx = (isAr ? 1 : -1) * (1 - _anim.value) * 280;
            return Positioned(
              left: isAr ? null : 0.0,
              right: isAr ? 0.0 : null,
              top: 0,
              bottom: 0,
              child: Transform.translate(
                offset: Offset(dx, 0),
                child: child,
              ),
            );
          },
          child: SizedBox(
            width: 280,
            child: Material(
              color: bg,
              child: Column(
                children: [
                  // Header
                  Container(
                    height: 52,
                    color: ColorsManager.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.grid_view_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'dashboard.categories'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                          onPressed: _close,
                        ),
                      ],
                    ),
                  ),

                  // Category list
                  Expanded(
                    child: ListView.builder(
                      itemCount: cats.length,
                      itemBuilder: (_, i) {
                        final cat = cats[i];
                        final name = cat.localizedName(isAr ? 'ar' : 'en');
                        final hasChildren = cat.hasChildren || cat.children.isNotEmpty;
                        final isExpanded = _expanded.contains(cat.id);

                        return Column(
                          children: [
                            // Parent row
                            GestureDetector(
                              onTap: () {
                                if (hasChildren) {
                                  setState(() {
                                    if (isExpanded) {
                                      _expanded.remove(cat.id);
                                    } else {
                                      _expanded.add(cat.id);
                                    }
                                  });
                                } else {
                                  _close();
                                  AppNavigator.pushNamed(
                                    context,
                                    '${Routes.categoryProducts}/${SlugUtils.slugify(cat.name, cat.id)}',
                                    arguments: cat,
                                  );
                                }
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                                        ),
                                      ),
                                    ),
                                    if (hasChildren)
                                      Icon(
                                        isExpanded
                                            ? Icons.keyboard_arrow_up_rounded
                                            : Icons.keyboard_arrow_down_rounded,
                                        size: 18,
                                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            // Sub-categories (expanded inline)
                            if (isExpanded && cat.children.isNotEmpty)
                              ...cat.children.map((sub) {
                                final subName = sub.localizedName(isAr ? 'ar' : 'en');
                                return GestureDetector(
                                  onTap: () {
                                    _close();
                                    AppNavigator.pushNamed(
                                      context,
                                      '${Routes.categoryProducts}/${SlugUtils.slugify(sub.name, sub.id)}',
                                      arguments: sub,
                                    );
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 52, right: 16, top: 10, bottom: 10),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4, height: 4,
                                          decoration: const BoxDecoration(
                                            color: ColorsManager.primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            subName,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? Colors.grey.shade300 : const Color(0xFF444444),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),

                            Divider(
                              height: 1,
                              color: isDark ? Colors.white10 : Colors.grey.shade100,
                              indent: 16,
                              endIndent: 16,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Individual category chip (used for sub-category bottom sheet only) ─────────
// ── Top-level helper for sub-category bottom-sheet ───────────────────────────
void _showCategorySubSheet(BuildContext context, CategoryEntity parent, bool isDark) {
  final isAr = context.locale.languageCode == 'ar';
  final parentName = parent.localizedName(isAr ? 'ar' : 'en');

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        decoration: BoxDecoration(
          color: isDark ? ColorsManager.surfaceDarkCard : const Color(0xFFF8F9FA),
          borderRadius: const BorderRadius.vertical(top: Radius.zero),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD4CFC8),
                borderRadius: BorderRadius.zero,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
              child: Row(
                children: [
                  Text(
                    parentName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: isDark ? Colors.grey[400] : Colors.grey[600], size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
            Flexible(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1,
                ),
                itemCount: parent.children.isEmpty ? 1 : parent.children.length,
                itemBuilder: (ctx, i) {
                  if (parent.children.isEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pop(context);
                      AppNavigator.pushNamed(
                        context,
                        '${Routes.subCategories}/${parent.id}/sub',
                        arguments: parent,
                      );
                    });
                    return const SizedBox.shrink();
                  }
                  final sub = parent.children[i];
                  final subName = sub.localizedName(isAr ? 'ar' : 'en');
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      AppNavigator.pushNamed(
                        context,
                        '${Routes.categoryProducts}/${SlugUtils.slugify(sub.name, sub.id)}',
                        arguments: sub,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (sub.iconUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.zero,
                              child: CachedNetworkImage(imageUrl: sub.iconUrl,
                                height: 38, width: 38, fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.category_outlined, size: 30,
                                  color: ColorsManager.primaryColor,
                                ),
                              ),
                            )
                          else
                            const Icon(Icons.category_outlined, size: 30,
                                color: ColorsManager.primaryColor),
                          const SizedBox(height: 6),
                          Text(
                            subName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _CategoryChip extends StatelessWidget {
  final CategoryEntity category;
  final bool isDark;
  const _CategoryChip({required this.category, required this.isDark});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

