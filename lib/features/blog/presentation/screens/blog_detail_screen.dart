import 'package:fastway/core/widgets/safe_mouse_region.dart';
// lib/features/blog/presentation/screens/blog_detail_screen.dart
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/di/injection_container.dart';
import 'package:fastway/core/layout/simple_web_shell.dart';
import 'package:fastway/core/responsive/max_width_container.dart';
import 'package:fastway/core/responsive/responsive_layout.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/features/blog/data/datasources/blog_remote_datasource.dart';
import 'package:fastway/features/blog/domain/entities/blog_entity.dart';
import 'package:fastway/features/blog/presentation/cubit/blog_cubit.dart';
import 'package:fastway/features/blog/presentation/cubit/blog_state.dart';
import 'package:fastway/core/widgets/selectable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fastway/core/widgets/skeletons.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

class BlogDetailScreen extends StatelessWidget {
  final String slug;
  const BlogDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    // Create an isolated cubit (NOT the singleton) so loadPostDetail
    // doesn't corrupt the shared blog list state.
    return BlocProvider(
      create: (_) => BlogCubit(sl<BlogRemoteDataSource>())..loadPostDetail(slug),
      child: _BlogDetailBody(slug: slug),
    );
  }
}

class _BlogDetailBody extends StatelessWidget {
  final String slug;
  const _BlogDetailBody({required this.slug});

  @override
  Widget build(BuildContext context) {
    final isWeb = isWebLayout(context);
    final content = BlocBuilder<BlogCubit, BlogState>(
      builder: (ctx, state) {
        if (state is BlogLoading || state is BlogInitial) {
          // Do NOT use Scaffold here — it fails inside SimpleWebShell's scrollable
          return const SizedBox(height: 800, child: BlogDetailSkeleton());
        }
        if (state is BlogError) {
          return SizedBox(
            height: 400,
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(state.message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ctx.read<BlogCubit>().loadPostDetail(slug),
                  child: Text('common.retry'.tr()),
                ),
              ]),
            ),
          );
        }
        if (state is BlogDetailLoaded) {
          return _ArticlePage(post: state.post, relatedPosts: state.related);
        }
        return const SizedBox.shrink();
      },
    );

    if (isWeb) {
      return SimpleWebShell(showFooter: true, content: content);
    }
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('blog.title'.tr()),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87,
        iconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(child: content),
    );
  }
}

// ─── Full article page ────────────────────────────────────────────────────────
class _ArticlePage extends StatelessWidget {
  final BlogPost post;
  final List<BlogPost> relatedPosts;
  const _ArticlePage({required this.post, required this.relatedPosts});

  static const _categoryColors = <String, Color>{
    'Nutrition': Color(0xFF10B981),
    'Logistics': Color(0xFF3B82F6),
    'Delivery': Color(0xFF8B5CF6),
    'Science': Color(0xFFF59E0B),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.sizeOf(context).width > 800;
    final locale = Localizations.localeOf(context).languageCode;
    final title = locale == 'ar' ? post.titleAr : post.title;
    final content = locale == 'ar' ? post.contentAr : post.content;
    final catLabel = locale == 'ar'
        ? (post.categoryNameAr ?? post.categoryName ?? '')
        : (post.categoryName ?? '');
    const accent = ColorsManager.primaryColor; // default; refined below by categoryId hash
    final bg     = isDark ? ColorsManager.surfaceDarkBase : const Color(0xFFF5F6FA);

    // Use related posts from state, filtering out the current article just in case
    final related = relatedPosts.where((r) => r.slug != post.slug).take(3).toList();

    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Main Article Layout ─────────────────────────────────────────────
          MaxWidthContainer(
            maxWidth: 800,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 16, vertical: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SimpleHeader(post: post, catLabel: catLabel, isDark: isDark, locale: locale, accent: accent),
                  const SizedBox(height: 40),
                  _MainContent(
                      post: post, content: content, isDark: isDark,
                      title: title, accent: accent),
                ],
              ),
            ),
          ),
          
          // ── Related Articles Section ─────────────────────────────────────────
          if (related.isNotEmpty)
            Container(
              width: double.infinity,
              color: isDark ? ColorsManager.surfaceDarkElevated : ColorsManager.gray100,
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: MaxWidthContainer(
                maxWidth: 1160,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16),
                  child: _RelatedArticlesSection(
                      related: related, isDark: isDark, accent: accent),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Simple Header ──────────────────────────────────────────────────────────────
class _SimpleHeader extends StatelessWidget {
  final BlogPost post;
  final Color accent;
  final String catLabel;
  final bool isDark;
  final String locale;

  const _SimpleHeader({
    required this.post, required this.accent, required this.catLabel,
    required this.isDark, required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final title = locale == 'ar' ? post.titleAr : post.title;
    final textColor = isDark ? Colors.white : ColorsManager.gray900;
    final secondaryColor = isDark ? Colors.white70 : ColorsManager.gray500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            GestureDetector(
              onTap: () => AppNavigator.pushNamed(context, Routes.blog),
              child: Text('blog.title'.tr(),
                  style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.chevron_right, size: 16, color: secondaryColor),
            ),
            if (catLabel.isNotEmpty) ...[
              Text(catLabel, style: TextStyle(color: secondaryColor, fontSize: 14, fontWeight: FontWeight.w500)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.chevron_right, size: 16, color: secondaryColor),
              ),
            ],
            Text(title, 
              softWrap: true,
              style: TextStyle(color: secondaryColor, fontSize: 14)),
          ],
        ),

        const SizedBox(height: 24),

        // Title
        Selectable(
          child: Text(title,
              softWrap: true,
              maxLines: 10,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: MediaQuery.sizeOf(context).width < 400 ? 22 : MediaQuery.sizeOf(context).width < 768 ? 26 : 42,
                fontWeight: FontWeight.w900,
                color: textColor, height: 1.15, letterSpacing: -0.5,
              )),
        ),

        const SizedBox(height: 24),
        
        if (post.coverImage != null && post.coverImage!.isNotEmpty) ...[
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 16.0 / 9.0,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? Colors.white24 : Colors.black12, width: 1.5),
              ),
              child: CachedNetworkImage(
                imageUrl: post.coverImage!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: accent.withValues(alpha: 0.1),
                  child: Center(child: CircularProgressIndicator(color: accent)),
                ),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _fmt(String raw) {
    try { return DateFormat('d MMM yyyy').format(DateTime.parse(raw)); } catch (_) { return raw; }
  }
}

// ── Main article content ──────────────────────────────────────────────────────
class _MainContent extends StatelessWidget {
  final BlogPost post;
  final String? content;
  final bool isDark;
  final String title;
  final Color accent;

  const _MainContent({
    required this.post, required this.content,
    required this.isDark, required this.title, required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final excerpt = locale == 'ar' ? post.excerptAr : post.excerpt;
    final bodyColor = isDark ? Colors.white70 : ColorsManager.gray700;

    return Selectable(
      child: content != null && content!.isNotEmpty
          ? _HtmlContent(html: content!, isDark: isDark, accent: accent)
          : Text(excerpt,
              style: TextStyle(fontSize: 18, height: 1.8, color: bodyColor, letterSpacing: 0.2)),
    );
  }
}

// ── Related Articles Section ───────────────────────────────────────────────────
class _RelatedArticlesSection extends StatelessWidget {
  final List<BlogPost> related;
  final bool isDark;
  final Color accent;
  const _RelatedArticlesSection({required this.related, required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (related.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'blog.related_articles'.tr(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : ColorsManager.gray900,
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            final crossAxisCount = isWide ? 4 : 2;
            
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.65,
              ),
              itemCount: related.length,
              itemBuilder: (context, index) {
                return _RelatedCard(
                  article: related[index],
                  isDark: isDark,
                  delay: Duration(milliseconds: 100 + index * 60),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// ── Related article card ──────────────────────────────────────────────────────
class _RelatedCard extends StatefulWidget {
  final BlogPost article;
  final bool isDark;
  final Duration delay;
  const _RelatedCard({required this.article, required this.isDark, required this.delay});
  @override State<_RelatedCard> createState() => _RelatedCardState();
}

class _RelatedCardState extends State<_RelatedCard> {
  bool _hovered = false;
  static const _catColors = <String, Color>{
    'Nutrition': Color(0xFF10B981),
    'Logistics': Color(0xFF3B82F6),
    'Delivery': Color(0xFF8B5CF6),
    'Science': Color(0xFFF59E0B),
  };

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    final locale = Localizations.localeOf(context).languageCode;
    final title = locale == 'ar' ? a.titleAr : a.title;
    final catLabel = locale == 'ar'
        ? (a.categoryNameAr ?? a.categoryName ?? '')
        : (a.categoryName ?? '');
    
    final accent = _catColors[a.categoryName] ?? ColorsManager.primaryColor;

    return SafeMouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => AppNavigator.pushNamed(context, '${Routes.blogDetail}/${a.slug}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _hovered ? -6 : 0, 0),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _hovered ? [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))
            ] : [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
            ],
            border: Border.all(color: widget.isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thumbnail
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: a.coverImage != null
                      ? CachedNetworkImage(
                          imageUrl: a.coverImage!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: accent.withValues(alpha: 0.15)),
                          errorWidget: (_, __, ___) => Container(color: accent.withValues(alpha: 0.15),
                              child: Icon(Icons.article, color: accent, size: 32)),
                        )
                      : Container(color: accent.withValues(alpha: 0.15),
                          child: Icon(Icons.article, color: accent, size: 32)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (catLabel.isNotEmpty) ...[
                      Text(catLabel,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: accent)),
                      const SizedBox(height: 8),
                    ],
                    Text(title,
                        maxLines: 3, overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800, height: 1.4,
                          color: widget.isDark ? Colors.white : ColorsManager.gray900,
                        )),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: widget.isDark ? Colors.white54 : Colors.black54),
                        const SizedBox(width: 4),
                        Text('${a.readTimeMinutes} ${'blog.min_read'.tr()}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.isDark ? Colors.white54 : Colors.black54)),
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

// ── HTML content renderer ─────────────────────────────────────────────────────
class _HtmlContent extends StatelessWidget {
  final String html;
  final bool isDark;
  final Color accent;
  const _HtmlContent({required this.html, required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    final bodyColor = isDark ? Colors.white70 : ColorsManager.gray700;
    
    return HtmlWidget(
      html,
      textStyle: TextStyle(
        fontSize: 18, 
        height: 1.8, 
        color: bodyColor, 
        letterSpacing: 0.2,
      ),
      customStylesBuilder: (element) {
        if (element.localName == 'h1' || element.localName == 'h2' || element.localName == 'h3') {
          return {'color': isDark ? 'white' : 'black'};
        }
        return null;
      },
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────
