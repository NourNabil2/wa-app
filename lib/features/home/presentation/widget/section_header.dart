// lib/features/home/presentation/widget/section_header.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final EdgeInsets? padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),


          if (actionLabel != null || onActionTap != null)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onActionTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel ?? 'home.seeAll'.tr(),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: ColorsManager.primaryColor,
                        decoration: TextDecoration.underline,
                        decorationColor: ColorsManager.primaryColor,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Icon(
                      // يفضل استخدام auto_direction أو Icon يقلب مع اللغة
                      Icons.arrow_forward_ios_rounded,
                      size: 14.r,
                      color: ColorsManager.primaryColor,
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}