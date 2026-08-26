// lib/features/home/presentation/widget/categories_grid.dart
import 'package:fastway/core/api/model/endpoints.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/category_entity.dart';

class CategoriesGrid extends StatelessWidget {
  final List<CategoryEntity> categories;
  final void Function(CategoryEntity)? onTap;

  const CategoriesGrid({
    super.key,
    required this.categories,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 260.h,
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
        child: GridView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 0,
            crossAxisSpacing: 16.h,
            mainAxisExtent: (MediaQuery.sizeOf(context).width - 32.w) / 3.5,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return _CategoryGridItem(
              category: cat,
              onTap: onTap != null ? () => onTap!(cat) : null,
            );
          },
        ),
      ),
    );
  }
}

class _CategoryGridItem extends StatelessWidget {
  final CategoryEntity category;
  final VoidCallback? onTap;

  const _CategoryGridItem({
    required this.category,
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
    final rawUrl = (category.image?.isNotEmpty == true ? category.image! : category.iconUrl).trim();
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
    final circleSize = 88.r;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF0F0F0),
                width: 1,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildImage(isDark),
          ),
          SizedBox(height: 8.h),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : const Color(0xFF1B0B3B),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(bool isDark) {
    final imageUrl = _fullImageUrl;

    if (imageUrl.isNotEmpty && !imageUrl.startsWith('assets/')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        memCacheWidth: 150,
        memCacheHeight: 150,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, __) => Center(
          child: SizedBox(
            width: 20.r,
            height: 20.r,
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
          width: 30.r,
          height: 30.r,
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
      child: Center(child: Icon(iconData, size: 26.r, color: accent)),
    );
  }
}
