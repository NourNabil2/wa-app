// lib/core/widgets/loyalty_points_bar.dart
//
// Unified loyalty-points indicator used on Product Details and Cart pages.
// Design language: minimal, professional — inspired by Amazon/Noon reward bars.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fastway/core/theme/colors.dart';

/// A slim, professional loyalty-points bar.
///
/// Renders a left-accent strip with a points icon, descriptive text, and
/// a numeric badge on the trailing edge. Works in both light and dark modes.
///
/// [title]    — primary label, e.g. "Earn 2,073 points with this purchase"
/// [subtitle] — secondary hint, e.g. "Use points to pay on your next order"
/// [points]   — raw integer shown in the trailing badge (e.g. 2073)
class LoyaltyPointsBar extends StatefulWidget {
  final int points;
  final String? titleOverride;
  final String? subtitleOverride;

  /// The customer's tier bonus percentage (e.g. 10 for +10%).
  ///
  /// [points] ALREADY includes this bonus — the chip exists so the customer can
  /// see WHY the number is higher, not to add anything to it.
  final double? bonusPercent;

  const LoyaltyPointsBar({
    super.key,
    required this.points,
    this.titleOverride,
    this.subtitleOverride,
    this.bonusPercent,
  });

  @override
  State<LoyaltyPointsBar> createState() => _LoyaltyPointsBarState();
}

class _LoyaltyPointsBarState extends State<LoyaltyPointsBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _startShineLoop();
  }

  void _startShineLoop() async {
    // Wait for the initial count-up animation to finish, then shine
    await Future.delayed(const Duration(milliseconds: 1500));
    while (mounted) {
      if (mounted) await _shineController.forward(from: 0.0);
      if (mounted) await Future.delayed(const Duration(seconds: 4)); // Pause between shines
    }
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points <= 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primary = ColorsManager.primaryColor;

    // ── Colours ──
    const accentBar = primary;
    final bgColor = isDark
        ? ColorsManager.surfaceDarkCard
        : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final badgeText = isDark ? primary : const Color(0xFF047857);

    final title = widget.titleOverride ??
        'product.earnPoints'.tr(namedArgs: {'points': _fmt(widget.points)});
    final subtitle = widget.subtitleOverride ?? 'product.use_points_hint'.tr();

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Content ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.stars_rounded, color: primary, size: 28),
                        ),
                        const SizedBox(width: 12),

                        // Text block
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: titleColor,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                  // Tier bonus chip. The points figure already
                                  // includes the bonus; this just explains why.
                                  if ((widget.bonusPercent ?? 0) > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: badgeText.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        'points.bonus_points_badge'.tr(args: [
                                          widget.bonusPercent! % 1 == 0
                                              ? widget.bonusPercent!.toStringAsFixed(0)
                                              : widget.bonusPercent!.toStringAsFixed(1),
                                        ]),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: badgeText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: subtitleColor,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Animated Points badge
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: TweenAnimationBuilder<int>(
                            tween: IntTween(begin: 0, end: widget.points),
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.easeOutExpo,
                            builder: (context, value, child) {
                              return Text(
                                '+${_fmt(value)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: badgeText,
                                  letterSpacing: 0.3,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Shine Effect Overlay ──
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _shineController,
                builder: (context, child) {
                  // Translate from far right to far left for RTL
                  final dx = Directionality.of(context) == TextDirection.RTL
                      ? 1.5 - (_shineController.value * 3.0)
                      : -1.5 + (_shineController.value * 3.0);
                  return FractionalTranslation(
                    translation: Offset(dx, 0),
                    child: FractionalTranslation(
                      translation: const Offset(0, -0.5),
                      child: Transform.rotate(
                        angle: 0.4,
                        child: Container(
                          width: 80,
                          height: 1000,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primary.withValues(alpha: 0.0),
                                primary.withValues(alpha: isDark ? 0.02 : 0.04),
                                primary.withValues(alpha: isDark ? 0.08 : 0.12),
                                primary.withValues(alpha: isDark ? 0.02 : 0.04),
                                primary.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Format number with comma separators (1234 → "1,234").
  static String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
