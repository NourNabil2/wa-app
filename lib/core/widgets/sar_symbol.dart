// lib/core/widgets/sar_symbol.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fastway/core/utils/assets.dart';

/// Standalone Saudi Riyal symbol (SVG). Prefer [SarText] for inline price display.
class SarSymbol extends StatelessWidget {
  final double size;
  final Color? color;

  const SarSymbol({super.key, this.size = 14, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? DefaultTextStyle.of(context).style.color ?? Colors.black;
    return SvgPicture.asset(
      Assets.saudiRiyalSymbol,
      width: size * 1.5,
      height: size,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
    );
  }
}

/// Displays a price with the **official Saudi Riyal symbol** (U+20C1, Unicode 16.0)
/// rendered as a real text glyph — not an SVG — so Flutter's text engine handles
/// baseline alignment automatically.
///
/// The symbol uses the custom `SaudiRiyalSAR` font (0.7 KB, built from the
/// official SAMA SVG); the price number uses the app's standard Tajawal font.
/// Because both are [TextSpan]s in a single [Text.rich], they share the same
/// line-height metrics — no manual offsets needed.
///
/// Usage:
/// ```dart
/// SarText(price: '49.99')
/// SarText(price: '149.00', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))
/// ```
class SarText extends StatelessWidget {
  final String price;
  final TextStyle? style;

  /// When true the symbol appears before the number (default, per SAMA guidelines).
  final bool symbolFirst;

  /// When true, a strike-through line is drawn across the price digits only (not the ﷼ symbol).
  final bool strikeThrough;

  const SarText({
    super.key,
    required this.price,
    this.style,
    this.symbolFirst = true,
    this.strikeThrough = false,
  });

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style;
    final ts = style != null ? base.merge(style) : base;
    final fontSize = ts.fontSize ?? 14.0;
    final color = ts.color ?? Theme.of(context).colorScheme.onSurface;
    final effectiveStyle = ts.copyWith(color: color);

    // Symbol span
    final symbolSpan = TextSpan(
      text: '\u20C1',
      style: effectiveStyle.copyWith(
        fontFamily: 'SaudiRiyalSAR',
        package: null,
        fontSize: fontSize * 0.65,
        height: ts.height ?? 1.2,
      ),
    );

    // Price span (no decoration — we draw the line ourselves)
    final priceSpan = TextSpan(text: price, style: effectiveStyle);

    // Gap
    final gapSpan = TextSpan(text: '\u202F', style: effectiveStyle);

    final children = symbolFirst
        ? [symbolSpan, gapSpan, priceSpan]
        : [priceSpan, gapSpan, symbolSpan];

    final fullSpan = TextSpan(style: effectiveStyle, children: children);

    final textWidget = Text.rich(
      fullSpan,
      textDirection: TextDirection.ltr,
    );

    if (!strikeThrough) return textWidget;

    // ── Measure where the digits are so the line covers ONLY them ──

    // 1) Find the baseline → the Y center of digits = baseline - capHeight/2
    //    capHeight ≈ fontSize × 0.7 for most Latin fonts
    final fullTP = TextPainter(text: fullSpan, textDirection: TextDirection.ltr)
      ..layout();
    final baseline =
        fullTP.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final strikeY = (baseline ?? fullTP.height * 0.4) - fontSize * 0.3;

    // 2) Find horizontal span of the price digits
    double startX, endX;
    if (symbolFirst) {
      final prefixTP = TextPainter(
        text: TextSpan(style: effectiveStyle, children: [symbolSpan, gapSpan]),
        textDirection: TextDirection.ltr,
      )..layout();
      startX = prefixTP.width;
      prefixTP.dispose();
      endX = fullTP.width;
    } else {
      final priceTP = TextPainter(
        text: TextSpan(text: price, style: effectiveStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      startX = 0;
      endX = priceTP.width;
      priceTP.dispose();
    }

    fullTP.dispose();

    return CustomPaint(
      foregroundPainter: _DigitStrikePainter(
        color: color,
        startX: startX,
        endX: endX,
        y: strikeY,
      ),
      child: textWidget,
    );
  }
}

class _DigitStrikePainter extends CustomPainter {
  final Color color;
  final double startX, endX, y;

  _DigitStrikePainter({
    required this.color,
    required this.startX,
    required this.endX,
    required this.y,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
  }

  @override
  bool shouldRepaint(_DigitStrikePainter old) =>
      old.color != color ||
      old.startX != startX ||
      old.endX != endX ||
      old.y != y;
}
