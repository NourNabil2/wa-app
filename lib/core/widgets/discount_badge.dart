import 'package:flutter/material.dart';

class DiscountBadge extends StatelessWidget {
  final int percent;
  final double scale;

  const DiscountBadge({
    super.key,
    required this.percent,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final double fontSize = (12.0 * scale).clamp(9.0, 16.0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (6.0 * scale).clamp(4.0, 8.0),
        vertical: (4.0 * scale).clamp(3.0, 6.0),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEF5350).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        widthFactor: 1.0,
        heightFactor: 1.0,
        child: Text(
          '$percent%',
          textAlign: TextAlign.center,
          strutStyle: StrutStyle(
            fontSize: fontSize,
            height: 1.0,
            leading: 0,
            forceStrutHeight: true,
          ),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFEF5350),
            height: 1.0,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      ),
    );
  }
}
