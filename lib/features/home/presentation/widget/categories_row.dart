// lib/features/home/presentation/widget/categories_row.dart
// Circular category slider — Instagram Stories style
import 'package:fastway/core/api/model/endpoints.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/category_entity.dart';

class CategoriesRow extends StatelessWidget {
  final List<CategoryEntity> categories;
  final void Function(CategoryEntity)? onTap;
  final int? selectedIndex;

  const CategoriesRow({
    super.key,
    required this.categories,
    this.onTap,
    this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    // One unified design for all screen sizes — circular image slider
    return SizedBox(
      height: 105,
      // Opt the mouse back in as a drag device: AppScrollBehavior excludes it
      // app-wide so that click-dragging selects text instead of scrolling.
      // A carousel has no selectable text and users expect to drag it.
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          physics: const BouncingScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (_, i) => _CategoryCircle(
            category: categories[i],
            isSelected: selectedIndex == i,
            index: i,
            onTap: onTap != null ? () => onTap!(categories[i]) : null,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CategoryCircle extends StatelessWidget {
  final CategoryEntity category;
  final bool isSelected;
  final int index;
  final VoidCallback? onTap;

  const _CategoryCircle({
    required this.category,
    required this.isSelected,
    required this.index,
    this.onTap,
  });

  Color get _accent {
    try {
      final hex = category.color?.replaceAll('#', '') ?? '10B981';
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return ColorsManager.primaryColor;
    }
  }

  String get _fullImageUrl {
    final rawUrl = category.iconUrl.trim();
    if (rawUrl.isEmpty) return '';
    if (rawUrl.startsWith('http')) return rawUrl;
    final baseDomain = Endpoints.baseUrl.replaceAll(RegExp(r'/api/v1$'), '');
    return '$baseDomain/storage/categories/$rawUrl.png';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    final name = locale == 'ar' ? category.nameAr : category.name;
    const circleSize = 66.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AnimatedContainer removed — size+BoxShadow change on selection
            // forces GPU repaint of all categories simultaneously.
            Container(
              width: isSelected ? circleSize + 4 : circleSize,
              height: isSelected ? circleSize + 4 : circleSize,
              padding: isSelected ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? LinearGradient(
                        colors: [_accent, _accent.withValues(alpha: 0.5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: isSelected
                    ? null
                    : Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.shade200,
                        width: 1.5,
                      ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  // BoxShadow removed — changes between selected/unselected
                  // causing GPU repaint across all category items.
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildImage(isDark),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? _accent
                    : (isDark ? Colors.white70 : const Color(0xFF4A4A4A)),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    )
        ;
  }

  Widget _buildImage(bool isDark) {
    final imageUrl = _fullImageUrl;

    if (imageUrl.isNotEmpty && !imageUrl.startsWith('assets/')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        memCacheWidth: 132,  // 66px circle * 2x retina
        memCacheHeight: 132,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, __) => Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _accent.withValues(alpha: 0.5),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => _FallbackIcon(accent: _accent, isDark: isDark, name: category.name),
      );
    }

    final url = category.iconUrl.trim();
    if (url.startsWith('assets/') && url.endsWith('.svg')) {
      return Center(
        child: SvgPicture.asset(
          url,
          width: 30,
          height: 30,
          colorFilter: ColorFilter.mode(_accent, BlendMode.srcIn),
        ),
      );
    }

    return _FallbackIcon(accent: _accent, isDark: isDark, name: category.name);
  }
}

class _FallbackIcon extends StatelessWidget {
  final Color accent;
  final bool isDark;
  final String name;

  const _FallbackIcon({required this.accent, required this.isDark, required this.name});

  @override
  Widget build(BuildContext context) {
    const iconMap = {
      'protein': Icons.fitness_center_rounded,
      'creatine': Icons.bolt_rounded,
      'vitamin': Icons.medication_rounded,
      'bcaa': Icons.science_rounded,
      'pre-workout': Icons.local_fire_department_rounded,
      'fat': Icons.monitor_weight_rounded,
      'mass': Icons.sports_gymnastics_rounded,
      'omega': Icons.water_drop_rounded,
      'collagen': Icons.face_retouching_natural_rounded,
      'amino': Icons.biotech_rounded,
    };

    final lower = name.toLowerCase();
    final iconData = iconMap.entries
        .firstWhere((e) => lower.contains(e.key),
            orElse: () => const MapEntry('', Icons.category_rounded))
        .value;

    return Container(
      color: accent.withValues(alpha: 0.08),
      child: Center(child: Icon(iconData, size: 26, color: accent)),
    );
  }
}