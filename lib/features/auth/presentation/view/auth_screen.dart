// lib/features/auth/presentation/view/auth_screen.dart
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/responsive/responsive_layout.dart';
import 'package:fastway/core/utils/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/routes/routes.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWeb = isWebLayout(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
      body: isWeb ? _WebLayout(isDark: isDark) : _MobileLayout(isDark: isDark),
    );
  }
}

// ── Web ───────────────────────────────────────────────────────────────────────

class _WebLayout extends StatelessWidget {
  final bool isDark;
  const _WebLayout({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo header
              Image.asset(Assets.logoApp, height: 80, fit: BoxFit.contain),
              const SizedBox(height: 16),
              Text(
                'Fastway',
                style: TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.w900, 
                  color: isDark ? Colors.white : ColorsManager.primaryColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),
              _AuthCard(isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mobile ────────────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final bool isDark;
  const _MobileLayout({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(Assets.logoApp, height: 56.r, fit: BoxFit.contain),
            SizedBox(height: 32.h),

            _AuthCard(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ── Shared card ───────────────────────────────────────────────────────────────

class _AuthCard extends StatelessWidget {
  final bool isDark;
  const _AuthCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isWeb = isWebLayout(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'auth.visitorTitle'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isWeb ? 26 : 22.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : ColorsManager.surfaceDarkElevated,
            letterSpacing: -0.4,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: isWeb ? 6 : 6.h),
        Text(
          'auth.visitorSubtitle'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isWeb ? 13 : 13.sp,
            color: Colors.grey.shade500,
            height: 1.5,
          ),
          maxLines: 5,
          overflow: TextOverflow.visible,
        ),

        SizedBox(height: isWeb ? 36 : 36.h),

        // Create account
        SizedBox(
          width: double.infinity,
          height: isWeb ? 48 : 50.h,
          child: ElevatedButton(
            onPressed: () => AppNavigator.pushNamed(context, Routes.signup),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.primary2Color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'auth.createAccount'.tr(),
              style: TextStyle(
                  fontSize: isWeb ? 14 : 14.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        SizedBox(height: isWeb ? 10 : 10.h),

        // Login
        SizedBox(
          width: double.infinity,
          height: isWeb ? 48 : 50.h,
          child: OutlinedButton(
            onPressed: () => AppNavigator.pushNamed(context, Routes.login),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.1)),
              foregroundColor: isDark ? Colors.white : ColorsManager.surfaceDarkElevated,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'auth.login'.tr(),
              style: TextStyle(
                  fontSize: isWeb ? 14 : 14.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ),


      ],
    );
  }
}