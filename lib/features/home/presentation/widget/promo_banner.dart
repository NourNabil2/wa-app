import 'package:fastway/core/widgets/safe_mouse_region.dart';
// lib/features/home/presentation/widget/promo_banner.dart
// Premium Hero Slider — Amazon/Noon style
import 'dart:async';
import 'dart:ui' show PointerDeviceKind;
import 'package:fastway/features/home/domain/entities/banner_entity.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/responsive/responsive_layout.dart';
import 'package:fastway/core/widgets/fastway_logo_fallback.dart' as fastway_logo;

class PromoBanner extends StatefulWidget {
  final List<BannerEntity> banners;
  final VoidCallback? onTap;

  const PromoBanner({super.key, this.banners = const [], this.onTap});

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  Timer? _autoPlayTimer;
  bool _isHovered = false;
  // Note: _progressController removed — the AnimatedBuilder was running at
  // 60fps continuously, causing GPU layer thrashing across the entire page.

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (widget.banners.length <= 1) return;
    // Auto-advance every 5 seconds
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _isHovered) return;
      _nextPage();
    });
  }

  void _nextPage() {
    if (!_pageController.hasClients) return;
    final next = (_currentPage + 1) % widget.banners.length;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
  }

  void _prevPage() {
    if (!_pageController.hasClients) return;
    final prev =
        (_currentPage - 1 + widget.banners.length) % widget.banners.length;
    _pageController.animateToPage(
      prev,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = isWebLayout(context);
    final screenWidth = MediaQuery.sizeOf(context).width;

    if (widget.banners.isEmpty) {
      final placeholderHeight = isWeb ? screenWidth / (13.0 / 5.0) : 360.h;
      return _PlaceholderBanner(height: placeholderHeight, isWeb: isWeb);
    }

    Widget content = Stack(
      children: [
        // ── Full-bleed pages ───────────────────────────────────────────
        PageView.builder(
          controller: _pageController,
          itemCount: widget.banners.length,
          scrollBehavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse
            },
          ),
          onPageChanged: (i) {
            setState(() => _currentPage = i);
          },
          itemBuilder: (context, index) {
            final banner = widget.banners[index];
            return _BannerPage(
              banner: banner,
              onTap: widget.onTap,
            );
          },
        ),

        // ── Banner title / subtitle ────────────────────────────────────
        if (widget.banners.isNotEmpty)
          Positioned(
            bottom: isWeb ? 56 : 30.h,
            left: isWeb ? 40 : 16.w,
            right: isWeb ? 120 : 16.w,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _BannerText(
                key: ValueKey(_currentPage),
                banner: widget.banners[_currentPage],
              ),
            ),
          ),

        // ── Progress indicator bar ─────────────────────────────────────
        if (widget.banners.length > 1)
          Positioned(
            bottom: isWeb ? 20 : 10.h,
            left: 0,
            right: 0,
            child: Center(
              child: _StaticDotsBar(
                count: widget.banners.length,
                current: _currentPage,
              ),
            ),
          ),

        // ── Web nav arrows ─────────────────────────────────────────────
        if (isWeb && widget.banners.length > 1) ...[
          _NavArrow(isLeft: true, isVisible: true, onTap: _nextPage),
          _NavArrow(isLeft: false, isVisible: true, onTap: _prevPage),
        ],

      ],
    );

    if (isWeb) {
      content = AspectRatio(aspectRatio: 13.0 / 5.0, child: content);
    } else {
      content = SizedBox(height: 200.h, child: content);
    }

    return SafeMouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _autoPlayTimer?.cancel();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _startAutoPlay();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }
}

// ── Individual banner page ─────────────────────────────────────────────────────
class _BannerPage extends StatelessWidget {
  final BannerEntity banner;
  final VoidCallback? onTap;

  const _BannerPage({required this.banner, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isWeb = isWebLayout(context);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (banner.imageUrl.isNotEmpty)
            banner.imageUrl.startsWith('assets/')
                ? Image.asset(
                    banner.imageUrl,
                    fit: isWeb ? BoxFit.cover : BoxFit.fill,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => _FallbackBanner(title: banner.title),
                  )
                : CachedNetworkImage(
                    imageUrl: banner.imageUrl,
                    fit: isWeb ? BoxFit.cover : BoxFit.fill,
                    width: double.infinity,
                    height: double.infinity,
                    memCacheWidth: 840,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder: (_, __) => Container(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1A1A2E)
                          : const Color(0xFFF5F5F5),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: ColorsManager.primaryColor,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => _FallbackBanner(title: banner.title),
                  )
          else
            _FallbackBanner(title: banner.title),
        ],
      ),
    );
  }
}

// ── Fallback gradient banner ──────────────────────────────────────────────────
class _FallbackBanner extends StatelessWidget {
  final String title;
  const _FallbackBanner({required this.title});

  @override
  Widget build(BuildContext context) {
    return const fastway_logo.FastwayLogoFallback(
      ratio: fastway_logo.FallbackRatio.wide16x9,
    );
  }
}

// ── Banner text overlay ───────────────────────────────────────────────────────
class _BannerText extends StatelessWidget {
  final BannerEntity banner;
  const _BannerText({super.key, required this.banner});

  @override
  Widget build(BuildContext context) {
    final isWeb = isWebLayout(context);
    final locale = Localizations.localeOf(context).languageCode;
    final title = locale == 'ar' ? banner.titleAr : banner.title;
    if (title.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [

        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: isWeb ? 28 : 16,
            fontWeight: FontWeight.w800,
            height: 1.2,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 8,
              )
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Simple static dots — no per-frame AnimationController ────────────────────
class _StaticDotsBar extends StatelessWidget {
  final int count;
  final int current;

  const _StaticDotsBar({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

// ── Navigation arrow ──────────────────────────────────────────────────────────
class _NavArrow extends StatelessWidget {
  final bool isLeft;
  final bool isVisible;
  final VoidCallback onTap;

  const _NavArrow({
    required this.isLeft,
    required this.isVisible,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: Align(
        alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                  )
                ],
              ),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Icon(
                  isLeft
                      ? Icons.arrow_back_ios_new_rounded
                      : Icons.arrow_forward_ios_rounded,
                  color: Colors.black,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Placeholder shimmer banner ────────────────────────────────────────────────
class _PlaceholderBanner extends StatelessWidget {
  final double height;
  final bool isWeb;
  const _PlaceholderBanner({required this.height, required this.isWeb});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLightThemeWeb = isWeb && !isDark;

    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: isLightThemeWeb ? const Color(0xFFF5F5F5) : null,
          gradient: isLightThemeWeb
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.image_outlined,
                size: 48,
                color: isLightThemeWeb ? Colors.black12 : Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'Fastway',
                style: TextStyle(
                  color: isLightThemeWeb ? Colors.black12 : Colors.white.withValues(alpha: 0.5),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}