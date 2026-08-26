import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/widgets/safe_mouse_region.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/api/model/endpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/skeletons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:fastway/core/utils/slug_utils.dart';
import '../../../../core/routes/routes.dart';
import '../../../../features/home/domain/entities/category_entity.dart';
import '../../../../features/home/presentation/cubit/home_cubit.dart';
import '../../../../features/home/presentation/cubit/home_state.dart';

/// Desktop category navigation panel.
class WebCategoryDrawer {
  static void show(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final homeCubit = context.read<HomeCubit>();

    if (isWide) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.4),
        builder: (_) => BlocProvider.value(
          value: homeCubit,
          child: const _CategoryDialog(),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BlocProvider.value(
          value: homeCubit,
          child: const _WebCategoryDrawerContent(),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DESKTOP DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryDialog extends StatelessWidget {
  const _CategoryDialog();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 80),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840, maxHeight: 580), // كبرنا الارتفاع سنة عشان الـ Grid
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
          child: Container(
            color: isDark ? ColorsManager.surfaceDarkCard : const Color(0xFFF8F9FA),
            child: Column(
              children: [
                // ── Header ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 20, 16),
                  child: Row(
                    children: [
                      Text(
                        'dashboard.categories'.tr(),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.grey[400] : const Color(0xFF6B6B6B),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),

                // ── Grid ────────────────────────────────────
                Expanded(child: _CategoriesGrid()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOBILE BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _WebCategoryDrawerContent extends StatelessWidget {
  const _WebCategoryDrawerContent();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.65,
      decoration: BoxDecoration(
        color: isDark ? ColorsManager.surfaceDarkCard : const Color(0xFFF8F9FA),
        borderRadius: const BorderRadius.vertical(top: Radius.zero),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD4CFC8),
              borderRadius: BorderRadius.zero,
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 20, 12),
            child: Row(
              children: [
                Text(
                  'dashboard.categories'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark ? Colors.grey[400] : const Color(0xFF6B6B6B),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),

          // Grid
          Expanded(child: _CategoriesGrid()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED CATEGORIES GRID
// ─────────────────────────────────────────────────────────────────────────────

class _CategoriesGrid extends StatelessWidget {
  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return ColorsManager.primaryColor;
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return ColorsManager.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final homeCubit = context.read<HomeCubit>();

    return BlocProvider.value(
        value: homeCubit,
        child: BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoaded) {
          final categories = state.categories;
          return GridView.builder(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 4 : 3,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.95, // عدلناها عشان تدي مساحة طولية مريحة للكارت
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final locale = Localizations.localeOf(context).languageCode;
              final name = locale == 'ar' ? cat.nameAr : cat.name;
              final accent = _parseColor(cat.color);

              return _CategoryTile(
                category: cat, // 👈 باصينا الأوبجيكت كله هنا
                name: name,
                accent: accent,
                isDark: isDark,
                index: index,
                onTap: () {
                  Navigator.pop(context);
                  AppNavigator.pushNamed(
                    context,
                    '${Routes.categoryProducts}/${SlugUtils.slugify(cat.name, cat.id)}',
                    arguments: cat,
                  );
                },
              );
            },
          );
        }

        if (state is HomeLoading) {
          return const _CategoryDrawerSkeleton();
        }

        return const _CategoryDrawerSkeleton();
      },
    ) );
  }
}

class _CategoryDrawerSkeleton extends StatelessWidget {
  const _CategoryDrawerSkeleton();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    return BaseShimmer(
      child: GridView.builder(
        padding: const EdgeInsets.all(24),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isWide ? 4 : 3,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 0.95,
        ),
        itemCount: isWide ? 8 : 6,
        itemBuilder: (_, __) => const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShimmerBox(width: 60, height: 60, radius: 18),
            SizedBox(height: 14),
            ShimmerLine(width: 80, height: 12),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY TILE  (UI Enhanced with dynamic icons and squircles)
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryTile extends StatefulWidget {
  final CategoryEntity category;
  final String name;
  final Color accent;
  final bool isDark;
  final int index;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.name,
    required this.accent,
    required this.isDark,
    required this.index,
    required this.onTap,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  String get _fullImageUrl {
    final rawUrl = widget.category.iconUrl.trim();
    if (rawUrl.isEmpty) return '';
    if (rawUrl.startsWith('http')) return rawUrl;

    final baseDomain = Endpoints.baseUrl.replaceAll(RegExp(r'/api/v1$'), '');
    return '$baseDomain/storage/categories/$rawUrl.png';
  }

  @override
  Widget build(BuildContext context) {
    return SafeMouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          decoration: BoxDecoration(
            color: widget.isDark
                ? (_isHovered ? const Color(0xFF2A2A2C) : const Color(0xFF222224))
                : (_isHovered ? Colors.white : Colors.white),
            borderRadius: BorderRadius.zero, // حواف الكارت
            border: Border.all(
              color: widget.isDark
                  ? (_isHovered ? widget.accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05))
                  : (_isHovered ? widget.accent.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.04)),
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Icon Container (Squircle) ──
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.zero, // Squircle
                  boxShadow: const [],
                ),
                child: Center(
                  child: _buildIcon(32, widget.isDark),
                ),
              ),
              const SizedBox(height: 14),

              // ── Category Name ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: _isHovered ? FontWeight.w700 : FontWeight.w600,
                    color: _isHovered ? widget.accent : (widget.isDark ? Colors.white : const Color(0xFF1A1A1A)),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        )
      ),
    );
  }

  Widget _buildIcon(double sz, bool isDark) {
    final imageUrl = _fullImageUrl;
    final color = widget.accent;

    if (imageUrl.isNotEmpty && !imageUrl.startsWith('assets/')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: sz,
        height: sz,
        memCacheWidth: (sz * 2).toInt(),
        memCacheHeight: (sz * 2).toInt(),
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        fit: BoxFit.contain,
        color: color,
        colorBlendMode: BlendMode.srcIn,
        placeholder: (context, url) => SizedBox(
          width: sz * 0.5,
          height: sz * 0.5,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _isHovered ? Colors.white54 : widget.accent.withValues(alpha: 0.5),
          ),
        ),
        errorWidget: (context, url, error) {
          return Icon(Icons.category_rounded, size: sz, color: color);
        },
      );
    }

    final url = widget.category.iconUrl.trim();
    if (url.startsWith('assets/') && url.endsWith('.svg')) {
      return SvgPicture.asset(
          url,
          width: sz,
          height: sz,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn)
      );
    }

    const iconMap = {
      'electronics': Icons.electrical_services_rounded,
      'clothing': Icons.checkroom_rounded,
      'sports': Icons.sports_basketball_rounded,
      'home': Icons.home_rounded,
      'books': Icons.menu_book_rounded,
      'beauty': Icons.face_retouching_natural_rounded,
      'vitamins': Icons.medication_rounded,
      'supplements': Icons.health_and_safety_rounded,
      'fitness': Icons.fitness_center_rounded,
      'nutrition': Icons.restaurant_rounded,
    };

    final iconData = iconMap.entries
        .firstWhere(
            (e) => widget.name.toLowerCase().contains(e.key),
        orElse: () => const MapEntry('', Icons.category_rounded)
    )
        .value;

    return Icon(iconData, size: sz, color: color);
  }
}