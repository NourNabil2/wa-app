// lib/features/profile/presentation/widgets/profile_theme_tile.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/colors.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';

class ProfileThemeTile extends StatelessWidget {
  final String currentTheme; // 'light' | 'dark' | 'system'
  final ValueChanged<String> onChanged;

  const ProfileThemeTile({
    super.key,
    required this.currentTheme,
    required this.onChanged,
  });

  String _label(BuildContext context) {
    switch (currentTheme) {
      case 'dark':
        return 'profile.theme.dark'.tr();
      case 'system':
        return 'profile.theme.system'.tr();
      default:
        return 'profile.theme.light'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GestureDetector(
        onTap: () => _showThemeSheet(context),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.chevron_left, size: 20.r, color: cs.onSurfaceVariant),
              const Spacer(),
              Text(
                _label(context),
                style: TextStyle(fontSize: 13.sp, color: cs.onSurfaceVariant),
              ),
              SizedBox(width: 8.w),
              Text(
                'profile.theme.label'.tr(),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface, // 👈 التعديل هنا
                ),
              ),
              SizedBox(width: 10.w),
              Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  color: ColorsManager.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.zero,
                ),
                child: Icon(Icons.wb_sunny_outlined,
                    size: 18.r, color: ColorsManager.primaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor, // 👈 الخلفية تتبع الثيم
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.zero),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.zero,
              ),
            ),
            Text(
              'profile.theme.choose'.tr(),
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface),
            ),
            SizedBox(height: 16.h),
            _ThemeOption(
              icon: Icons.wb_sunny_outlined,
              label: 'profile.theme.light'.tr(),
              value: 'light',
              selected: currentTheme == 'light',
              onTap: () {
                Navigator.pop(ctx);
                context.read<SettingsCubit>().setTheme('light');
                onChanged('light');
              },
            ),
            _ThemeOption(
              icon: Icons.nightlight_round,
              label: 'profile.theme.dark'.tr(),
              value: 'dark',
              selected: currentTheme == 'dark',
              onTap: () {
                Navigator.pop(ctx);
                context.read<SettingsCubit>().setTheme('dark');
                onChanged('dark');
              },
            ),
            _ThemeOption(
              icon: Icons.brightness_auto_outlined,
              label: 'profile.theme.system'.tr(),
              value: 'system',
              selected: currentTheme == 'system',
              onTap: () {
                Navigator.pop(ctx);
                context.read<SettingsCubit>().setTheme('system');
                onChanged('system');
              },
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      leading: Icon(icon,
          color: selected ? ColorsManager.primaryColor : cs.onSurfaceVariant),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected
              ? ColorsManager.primaryColor
              : cs.onSurface, // 👈 التعديل هنا
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle_rounded,
              color: ColorsManager.primaryColor, size: 20.r)
          : null,
    );
  }
}
