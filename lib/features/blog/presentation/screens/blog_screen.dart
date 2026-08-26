import 'package:fastway/core/widgets/safe_mouse_region.dart';
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/di/injection_container.dart';
import 'package:fastway/core/layout/simple_web_shell.dart';
import 'package:fastway/core/layout/web_footer.dart';
import 'package:fastway/core/responsive/max_width_container.dart';
import 'package:fastway/core/responsive/responsive_layout.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/features/blog/domain/entities/blog_entity.dart';
import 'package:fastway/core/widgets/custom_app_bar.dart';
import 'package:fastway/features/blog/presentation/cubit/blog_cubit.dart';
import 'package:fastway/features/blog/presentation/cubit/blog_state.dart';
import 'package:fastway/core/widgets/selectable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fastway/core/widgets/skeletons.dart';

class BlogScreen extends StatefulWidget {
  final BlogCategory? initialCategory;
  const BlogScreen({super.key, this.initialCategory});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  late final BlogCubit _cubit;

  @override
  void initState() {
    super.initState();
    // Always use the global singleton — safe in any context
    _cubit = sl<BlogCubit>();

    // Load posts if not already loaded
    if (_cubit.state is BlogInitial) {
      _cubit.loadPosts(initialCategory: widget.initialCategory);
    } else if (widget.initialCategory != null) {
      // Already loaded — just apply the filter
      Future.microtask(() {
        if (mounted) _cubit.filterByCategory(widget.initialCategory!);
      });
    }
  }

  @override
  void dispose() {
    // Do NOT close — BlogCubit is a global singleton managed by GetIt
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BlogCubit>.value(
      value: _cubit,
      child: _BlogScreenBody(initialCategory: widget.initialCategory),
    );
  }
}

class _BlogScreenBody extends StatelessWidget {
  final BlogCategory? initialCategory;
  const _BlogScreenBody({this.initialCategory});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWeb  = isWebLayout(context);

    if (isWeb) {
      return SimpleWebShell(
        showFooter: false,
        content: _WebBlogContent(isDark: isDark),
      );
    }

    final locale = Localizations.localeOf(context).languageCode;
    final String title = initialCategory != null && initialCategory!.id.isNotEmpty
        ? (locale == 'ar' ? initialCategory!.nameAr : initialCategory!.name)
        : 'blog.title'.tr();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F6FA),
      appBar: CustomAppBar(title: title),
      body: BlocBuilder<BlogCubit, BlogState>(
        builder: (context, state) {
          if (state is BlogLoading || state is BlogInitial) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.separated(
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, __) => const SizedBox(height: 300, child: BlogCardSkeleton()),
              ),
            );
          }
          if (state is BlogError) return _ErrorView(message: state.message);
          if (state is BlogLoaded) {
            if (initialCategory == null) {
              return _MobileBlogCategoriesLayout(state: state, isDark: isDark);
            } else {
              return _MobileBlogLayout(state: state, isDark: isDark);
            }
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Web content
// ─────────────────────────────────────────────────────────────────────────────

class _WebBlogContent extends StatelessWidget {
  final bool isDark;
  const _WebBlogContent({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlogCubit, BlogState>(
      builder: (context, state) {
        if (state is BlogLoading || state is BlogInitial) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 24, mainAxisSpacing: 32, childAspectRatio: 0.85,
              ),
              itemCount: 6,
              itemBuilder: (_, __) => const BlogCardSkeleton(),
            ),
          );
        }
        if (state is BlogError) {
          return SizedBox(
            height: 400,
            child: _ErrorView(message: state.message),
          );
        }
        if (state is BlogLoaded) return _WebBlogLayout(state: state, isDark: isDark);
        return const SizedBox.shrink();
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BEAUTIFUL CATEGORY FILTER BAR
// ═════════════════════════════════════════════════════════════════════════════

class _CategoryFilterDropdown extends StatelessWidget {
  final List<BlogCategory> categories;
  final BlogCategory selected;
  final bool isDark;

  const _CategoryFilterDropdown({
    required this.categories,
    required this.selected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final selectedLabel = locale == 'ar' ? selected.nameAr : selected.name;

    return PopupMenuButton<BlogCategory>(
      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, 40),
      onSelected: (cat) => context.read<BlogCubit>().filterByCategory(cat),
      itemBuilder: (context) {
        return categories.map((cat) {
          final isSelected = cat == selected;
          final label = locale == 'ar' ? cat.nameAr : cat.name;
          return PopupMenuItem<BlogCategory>(
            value: cat,
            child: Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isDark
                            ? (isSelected ? ColorsManager.primaryColor : Colors.white)
                            : (isSelected ? ColorsManager.primaryColor : Colors.black87),
                      )),
                ),
                if (isSelected)
                  const Icon(Icons.check_rounded, size: 16, color: ColorsManager.primaryColor),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selectedLabel,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18,
                color: isDark ? Colors.white54 : Colors.black45),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// WEB BLOG LAYOUT
// ═════════════════════════════════════════════════════════════════════════════

class _WebBlogLayout extends StatelessWidget {
  final BlogLoaded state;
  final bool isDark;

  const _WebBlogLayout({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MaxWidthContainer(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                Row(
                  children: [
                    InkWell(
                      onTap: () => AppNavigator.pushNamed(context, Routes.dashBoard),
                      child: Text('dashboard.home'.tr(), style: const TextStyle(fontSize: 13, color: ColorsManager.primaryColor, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.chevron_right_rounded, size: 16, color: isDark ? Colors.white38 : Colors.black38),
                    ),
                    Text('blog.title'.tr(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                    const Spacer(),
                    _CategoryFilterDropdown(
                      categories: state.categories,
                      selected: state.selectedCategory,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Selectable(
                  child: Text(
                    state.selectedCategory == BlogCategory.all
                        ? 'blog.title'.tr()
                        : (Localizations.localeOf(context).languageCode == 'ar' ? state.selectedCategory.nameAr : state.selectedCategory.name),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87),
                  ),
                ),
                const SizedBox(height: 28),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: state.filteredPosts.isEmpty
                      ? _EmptyState(key: const ValueKey('empty'), isDark: isDark)
                      : _buildGrid(context, state.filteredPosts),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
        const WebFooter(),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, List<BlogPost> posts) {
    return LayoutBuilder(
      key: ValueKey(posts.length),
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: posts.asMap().entries.map((entry) {
            final cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 20) / crossAxisCount;
            return SizedBox(
              width: cardWidth,
              child: _BlogCard(post: entry.value, isDark: isDark, index: entry.key),
            );
          }).toList(),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MOBILE BLOG LAYOUT
// ═════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// Mobile Categories Grid Layout (Shown when initialCategory is null)
// ─────────────────────────────────────────────────────────────────────────────

class _MobileBlogCategoriesLayout extends StatelessWidget {
  final BlogLoaded state;
  final bool isDark;

  const _MobileBlogCategoriesLayout({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    // include "All" category plus other categories
    final List<BlogCategory> displayCategories = [BlogCategory.all, ...state.categories.where((c) => c.id.isNotEmpty)];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: displayCategories.length,
      itemBuilder: (context, index) {
        final cat = displayCategories[index];
        final label = locale == 'ar' ? cat.nameAr : cat.name;
        final bool isAll = cat.id.isEmpty;
        
        return InkWell(
          onTap: () => AppNavigator.pushNamed(context, Routes.blog, arguments: cat),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (cat.image?.isNotEmpty == true)
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: CachedNetworkImage(
                        imageUrl: cat.image!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: ColorsManager.primaryColor.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Center(
                        child: Icon(
                          isAll ? Icons.grid_view_rounded : Icons.article_rounded,
                          size: 40,
                          color: ColorsManager.primaryColor,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isAll && cat.postsCount > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${cat.postsCount} مقال',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MobileBlogLayout extends StatelessWidget {
  final BlogLoaded state;
  final bool isDark;

  const _MobileBlogLayout({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _CategoryFilterDropdown(
                  categories: state.categories,
                  selected:   state.selectedCategory,
                  isDark:     isDark,
                ),
              ],
            ),
          ),
        ),
        if (state.filteredPosts.isEmpty)
          SliverToBoxAdapter(child: _EmptyState(isDark: isDark))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _BlogCard(post: state.filteredPosts[index], isDark: isDark, index: index),
                ),
                childCount: state.filteredPosts.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BLOG CARD
// ═════════════════════════════════════════════════════════════════════════════

class _BlogCard extends StatefulWidget {
  final BlogPost post;
  final bool isDark;
  final int index;

  const _BlogCard({required this.post, required this.isDark, required this.index});

  @override
  State<_BlogCard> createState() => _BlogCardState();
}

class _BlogCardState extends State<_BlogCard> {
  bool _hovered = false;

  static const _palette = <Color>[
    Color(0xFF10B981), Color(0xFF3B82F6), Color(0xFF8B5CF6),
    Color(0xFFF59E0B), ColorsManager.primaryColor, Color(0xFFEF4444),
  ];

  Color get _accent {
    // Use category-based color if available, else cycle by index
    if (widget.post.categoryId != null) {
      return _palette[(widget.post.categoryId.hashCode.abs()) % _palette.length];
    }
    return _palette[widget.index % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final locale   = Localizations.localeOf(context).languageCode;
    final post     = widget.post;
    final accent   = _accent;
    final title    = locale == 'ar' ? post.titleAr   : post.title;
    final excerpt  = locale == 'ar' ? post.excerptAr : post.excerpt;
    final catLabel = locale == 'ar'
        ? (post.categoryNameAr ?? post.categoryName ?? '')
        : (post.categoryName ?? '');

    return SafeMouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => AppNavigator.pushNamed(context, '${Routes.blogDetail}/${post.slug}'),
        child: Container(
          decoration: BoxDecoration(
            color: widget.isDark ? ColorsManager.surfaceDarkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? accent.withValues(alpha: 0.4)
                  : (widget.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
            ),
            // BoxShadow removed — blurRadius change on hover = GPU repaint
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 16.0 / 9.0,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      post.coverImage != null
                          ? CachedNetworkImage(
                              imageUrl: post.coverImage!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _ImagePlaceholder(accent),
                              errorWidget:  (_, __, ___) => _ImagePlaceholder(accent),
                            )
                          : _ImagePlaceholder(accent),
                      // Gradient overlay
                      Positioned(
                        bottom: 0, left: 0, right: 0, height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
                              begin: Alignment.bottomCenter, end: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ),
                      // Category badge
                      if (catLabel.isNotEmpty)
                        Positioned(
                          top: 12, left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(8),
                              // BoxShadow removed from category badge
                            ),
                            child: Text(
                              catLabel,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                          ),
                        ),
                      // Read time badge
                      Positioned(
                        bottom: 12, right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule_rounded, size: 12, color: Colors.white.withValues(alpha: 0.9)),
                              const SizedBox(width: 4),
                              Text(
                                '${post.readTimeMinutes} min',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 55,
                      child: Text(
                        title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800, height: 1.3,
                          color: _hovered ? accent : (widget.isDark ? Colors.white : const Color(0xFF1A1A1A)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      excerpt,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: widget.isDark ? Colors.white54 : Colors.black54, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'blog.read_more'.tr(),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accent),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: accent),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final Color accent;
  const _ImagePlaceholder(this.accent);

  @override
  Widget build(BuildContext context) => Container(
    color: accent.withValues(alpha: 0.15),
    child: Center(child: Icon(Icons.article_rounded, size: 40, color: accent.withValues(alpha: 0.5))),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: isDark ? Colors.white24 : Colors.black12),
            const SizedBox(height: 16),
            Text(
              'blog.no_posts'.tr(),
              style: TextStyle(fontSize: 16, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ERROR VIEW
// ═════════════════════════════════════════════════════════════════════════════

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.read<BlogCubit>().loadPosts(),
            icon: const Icon(Icons.refresh),
            label: Text('errors.network.action'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.primaryColor, foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
