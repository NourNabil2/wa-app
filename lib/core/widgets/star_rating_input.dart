// lib/core/widgets/star_rating_input.dart
//
// Reusable tap-to-rate 1–5 star input. RTL-safe (uses a Row, which follows
// the ambient text direction). Pass [value] (0 = unrated) and [onChanged].

import 'package:flutter/material.dart';

class StarRatingInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;
  final Color color;

  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 32,
    this.color = const Color(0xFFFBBF24),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = star <= value;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(star),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: filled ? color : Colors.grey.shade400,
            ),
          ),
        );
      }),
    );
  }
}
