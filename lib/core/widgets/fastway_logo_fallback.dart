import 'package:flutter/material.dart';
import 'package:fastway/core/utils/assets.dart';

enum FallbackRatio {
  square,
  wide16x9,
  banner10x3,
}

class FastwayLogoFallback extends StatelessWidget {
  final double? width;
  final double? height;
  final FallbackRatio ratio;

  const FastwayLogoFallback({
    super.key, 
    this.width, 
    this.height,
    this.ratio = FallbackRatio.square,
  });

  @override
  Widget build(BuildContext context) {
    String assetPath;
    switch (ratio) {
      case FallbackRatio.wide16x9:
        assetPath = Assets.fallback16x9;
        break;
      case FallbackRatio.banner10x3:
        assetPath = Assets.fallback10x3;
        break;
      case FallbackRatio.square:
      default:
        assetPath = Assets.fallback1x1;
        break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      child: Image.asset(
        assetPath,
        fit: BoxFit.cover,
      ),
    );
  }
}
