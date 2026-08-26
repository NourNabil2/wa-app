// lib/features/onboarding/presentation/widgets/page_indicator.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fastway/core/theme/colors.dart';

class PageIndicator extends StatelessWidget {
  final int count;
  final int current;

  const PageIndicator({
    super.key,
    required this.count,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.only(right: 6.w),
          // active: pill ممتد — inactive: دائرة صغيرة
          width:  isActive ? 16.w : 28.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: isActive
                ? ColorsManager.primary2Color
                : ColorsManager.secondaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}