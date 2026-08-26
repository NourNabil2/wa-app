import 'package:fastway/core/widgets/safe_mouse_region.dart';
import 'package:easy_localization/easy_localization.dart';
// lib/features/home/presentation/widget/card/web_category_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fastway/core/api/model/endpoints.dart';
import 'package:fastway/features/home/domain/entities/category_entity.dart';
import 'package:fastway/core/theme/colors.dart';

class WebCategoryCard extends StatefulWidget {
  final CategoryEntity category;
  final String name;
  final int index;
  final VoidCallback onTap;

  const WebCategoryCard({
    super.key,
    required this.category,
    required this.name,
    required this.index,
    required this.onTap,
  });

  @override
  State<WebCategoryCard> createState() => _WebCategoryCardState();
}

class _WebCategoryCardState extends State<WebCategoryCard> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  Color get _accentColor {
    try {
      final hex = widget.category.color?.replaceAll('#', '') ?? '10B981';
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return ColorsManager.primaryColor;
    }
  }

  String get _fullImageUrl {
    final rawUrl = widget.category.iconUrl.trim();
    if (rawUrl.isEmpty) return '';
    if (rawUrl.startsWith('http') || rawUrl.startsWith('assets/')) return rawUrl;
    final baseDomain = Endpoints.baseUrl.replaceAll(RegExp(r'/api/v1$'), '');
    return '$baseDomain/storage/categories/$rawUrl.png';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accentColor;

    return SafeMouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        // All hover animations removed — BoxShadow change + Matrix4 were
        // forcing GPU compositing layers on every hover event.
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141414) : Colors.white,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: _isHovered
                  ? accent.withValues(alpha: 0.3)
                  : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.zero,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. الأيقونة (على الجنب)
                      _buildIcon(26, accent),

                      const SizedBox(width: 12), // مسافة بين الأيقونة والنص

                      // 2. النصوص (اسم القسم وزر الاستكشاف)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center, // توسيط عمودي
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              maxLines: 2, // سامحين بسطرين لو الاسم طويل بما إن المساحة بقت أضيق
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white.withValues(alpha: 0.95) : ColorsManager.surfaceDarkElevated,
                                letterSpacing: -0.2,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // CTA (Explore)
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'categories.explore'.tr(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 11,
                                  color: accent,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }

  Widget _buildIcon(double sz, Color accent) {
    final imageUrl = _fullImageUrl;
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
        color: accent,
        colorBlendMode: BlendMode.srcIn,
        errorWidget: (_, __, ___) =>
            Icon(Icons.category_rounded, color: accent, size: sz),
      );
    }
    return Icon(Icons.category_rounded, color: accent, size: sz);
  }
}