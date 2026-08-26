// lib/features/profile/presentation/widgets/profile_logout_button.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/colors.dart';

class ProfileLogoutButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const ProfileLogoutButton({
    super.key,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SizedBox(
        width: double.infinity,
        height: 56.h,
        child: MouseRegion(
          cursor: isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: ElevatedButton(
            onPressed: isLoading ? null : onTap,
            style: ElevatedButton.styleFrom(
            backgroundColor: ColorsManager.errorSurface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 20.r,
                  height: 20.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(ColorsManager.errorFill),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'profile.logout'.tr(),
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: ColorsManager.errorFill,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.logout_rounded,
                      color: ColorsManager.errorFill,
                      size: 20.r,
                    ),
                  ],
                ),
        ),
      ),
      )
    );
  }
}
