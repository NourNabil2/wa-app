import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fastway/features/home/domain/entities/brand_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Palette of gradient pairs for the initials fallback — one per brand index.
const _kGradients = <List<Color>>[
  [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
  [Color(0xFFF59E0B), Color(0xFFEF4444)],
  [Color(0xFF10B981), Color(0xFF059669)],
  [Color(0xFFEC4899), Color(0xFFBE185D)],
  [Color(0xFF8B5CF6), Color(0xFF6366F1)],
  [Color(0xFF14B8A6), Color(0xFF0891B2)],
  [Color(0xFFF97316), Color(0xFFEF4444)],
];

/// Brands section — single horizontal scrollable row with arrow buttons
/// and mouse-drag scrolling — same logic as ProductsRow.
class BrandsRail extends StatefulWidget {
  final List<BrandEntity> brands;
  final void Function(BrandEntity)? onTap;
  final double? horizontalPadding;

  const BrandsRail({super.key, required this.brands, this.onTap, this.horizontalPadding});

  @override
  State<BrandsRail> createState() => _BrandsRailState();
}

class _BrandsRailState extends State<BrandsRail> {
  late final ScrollController _sc;

  bool _canScrollBack    = false;
  bool _canScrollForward = true;

  @override
  void initState() {
    super.initState();
    _sc = ScrollController();
    _sc.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!_sc.hasClients) return;
    final pos        = _sc.position;
    final canBack    = pos.pixels > 1;
    final canForward = pos.pixels < pos.maxScrollExtent - 1;
    if (canBack != _canScrollBack || canForward != _canScrollForward) {
      setState(() {
        _canScrollBack    = canBack;
        _canScrollForward = canForward;
      });
    }
  }

  @override
  void dispose() {
    _sc
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _scroll(double chipW, {required bool forward}) {
    if (!_sc.hasClients) return;
    final step   = (chipW + 14) * 3; // scroll 3 chips at a time
    final target = forward
        ? (_sc.offset + step).clamp(0.0, _sc.position.maxScrollExtent)
        : (_sc.offset - step).clamp(0.0, _sc.position.maxScrollExtent);
    _sc.animateTo(target,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.brands.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl  = Directionality.of(context) == TextDirection.rtl;

    const double circleOuter = 76.0; // outer ring diameter
    const double chipW       = circleOuter + 8; // total tap area per chip
    final double sidePad     = widget.horizontalPadding ?? 16.0;
    const double chipGap     = 14.0;

    // ── Arrow button builder — identical pattern to ProductsRow ──────────────
    Widget arrowBtn({required bool isLeftSlot}) {
      final isForward = isRtl ? isLeftSlot : !isLeftSlot;
      final show      = (isForward ? _canScrollForward : _canScrollBack) && kIsWeb;

      return AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: show ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: !show,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _scroll(chipW, forward: isForward),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Directionality(
                // Force LTR so Flutter doesn't auto-mirror icons in RTL
                textDirection: TextDirection.ltr,
                child: Icon(
                  isLeftSlot
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: const Color(0xFF0D8D63),
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: chipW,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // ── Scrollable chips — mouse + touch drag enabled ──────────────────
          Positioned.fill(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
              child: SingleChildScrollView(
                controller: _sc,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: sidePad),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(widget.brands.length, (i) {
                    final chip = _BrandChip(
                      brand: widget.brands[i],
                      index: i,
                      size: circleOuter - 8, // inner circle
                      onTap: widget.onTap != null
                          ? () => widget.onTap!(widget.brands[i])
                          : null,
                    );
                    if (i == widget.brands.length - 1) return chip;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [chip, const SizedBox(width: chipGap)],
                    );
                  }),
                ),
              ),
            ),
          ),

          // ── Left arrow ─────────────────────────────────────────────────────
          Positioned(
            left: -16,
            child: arrowBtn(isLeftSlot: true),
          ),

          // ── Right arrow ────────────────────────────────────────────────────
          Positioned(
            right: -16,
            child: arrowBtn(isLeftSlot: false),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Brand chip — circle with animated hover ring + transparent background
// ─────────────────────────────────────────────────────────────────────────────
class _BrandChip extends StatefulWidget {
  final BrandEntity brand;
  final int index;
  final double size;
  final VoidCallback? onTap;

  const _BrandChip({
    required this.brand,
    required this.index,
    required this.size,
    this.onTap,
  });

  @override
  State<_BrandChip> createState() => _BrandChipState();
}

class _BrandChipState extends State<_BrandChip> {
  bool _hovered = false;
  bool _pressed = false;

  String get _initials {
    final parts = widget.brand.name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    final name = parts[0];
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
  }

  List<Color> get _gradient => _kGradients[widget.index % _kGradients.length];

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final hasLogo    = widget.brand.logoUrl.isNotEmpty;
    final accentColor = _gradient[0];

    // Ring color: animates to accent on hover/press
    final Color ringColor;
    if (_pressed) {
      ringColor = accentColor.withValues(alpha: 0.85);
    } else if (_hovered) {
      ringColor = accentColor.withValues(alpha: 0.65);
    } else {
      ringColor = hasLogo
          ? (isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.grey.shade200)
          : accentColor.withValues(alpha: 0.35);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap:       widget.onTap,
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp:     (_) => setState(() => _pressed = false),
        onTapCancel: ()  => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width:  widget.size + 8,
          height: widget.size + 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: ringColor,
              width: (_hovered || _pressed) ? 2.5 : 2,
            ),
          ),
          padding: const EdgeInsets.all(3),
          child: AnimatedScale(
            scale: _pressed ? 0.92 : (_hovered ? 1.04 : 1.0),
            duration: const Duration(milliseconds: 150),
            child: hasLogo
                // ── Logo: bare SizedBox — zero background, truly transparent
                ? SizedBox(
                    width:  widget.size,
                    height: widget.size,
                    child: CachedNetworkImage(
                      imageUrl:       widget.brand.logoUrl,
                      width:          widget.size,
                      height:         widget.size,
                      memCacheWidth:  (widget.size * 2).toInt(),
                      memCacheHeight: (widget.size * 2).toInt(),
                      fadeInDuration:  Duration.zero,
                      fadeOutDuration: Duration.zero,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => _InitialsCircle(
                        initials: _initials,
                        gradient: _gradient,
                        size: widget.size,
                      ),
                      errorWidget: (_, __, ___) => _InitialsCircle(
                        initials: _initials,
                        gradient: _gradient,
                        size: widget.size,
                      ),
                    ),
                  )
                // ── Initials fallback: gradient circle ───────────────────────
                : Container(
                    width:  widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _gradient,
                        begin: Alignment.topLeft,
                        end:   Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _initials,
                        style: TextStyle(
                          fontSize:     widget.size * 0.32,
                          fontWeight:   FontWeight.w800,
                          color:        Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Fallback circle with gradient + initials (used on image load error too).
class _InitialsCircle extends StatelessWidget {
  final String      initials;
  final List<Color> gradient;
  final double      size;

  const _InitialsCircle({
    required this.initials,
    required this.gradient,
    required this.size,
  });

  @override
  Widget build(BuildContext context) => Container(
        width:  size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: gradient,
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              fontSize:   size * 0.3,
              fontWeight: FontWeight.w800,
              color:      Colors.white,
            ),
          ),
        ),
      );
}
