// lib/features/profile/presentation/widgets/profile_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/utils/assets.dart';

class ProfileHeader extends StatelessWidget {
  final dynamic profile;
  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 20.h),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Logo ──────────────────────────────────────────────────
          Image.asset(
            Assets.logoApp,
            width: 120.w,
            height: 120.w,
          ),
          SizedBox(height: 16.h),
          // ── Name / Phone ──────────────────────────────────────────
          Text(profile.name ?? '',
              style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.2)),
          SizedBox(height: 8.h),
          Text(profile.phone ?? '',
              style: TextStyle(
                  fontSize: 16.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
