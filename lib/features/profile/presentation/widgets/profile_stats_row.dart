// lib/features/profile/presentation/widgets/profile_stats_row.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/colors.dart';

import '../../../../core/routes/app_navigator.dart';
import '../../../../core/routes/routes.dart';

class ProfileStatsRow extends StatelessWidget {
  final int totalOrders;
  final int rewardPoints;
  final VoidCallback onPointsTap;
  const ProfileStatsRow(
      {super.key,
      required this.totalOrders,
      required this.rewardPoints,
      required this.onPointsTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: _RichStatCard(
              svgIcon: 'assets/icons/cart-icons-nav.svg',
              iconColor: ColorsManager.primaryColor,
              bgColor: ColorsManager.primaryColor.withValues(alpha: 0.1),
              label: 'profile.total_orders'.tr(),
              value: '$totalOrders',
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: GestureDetector(
              onTap: () => AppNavigator.pushNamed(context, Routes.points),
              child: _RichStatCard(
                icon: Icons.stars_rounded,
                iconColor: ColorsManager.primaryColor,
                bgColor: ColorsManager.primaryColor.withValues(alpha: 0.1),
                label: 'profile.reward_points'.tr(),
                value: '$rewardPoints',
                isTappable: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RichStatCard extends StatelessWidget {
  final IconData? icon;
  final String? svgIcon;
  final Color iconColor, bgColor;
  final String label, value;
  final bool isTappable;

  const _RichStatCard({
    this.icon,
    this.svgIcon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.value,
    this.isTappable = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // 👈 التعديل هنا
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.1), width: 1),
        // BoxShadow removed
      ),
      child: Row(
        children: [
          if (svgIcon != null)
            SvgPicture.asset(svgIcon!, width: 26.r, height: 26.r, colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn))
          else if (icon != null)
            Icon(icon, color: iconColor, size: 26.r),
          SizedBox(width: 12.w),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
            SizedBox(height: 3.h),
            Text(value,
                style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w300,
                    color: cs.onSurface)), // 👈 التعديل هنا
          ]),
          if (isTappable) ...[
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13.r, color: iconColor.withValues(alpha: 0.7)),
          ],
        ],
      ),
    );
  }
}
