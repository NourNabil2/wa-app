import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/theme/text_theme.dart';
import 'package:fastway/core/utils/slug_utils.dart';
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:fastway/core/routes/routes.dart';

/// Custom painter that draws a tab shape: rounded top corners, flat bottom,
/// with borders on top/left/right only (no bottom border).
/// This avoids the Flutter Web CanvasKit bug where BoxDecoration with
/// borderRadius + non-uniform Border hides child Text widgets.
class _TabPainter extends CustomPainter {
  final Color bgColor;
  final Color borderColor;
  final double radius;

  _TabPainter({
    required this.bgColor,
    required this.borderColor,
    this.radius = 10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
    );

    // Fill background
    canvas.drawRRect(rrect, Paint()..color = bgColor);

    // Draw border on top, left, right only (skip bottom)
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()
      ..moveTo(0, size.height) // bottom-left
      ..lineTo(0, radius) // left side up
      ..arcToPoint(Offset(radius, 0), radius: Radius.circular(radius)) // top-left corner
      ..lineTo(size.width - radius, 0) // top side
      ..arcToPoint(Offset(size.width, radius), radius: Radius.circular(radius)) // top-right corner
      ..lineTo(size.width, size.height); // right side down

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(_TabPainter oldDelegate) =>
      bgColor != oldDelegate.bgColor || borderColor != oldDelegate.borderColor;
}

class SubHeaderCategoriesBtn extends StatefulWidget {
  final bool isDark;
  final bool isActive;
  final void Function(LayerLink) onHover;
  final VoidCallback onLeave;

  const SubHeaderCategoriesBtn({
    super.key,
    required this.isDark,
    required this.isActive,
    required this.onHover,
    required this.onLeave,
  });

  @override
  State<SubHeaderCategoriesBtn> createState() => _SubHeaderCategoriesBtnState();
}

class _SubHeaderCategoriesBtnState extends State<SubHeaderCategoriesBtn> {
  final LayerLink _link = LayerLink();
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active  = widget.isActive || _hovered;
    const primary = ColorsManager.primaryColor;
    final color   = active ? primary : (widget.isDark ? Colors.white70 : Colors.black87);

    final borderColor = widget.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);
    final bgColor     = widget.isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) { setState(() => _hovered = true); widget.onHover(_link); },
        onExit:  (_) { setState(() => _hovered = false); widget.onLeave(); },
        child: CustomPaint(
          painter: active ? _TabPainter(bgColor: bgColor, borderColor: borderColor) : null,
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.grid_view_rounded, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    'dashboard.categories'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: AppTextTheme.fontFamily,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: active ? primary : (widget.isDark ? Colors.white38 : Colors.black38),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SubHeaderBrandsBtn extends StatefulWidget {
  final bool isDark;
  final bool isActive;
  final void Function(LayerLink) onHover;
  final VoidCallback onLeave;

  const SubHeaderBrandsBtn({
    super.key,
    required this.isDark,
    required this.isActive,
    required this.onHover,
    required this.onLeave,
  });

  @override
  State<SubHeaderBrandsBtn> createState() => _SubHeaderBrandsBtnState();
}

class _SubHeaderBrandsBtnState extends State<SubHeaderBrandsBtn> {
  final LayerLink _link = LayerLink();
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive || _hovered;
    final color = active ? ColorsManager.primaryColor : (widget.isDark ? Colors.white70 : Colors.black87);

    final borderColor = widget.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);
    final bgColor     = widget.isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) { setState(() => _hovered = true); widget.onHover(_link); },
        onExit:  (_) { setState(() => _hovered = false); widget.onLeave(); },
        child: CustomPaint(
          painter: active ? _TabPainter(bgColor: bgColor, borderColor: borderColor) : null,
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'home.topBrands'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: AppTextTheme.fontFamily,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 14,
                      color: active ? ColorsManager.primaryColor : (widget.isDark ? Colors.white38 : Colors.black38)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SubHeaderCategoryItem extends StatefulWidget {
  final dynamic category;
  final bool isDark;
  final Duration animDelay;
  final bool isActive;
  final void Function(dynamic, LayerLink) onHover;
  final VoidCallback onLeave;

  const SubHeaderCategoryItem({
    super.key,
    required this.category,
    required this.isDark,
    required this.animDelay,
    required this.isActive,
    required this.onHover,
    required this.onLeave,
  });

  @override
  State<SubHeaderCategoryItem> createState() => _SubHeaderCategoryItemState();
}

class _SubHeaderCategoryItemState extends State<SubHeaderCategoryItem> {
  final LayerLink _layerLink = LayerLink();
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final locale      = Localizations.localeOf(context).languageCode;
    final name        = locale == 'ar' ? widget.category.nameAr : widget.category.name;
    final hasChildren = widget.category.hasChildren == true ||
        (widget.category.children != null && widget.category.children.isNotEmpty);
    final isActive    = widget.isActive || _hovered;
    const primary     = ColorsManager.primaryColor;
    final color       = isActive ? primary : (widget.isDark ? Colors.white70 : Colors.black87);
    
    final borderColor = widget.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);
    final bgColor     = widget.isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() => _hovered = true);
          if (hasChildren) widget.onHover(widget.category, _layerLink);
        },
        onExit: (_) {
          setState(() => _hovered = false);
          widget.onLeave();
        },
        child: GestureDetector(
          onTap: () => AppNavigator.pushNamed(
            context,
            '${Routes.categoryProducts}/${SlugUtils.slugify(widget.category.name, widget.category.id)}',
            arguments: widget.category,
          ),
          child: CustomPaint(
            painter: isActive ? _TabPainter(bgColor: bgColor, borderColor: borderColor) : null,
            child: SizedBox(
              height: 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontFamily: AppTextTheme.fontFamily,
                      ),
                    ),
                    if (hasChildren) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: color),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
