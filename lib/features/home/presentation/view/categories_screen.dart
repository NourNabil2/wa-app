// lib/features/home/presentation/view/categories_screen.dart
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
import 'package:fastway/core/widgets/skeletons.dart';
import 'package:fastway/features/home/domain/entities/category_entity.dart';
import 'package:fastway/features/home/presentation/cubit/home_cubit.dart';
import 'package:fastway/features/home/presentation/cubit/home_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
// Root screen
// ─────────────────────────────────────────────────────────────────────────────

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWeb = isWebLayout(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        // ── Loading ─────────────────────────────────────────────────────────
        if (state is HomeLoading || state is HomeInitial) {
          const loading = SizedBox(
            height: 400,
            child: SubCategorySkeleton(),
          );
          if (isWeb) {
            return const SimpleWebShell(showFooter: true, content: loading);
          }
          return const Scaffold(
            body: SafeArea(child: SubCategorySkeleton()),
          );
        }

        // ── Error ───────────────────────────────────────────────────────────
        if (state is HomeError) {
          final errorWidget = Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.error_outline_rounded, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(state.message, style: TextStyle(color: Colors.grey.shade500)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<HomeCubit>().loadHome(),
                child: Text('common.retry'.tr()),
              ),
            ]),
          );
          if (isWeb) {
            return SimpleWebShell(
                showFooter: true, content: SizedBox(height: 400, child: errorWidget));
          }
          return Scaffold(
            body: SafeArea(child: errorWidget),
          );
        }

        final categories = state is HomeLoaded ? state.categories : <CategoryEntity>[];
        final locale = Localizations.localeOf(context).languageCode;

        // ── Web layout ──────────────────────────────────────────────────────
        if (isWeb) {
          return SimpleWebShell(
            showFooter: true,
            content: _WebCategoriesContent(
              categories: categories,
              locale: locale,
              isDark: isDark,
            ),
          );
        }

        // ── Mobile layout ───────────────────────────────────────────────────
        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F6FA),
          body: SafeArea(
            child: categories.isEmpty
                ? Center(child: Text('home.noCategories'.tr()))
                : _MobileCategoriesList(
                    categories: categories, locale: locale, isDark: isDark),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Web content (flat Column — SimpleWebShell owns the scroll)
// ─────────────────────────────────────────────────────────────────────────────

class _WebCategoriesContent extends StatelessWidget {
  final List<CategoryEntity> categories;
  final String locale;
  final bool isDark;

  const _WebCategoriesContent({
    required this.categories,
    required this.locale,
    required this.isDark,
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
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => AppNavigator.pushNamed(context, Routes.dashBoard),
                    child: Text(
                      'dashboard.home'.tr(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: ColorsManager.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.chevron_right_rounded, size: 16, color: dimColor),
                  ),
                  Text(
                    'dashboard.categories'.tr(),
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

        // ── Grid ──────────────────────────────────────────────────────────
        if (categories.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: Center(child: Text('home.noCategories'.tr())),
          )
        else
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
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
                    itemCount: categories.length,
                    itemBuilder: (_, i) => _CategoryCard(
                      category: categories[i],
                      locale: locale,
                      isDark: isDark,
                      isWeb: true,
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
// Mobile List (Horizontal Cards)
// ─────────────────────────────────────────────────────────────────────────────

class _MobileCategoriesList extends StatelessWidget {
  final List<CategoryEntity> categories;
  final String locale;
  final bool isDark;

  const _MobileCategoriesList({
    required this.categories,
    required this.locale,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) => _MobileCategoryCard(
        category: categories[i],
        locale: locale,
        isDark: isDark,
      ),
    );
  }
}

class _MobileCategoryCard extends StatelessWidget {
  final CategoryEntity category;
  final String locale;
  final bool isDark;

  const _MobileCategoryCard({
    required this.category,
    required this.locale,
    required this.isDark,
  });

  void _onTap(BuildContext context) {
    if (category.hasChildren) {
      _showSubcategoriesBottomSheet(context, category, locale, isDark);
    } else {
      AppNavigator.pushNamed(
        context,
        '${Routes.categoryProducts}/${SlugUtils.slugify(category.name, category.id)}',
        arguments: category,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = category.localizedName(locale);
    final iconUrl = _resolveIconUrl(category);
    final bg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFCFCFCF);

    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Text
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    name.toUpperCase(),
                    textAlign: TextAlign.start,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
            // Large Image
            PositionedDirectional(
              end: -20,
              top: -20,
              bottom: -20,
              width: 180,
              child: iconUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: iconUrl,
                      fit: BoxFit.contain,
                      memCacheWidth: 360,
                      memCacheHeight: 360,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      placeholder: (_, __) => const Icon(
                        Icons.category_rounded,
                        color: Colors.white24,
                        size: 60,
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.category_rounded,
                        color: Colors.white24,
                        size: 60,
                      ),
                    )
                  : const Icon(
                      Icons.category_rounded,
                      color: Colors.white24,
                      size: 60,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single category card (shared mobile + web)
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final CategoryEntity category;
  final String locale;
  final bool isDark;
  final bool isWeb;

  const _CategoryCard({
    required this.category,
    required this.locale,
    required this.isDark,
    required this.isWeb,
  });

  void _onTap(BuildContext context) {
    if (category.hasChildren) {
      if (!isWeb) {
        _showSubcategoriesBottomSheet(context, category, locale, isDark);
      } else {
        AppNavigator.pushNamed(
          context,
          '${Routes.subCategories}/${SlugUtils.slugify(category.name, category.id)}',
          arguments: category,
        );
      }
    } else {
      AppNavigator.pushNamed(
        context,
        '${Routes.categoryProducts}/${SlugUtils.slugify(category.name, category.id)}',
        arguments: category,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = category.localizedName(locale);
    final accent = _parseColor(category.color);
    final iconUrl = _resolveIconUrl(category);

    final card = Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        borderRadius: BorderRadius.zero,
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
          // Icon / image
          Container(
            width: isWeb ? 64 : 52,
            height: isWeb ? 64 : 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: iconUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: iconUrl,
                    fit: BoxFit.contain,
                    memCacheWidth: 128,  // 64px icon * 2x retina
                    memCacheHeight: 128,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder: (_, __) => Icon(
                      Icons.category_rounded,
                      color: accent,
                      size: isWeb ? 28 : 22,
                    ),
                    errorWidget: (_, __, ___) => Icon(
                      Icons.category_rounded,
                      color: accent,
                      size: isWeb ? 28 : 22,
                    ),
                  )
                : Icon(
                    Icons.category_rounded,
                    color: accent,
                    size: isWeb ? 28 : 22,
                  ),
          ),
          SizedBox(height: isWeb ? 12 : 8),
          // Name
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
          // Arrow hint on web
          if (isWeb) ...[
            const SizedBox(height: 6),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 10,
              color: accent.withValues(alpha: 0.6),
            ),
          ],
        ],
      ),
    );

    if (isWeb) {
      return HoverableCard(onTap: () => _onTap(context), child: card);
    }
    return GestureDetector(onTap: () => _onTap(context), child: card);
  }
}

void _showSubcategoriesBottomSheet(
  BuildContext context,
  CategoryEntity category,
  String locale,
  bool isDark,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF1C1C2E) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: category.children.length + 1,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      title: Text(
                        'product.actions.view_all'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ColorsManager.primaryColor,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        AppNavigator.pushNamed(
                          context,
                          '${Routes.categoryProducts}/${SlugUtils.slugify(category.name, category.id)}',
                          arguments: category,
                        );
                      },
                    );
                  }

                  final sub = category.children[index - 1];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    title: Text(
                      sub.localizedName(locale),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (sub.hasChildren) {
                        AppNavigator.pushNamed(
                          context,
                          '${Routes.subCategories}/${SlugUtils.slugify(sub.name, sub.id)}',
                          arguments: sub,
                        );
                      } else {
                        AppNavigator.pushNamed(
                          context,
                          '${Routes.categoryProducts}/${SlugUtils.slugify(sub.name, sub.id)}',
                          arguments: sub,
                        );
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}