import 'package:fastway/core/routes/app_navigator.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/features/search/presentation/view/search_sheet.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MobileSearchBar extends StatelessWidget {
  const MobileSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GestureDetector(
        onTap: () => AppNavigator.pushNamed(context, Routes.search),
        child: Container(
          height: 52.h,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              width: 1,
            ),
            // BoxShadow removed — blur repaint on scroll
          ),
          child: Row(
            children: [
              SizedBox(width: 16.w),
              Icon(
                Icons.search_rounded,
                size: 22.r,
                color: ColorsManager.primaryColor,
              ),
              SizedBox(width: 12.w),

              Expanded(
                child: Text(
                  'home.search'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}