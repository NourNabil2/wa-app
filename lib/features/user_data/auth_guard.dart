// lib/core/guards/auth_guard.dart

import 'package:fastway/core/routes/app_navigator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/responsive/responsive_layout.dart';
import 'package:fastway/core/routes/app_routes.dart';
import 'package:fastway/features/user_data/user_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/routes/routes.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/app_size.dart';

class AuthGuard {
  static bool check(BuildContext context) {
    final isLoggedIn = context.read<UserCubit>().isLoggedIn;
    if (!isLoggedIn) {
      _showAuthRequiredDialog(context);
      return false;
    }
    return true;
  }

  static bool isGuest(BuildContext context) => !context.read<UserCubit>().isLoggedIn;

  static void _showAuthRequiredDialog(BuildContext context) {
    final hSize = AppSizeHorizontal.instance;
    final vSize = AppSizeVertical.instance;
    final isWeb = isWebLayout(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          // 🔥 التريكة هنا: تحديد عرض ثابت في الويب عشان ميبقاش عريض بزيادة
          constraints: BoxConstraints(maxWidth: isWeb ? 400 : 340),
          padding: EdgeInsets.all(hSize.s24),
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor, // 👈 بيقرأ من الثيم مباشرة
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            ),
            // BoxShadow removed from auth dialog
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Container
              Container(
                padding: EdgeInsets.all(hSize.s20),
                decoration: BoxDecoration(
                  color: ColorsManager.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_person_rounded,
                  size: hSize.s50,
                  color: ColorsManager.primaryColor,
                ),
              ),
              SizedBox(height: vSize.s20),
              Text(
                'auth.guard.title'.tr(),
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: hSize.s18,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: vSize.s12),
              Text(
                'auth.guard.body'.tr(),
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 5,
                overflow: TextOverflow.visible,
              ),
              SizedBox(height: vSize.s24),
              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    AppNavigator.pushNamed(AppRouter.navigatorKey.currentContext!, Routes.login);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: vSize.s14),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: Text('auth.guard.login'.tr()),
                ),
              ),
              SizedBox(height: vSize.s8),
              // Later Button
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'auth.guard.later'.tr(),
                  style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}