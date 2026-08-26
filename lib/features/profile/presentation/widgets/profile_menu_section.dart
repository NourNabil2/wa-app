// lib/features/profile/presentation/widgets/profile_menu_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/colors.dart';

class ProfileMenuItem {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  const ProfileMenuItem(
      {required this.icon,
      required this.label,
      this.subtitle,
      this.trailing,
      required this.onTap});
}

class ProfileMenuSection extends StatelessWidget {
  final String title;
  final List<ProfileMenuItem> items;
  const ProfileMenuSection(
      {super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 12.w, right: 12.w, bottom: 8.h),
            child: Text(title,
                style: TextStyle(
                    fontSize: 13.sp,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.bold)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: items.map(
                  (item) => _MenuItem(item: item, isLast: items.last == item)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final ProfileMenuItem item;
  final bool isLast;
  const _MenuItem({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
            leading: Icon(item.icon, size: 22.r, color: ColorsManager.primary2Color),
            title: Text(item.label,
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
            subtitle: item.subtitle != null
                ? Text(item.subtitle!,
                    style: TextStyle(
                        fontSize: 11.sp,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7)))
                : null,
            trailing: item.trailing ??
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                  size: 22.r,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
            onTap: item.onTap,
          ),
        ),
        if (!isLast)
          Divider(
              height: 1,
              indent: 68.w,
              endIndent: 16.w,
              color: cs.outlineVariant.withValues(alpha: 0.3)),
      ],
    );
  }
}
