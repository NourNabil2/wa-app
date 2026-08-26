// lib/features/category/presentation/screens/sub_categories_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/api/model/endpoints.dart';
import 'package:fastway/core/layout/simple_web_shell.dart';
import 'package:fastway/core/responsive/hoverable_card.dart';
import 'package:fastway/core/responsive/responsive_layout.dart';
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/utils/slug_utils.dart';
import 'package:fastway/core/widgets/custom_app_bar.dart';
import 'package:fastway/features/home/domain/entities/category_entity.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Color _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return ColorsManager.primaryColor;
  try {
    return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  } catch (_) {
    return ColorsManager.primaryColor;
  }
}

String _resolveIconUrl(CategoryEntity category) {
  final rawUrl = (category.image?.isNotEmpty == true ? category.image! : category.iconUrl).trim();
  if (rawUrl.isEmpty) return '';
  if (rawUrl.startsWith('http')) return rawUrl;
  final baseDomain = Endpoints.baseUrl.replaceAll(RegExp(r'/api/v1$'), '');
  return '$baseDomain/storage/categories/$rawUrl.png';
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class SubCategoriesScreen extends StatelessWidget {
  final CategoryEntity? category;

  const SubCategoriesScreen({super.key, this.category});

  void _navigate(BuildContext context, CategoryEntity subCat) {
    if (subCat.hasChildren) {
      AppNavigator.pushNamed(
        context,
        '${Routes.subCategories}/${SlugUtils.slugify(subCat.name, subCat.id)}',
        arguments: subCat,
      );
    } else {
      AppNavigator.pushNamed(
        context,
        '${Routes.categoryProducts}/${SlugUtils.slugify(subCat.name, subCat.id)}',
        arguments: subCat,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = isWebLayout(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;

    // ── Empty / no-data state ─────────────────────────────────────────────
    if (category == null || category!.children.isEmpty) {
      final emptyWidget = Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('common.noData'.tr(),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ]),
      );
      if (isWeb) {
        return SimpleWebShell(
          showFooter: true,
          content: SizedBox(height: 400, child: emptyWidget),
        );
      }
      return Scaffold(
        appBar: CustomAppBar(title: 'categories.title'.tr()),
        body: emptyWidget,
      );
    }

    final title = category!.localizedName(locale);
    final parentAccent = _parseColor(category!.color);
    final children = category!.children;

    // ── Web layout ────────────────────────────────────────────────────────
    if (isWeb) {
      return SimpleWebShell(
        showFooter: true,
        content: _WebSubCategoriesContent(
          title: title,
          parentAccent: parentAccent,
          category: category!,
          children: children,
          locale: locale,
          isDark: isDark,
          onNavigate: (sub) => _navigate(context, sub),
        ),
      );
    }

    // ── Mobile layout ─────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F6FA),
      appBar: CustomAppBar(title: title),
      body: _MobileSubCategoriesGrid(
        children: children,
        locale: locale,
        isDark: isDark,
        onNavigate: (sub) => _navigate(context, sub),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Web content — flat Column, SimpleWebShell owns the scroll
// ─────────────────────────────────────────────────────────────────────────────

class _WebSubCategoriesContent extends StatelessWidget {
  final String title;
  final Color parentAccent;
  final CategoryEntity category;
  final List<CategoryEntity> children;
  final String locale;
  final bool isDark;
  final void Function(CategoryEntity) onNavigate;

  const _WebSubCategoriesContent({
    required this.title,
    required this.parentAccent,
    required this.category,
    required this.children,
    required this.locale,
    required this.isDark,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final dimColor = isDark ? Colors.white38 : Colors.black38;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Breadcrumb ────────────────────────────────────────────────────
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => AppNavigator.pushNamed(context, Routes.dashBoard),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Text(
                        'dashboard.home'.tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: ColorsManager.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.chevron_right_rounded, size: 16, color: dimColor),
                  ),
                  GestureDetector(
                    onTap: () => AppNavigator.pushNamed(context, Routes.categories),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Text(
                        'dashboard.categories'.tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: ColorsManager.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.chevron_right_rounded, size: 16, color: dimColor),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Sub-categories grid ───────────────────────────────────────────
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
              child: LayoutBuilder(builder: (ctx, box) {
                final cols = box.maxWidth >= 900
                    ? 6
                    : box.maxWidth >= 700
                        ? 5
                        : 4;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: children.length,
                  itemBuilder: (_, i) => _SubCatCard(
                    subCat: children[i],
                    locale: locale,
                    isDark: isDark,
                    isWeb: true,
                    onTap: () => onNavigate(children[i]),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile grid
// ─────────────────────────────────────────────────────────────────────────────

class _MobileSubCategoriesGrid extends StatelessWidget {
  final List<CategoryEntity> children;
  final String locale;
  final bool isDark;
  final void Function(CategoryEntity) onNavigate;

  const _MobileSubCategoriesGrid({
    required this.children,
    required this.locale,
    required this.isDark,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final cols = MediaQuery.sizeOf(context).width >= 600 ? 4 : 2;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: children.length,
      itemBuilder: (_, i) => _SubCatCard(
        subCat: children[i],
        locale: locale,
        isDark: isDark,
        isWeb: false,
        onTap: () => onNavigate(children[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-category card (shared)
// ─────────────────────────────────────────────────────────────────────────────

class _SubCatCard extends StatelessWidget {
  final CategoryEntity subCat;
  final String locale;
  final bool isDark;
  final bool isWeb;
  final VoidCallback onTap;

  const _SubCatCard({
    required this.subCat,
    required this.locale,
    required this.isDark,
    required this.isWeb,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = subCat.localizedName(locale);
    final accent = _parseColor(subCat.color);

    final card = Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isWeb ? 64 : 52,
            height: isWeb ? 64 : 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: EdgeInsets.all(isWeb ? 10 : 8),
              child: _CategoryIcon(category: subCat, size: isWeb ? 28 : 22, accent: accent),
            ),
          ),
          SizedBox(height: isWeb ? 12 : 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isWeb ? 13 : 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                height: 1.3,
              ),
            ),
          ),
          if (isWeb && subCat.hasChildren) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.grid_view_rounded, size: 9, color: accent),
                  const SizedBox(width: 3),
                  Text(
                    '${subCat.children.length}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    if (isWeb) {
      return HoverableCard(onTap: onTap, child: card);
    }
    return GestureDetector(onTap: onTap, child: card);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon widget — resolves URL or falls back to Icon
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryIcon extends StatelessWidget {
  final CategoryEntity category;
  final double size;
  final Color accent;

  const _CategoryIcon({
    required this.category,
    required this.size,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveIconUrl(category);
    if (resolved.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: resolved,
        fit: BoxFit.contain,
        memCacheWidth: 128,
        memCacheHeight: 128,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, __) =>
            Icon(Icons.category_rounded, color: accent, size: size),
        errorWidget: (_, __, ___) =>
            Icon(Icons.category_rounded, color: accent, size: size),
      );
    }
    return Icon(Icons.category_rounded, color: accent, size: size);
  }
}
