import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/widgets/safe_mouse_region.dart';
// lib/features/product_details/presentation/widgets/product_image_gallery.dart

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductImageGallery extends StatefulWidget {
  final List<String> images;
  final bool isNew;
  final int? discountPercent;

  const ProductImageGallery({
    super.key,
    required this.images,
    this.isNew = false,
    this.discountPercent,
  });

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _autoPlayTimer;

  // ── إعدادات الـ Parallax للموبايل
  static const double _parallaxFactor = 0.35;
  static const double _overscaleFactor = 1.0 + _parallaxFactor;

  // ── متغيرات الاسترتش (Stretch-to-Open)
  double _startX = 0;
  double _startY = 0;
  double _stretchDelta = 0;
  bool _isDragging = false;
  bool _isFullScreenOpened = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 1.0,
      initialPage: 0,
    );
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
    if (widget.images.length <= 1) return;
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_currentIndex + 1) % widget.images.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 750),
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  void _stopAutoPlay() => _autoPlayTimer?.cancel();

  // ── منطق فتح الشاشة الكاملة
  void _openFullScreen(int index) async {
    if (_isFullScreenOpened) return;
    _isFullScreenOpened = true;

    await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false, // عشان الخلفية تبقى شفافة وتعمل أنيميشن ناعم
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: FullScreenGallery(
              images: widget.images,
              initialIndex: index,
            ),
          );
        },
      ),
    );

    if (mounted) {
      setState(() {
        _isFullScreenOpened = false;
        _stretchDelta = 0;
        _isDragging = false;
      });
    }
  }

  // ── منطق الاسترتش
  void _onPointerDown(PointerDownEvent event) {
    _startX = event.position.dx;
    _startY = event.position.dy;
    _isDragging = true;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (kIsWeb || _isFullScreenOpened) return;

    final dy = event.position.dy - _startY;
    final dx = (event.position.dx - _startX).abs();

    // نتأكد إن السحب لتحت (طولي) ومفيش سحب بالعرض
    if (dy > 0 && dy > dx * 1.5) {
      setState(() {
        _stretchDelta = dy;
      });

      // لو سحب مسافة كافية (140 بكسل)، نفتح الفول سكرين فوراً
      if (_stretchDelta > 140) {
        _openFullScreen(_currentIndex);
      }
    } else if (dy <= 0 && _stretchDelta > 0) {
      // لو بيسحب لفوق عشان يكمل سكرول الصفحة
      setState(() => _stretchDelta = 0);
    }
  }

  void _onPointerUp(PointerEvent event) {
    if (kIsWeb) return;
    setState(() {
      _isDragging = false;
      _stretchDelta = 0; // بيرجع لوضعه الطبيعي لو مسحبش للآخر
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.images.isEmpty) {
      return _EmptyState(isDark: isDark);
    }

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp, // في حالة الـ Scroll ألغى التاتش
      child: AnimatedScale(
        // معادلة الاسترتش (كل ما يسحب لتحت، الكارت يكبر لحد 25%)
        scale: 1.0 + (_stretchDelta / 400).clamp(0.0, 0.25),
        // لو بيسحب، الأنيميشن لحظي (0)، لو ساب صباعه بيرد بنعومة (300ms)
        duration: Duration(milliseconds: _isDragging ? 0 : 300),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter, // التمدد من فوق لتحت
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. Image Carousel ──
            SafeMouseRegion(
              onEnter: (_) => _stopAutoPlay(),
              onExit: (_) => _startAutoPlay(),
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                scrollBehavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                  },
                ),
                onPageChanged: (i) {
                  setState(() {
                    _currentIndex = i;
                  });
                  _startAutoPlay();
                },
                itemBuilder: (context, index) {
                  final imageUrl = widget.images[index];

                  if (kIsWeb) {
                    return GestureDetector(
                      onTap: () => _openFullScreen(index),
                      child: Hero(
                        tag: imageUrl,
                        child: imageUrl.startsWith('assets/')
                            ? Image.asset(
                                imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => _ErrorState(isDark: isDark),
                              )
                            : CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.contain,
                                errorWidget: (_, __, ___) => _ErrorState(isDark: isDark),
                              ),
                      ),
                    );
                  }

                  return GestureDetector(
                    onTap: () => _openFullScreen(index), // فتح بضغطة عادية برضو
                    child: Hero(
                      tag: imageUrl,
                      child: _MobileParallaxCard(
                        pageController: _pageController,
                        pageIndex: index,
                        imageUrl: imageUrl,
                        parallaxFactor: _parallaxFactor,
                        overscaleFactor: _overscaleFactor,
                        isDark: isDark,
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── 3. Dots indicator ──
            if (widget.images.length > 1)
              Positioned(
                bottom: 16, left: 0, right: 0,
                child: _DotsIndicator(count: widget.images.length, current: _currentIndex),
              ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// MOBILE PARALLAX CARD
// ════════════════════════════════════════════════════════════════════════════
class _MobileParallaxCard extends StatelessWidget {
  final PageController pageController;
  final int pageIndex;
  final String imageUrl;
  final double parallaxFactor;
  final double overscaleFactor;
  final bool isDark;

  const _MobileParallaxCard({
    required this.pageController,
    required this.pageIndex,
    required this.imageUrl,
    required this.parallaxFactor,
    required this.overscaleFactor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;

        return Container(
          color: isDark ? Colors.transparent : Colors.white,
          width: cardWidth,
          height: double.infinity,
          child: imageUrl.startsWith('assets/')
              ? Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _ErrorState(isDark: isDark),
                )
              : CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _ErrorState(isDark: isDark),
                ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// FULL SCREEN GALLERY (مع Swipe down to close)
// ════════════════════════════════════════════════════════════════════════════
class FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenGallery({super.key, required this.images, required this.initialIndex});

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;
  double _dragDy = 0; // لعمل تأثير سحب الصورة للأسفل لإغلاقها

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    // الخلفية بتشف لما تسحب الصورة لتحت
    final bgOpacity = (1.0 - (_dragDy.abs() / 300)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: bgOpacity),
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() {
            _dragDy += details.delta.dy;
          });
        },
        onVerticalDragEnd: (details) {
          // لو سحب بسرعة أو سحب مسافة كبيرة، يقفل الشاشة
          if (_dragDy.abs() > 100 || details.primaryVelocity!.abs() > 500) {
            Navigator.pop(context);
          } else {
            // لو ساب الصورة، ترد تاني لمكانها بـ Animation
            setState(() {
              _dragDy = 0;
            });
          }
        },
        child: Stack(
          children: [
            // الصور
            AnimatedContainer(
              duration: Duration(milliseconds: _dragDy == 0 ? 300 : 0),
              transform: Matrix4.translationValues(0, _dragDy, 0),
              curve: Curves.easeOutCubic,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Hero(
                      tag: widget.images[index], // نفس التاج عشان يربط الموبايل بالـ FullScreen
                      child: CachedNetworkImage(
                        imageUrl: widget.images[index],
                        fit: BoxFit.contain, // هنا الصورة بالكامل تظهر
                      ),
                    ),
                  );
                },
              ),
            ),

            // زرار الإغلاق
            Positioned(
              top: MediaQuery.paddingOf(context).top + 10,
              right: 16,
              child: AnimatedOpacity(
                opacity: _dragDy == 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),

            // مؤشر النقط
            if (widget.images.length > 1)
              Positioned(
                bottom: MediaQuery.paddingOf(context).bottom + 20,
                left: 0, right: 0,
                child: AnimatedOpacity(
                  opacity: _dragDy == 0 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: _DotsIndicator(count: widget.images.length, current: _currentIndex),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SMALL WIDGETS
// ════════════════════════════════════════════════════════════════════════════
class _BottomGradient extends StatelessWidget {
  const _BottomGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int current;
  const _DotsIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == current;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 6,
            width: isActive ? 16 : 6,
            decoration: BoxDecoration(
              color: isActive
                  ? ColorsManager.primaryColor
                  : ColorsManager.primaryColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF2C2C2E) : ColorsManager.gray100,
      child: Center(
        child: Icon(Icons.image_not_supported_outlined, size: 48, color: isDark ? Colors.grey[600] : Colors.grey[400]),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final bool isDark;
  const _ErrorState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF2C2C2E) : ColorsManager.gray100,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 36),
      ),
    );
  }
}