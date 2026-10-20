// lib/features/home/presentation/widget/categories_row.dart
// Circular category slider — Instagram Stories style
import 'package:fastway/core/theme/colors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
      height: 125,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    final name = locale == 'ar' ? category.nameAr : category.name;
    const circleSize = 80.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 86,
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
    final assetIndex = (index % 3) + 1;
    return Image.asset(
      'assets/images/category_$assetIndex.jpeg',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
