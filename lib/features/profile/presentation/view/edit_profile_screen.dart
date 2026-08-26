// lib/features/profile/presentation/view/edit_profile_screen.dart
//
// MOBILE REDESIGN:
//   • Gradient hero header with avatar + name
//   • Fields grouped in section cards with hairline dividers (no heavy borders)
//   • Save button pinned to bottom bar outside the scroll
//   • Web layout preserved unchanged

import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/widgets/app_buton.dart';
import 'package:fastway/core/layout/simple_web_shell.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/widgets/custom_snack_bar.dart';
import '../../domain/entities/profile_entity.dart';
import '../widgets/profile_field_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/routes/app_navigator.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/widgets/web_breadcrumb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/profile_cubit.dart';

class EditProfileScreen extends StatefulWidget {
  final ProfileEntity profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _emailController = TextEditingController(text: widget.profile.email);
    _phoneController = TextEditingController(text: widget.profile.phone ?? '');
    _dobController = TextEditingController(text: '05/15/1995');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final String name = _nameController.text.trim();
    final String phone = _phoneController.text.trim();
    
    await context.read<ProfileCubit>().updateProfile(
      name: name.isNotEmpty ? name : null,
      phone: phone.isNotEmpty ? phone : null,
    );
    
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      CustomSnackBar.show(context,
          message: 'profile.save_success'.tr(), type: SnackBarType.success);
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 5, 15),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: ColorsManager.primaryColor,
                onPrimary: Colors.white,
              ),
          textTheme: ThemeData.light().textTheme.apply(
                fontFamily: Theme.of(ctx).textTheme.bodyMedium?.fontFamily,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dobController.text =
          '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebLayout(context);
    }
    return _buildMobileLayout(context);
  }

  // ── Mobile ─────────────────────────────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: Text('profile.personal_data'.tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: isDark ? Colors.white : Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [

          // Scrollable form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 8.h),
              child: Column(
                children: [
                  // ── Personal info card ──────────────────────────
                  _SectionCard(
                    title: 'profile.personalInfo'.tr(),
                    icon: Icons.person_outline_rounded,
                    isDark: isDark,
                    children: [
                      _FieldRow(
                        icon: Icons.badge_outlined,
                        label: 'profile.name'.tr(),
                        controller: _nameController,
                        isDark: isDark,
                      ),
                      _FieldRow(
                        icon: Icons.email_outlined,
                        label: 'profile.email'.tr(),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        isDark: isDark,
                        readOnly: true,
                      ),
                      _FieldRow(
                        icon: Icons.phone_outlined,
                        label: 'profile.phone'.tr(),
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        isDark: isDark,
                        readOnly: true,
                      ),
                      _FieldRow(
                        icon: Icons.calendar_month_outlined,
                        label: 'profile.dob'.tr(),
                        controller: _dobController,
                        readOnly: true,
                        onTap: () => _pickDate(context),
                        isDark: isDark,
                        trailingIcon: Icons.chevron_left_rounded,
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),

          // Pinned save button
          Container(
            padding: EdgeInsets.fromLTRB(
                16.w, 12.h, 16.w, MediaQuery.paddingOf(context).bottom + 12.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              // BoxShadow removed from save bar
            ),
            child: AppButton(
              text: 'profile.save_changes'.tr(),
              isLoading: _isSaving,
              backgroundColor: ColorsManager.primary2Color,
              horizontalPadding: 0,
              verticalPadding: 0,
              borderRadius: 14,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }

  // ── Web (unchanged) ─────────────────────────────────────────────────────────

  Widget _buildWebLayout(BuildContext context) {
    return SimpleWebShell(
      content: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              WebBreadcrumb(
                isDark: Theme.of(context).brightness == Brightness.dark,
                labels: ['dashboard.home'.tr(), 'footer.account'.tr(), 'profile.personal_data'.tr()],
                onTaps: [
                  () => AppNavigator.pushNamed(context, Routes.dashBoard),
                  () => AppNavigator.pushNamed(context, Routes.profile),
                  null,
                ],
              ),
              const SizedBox(height: 16),
              // ── Page header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ColorsManager.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: const Icon(Icons.person_outline_rounded,
                        color: ColorsManager.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'profile.personal_data'.tr(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),
              ProfileFieldTile(
                  icon: Icons.person_outline_rounded,
                  label: 'profile.name'.tr(),
                  controller: _nameController,
                  keyboardType: TextInputType.name),
              SizedBox(height: 12.h),
              ProfileFieldTile(
                  icon: Icons.email_outlined,
                  label: 'profile.email'.tr(),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress),
              SizedBox(height: 12.h),
              ProfileFieldTile(
                  icon: Icons.phone_outlined,
                  label: 'profile.phone'.tr(),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone),
              SizedBox(height: 12.h),
              ProfileFieldTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'profile.dob'.tr(),
                  controller: _dobController,
                  readOnly: true,
                  onTap: () => _pickDate(context)),
              SizedBox(height: 28.h),
              AppButton(
                  text: 'profile.save_changes'.tr(),
                  isLoading: _isSaving,
                  backgroundColor: ColorsManager.primary2Color,
                  horizontalPadding: 0,
                  verticalPadding: 0,
                  onPressed: _save),
              SizedBox(height: 40.h),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOBILE-ONLY WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final List<Widget> children;
  const _SectionCard(
      {required this.title,
      required this.icon,
      required this.isDark,
      required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 4.w, bottom: 8.h),
          child: Row(
            children: [
              Icon(icon, size: 14.r, color: ColorsManager.primary2Color),
              SizedBox(width: 5.w),
              Text(title,
                  style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: ColorsManager.primary2Color,
                      letterSpacing: 0.2)),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final IconData? trailingIcon;
  final bool isDark;

  const _FieldRow({
    required this.icon,
    required this.label,
    this.hint,
    required this.controller,
    required this.isDark,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          Container(
            width: 34.r,
            height: 34.r,
            alignment: Alignment.center,
            child: Icon(icon, size: 20.r, color: ColorsManager.primary2Color),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11.sp,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500)),
                SizedBox(height: 2.h),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  readOnly: readOnly,
                  onTap: onTap,
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle:
                        TextStyle(fontSize: 13.sp, color: cs.onSurfaceVariant),
                    border: (readOnly && onTap == null) ? InputBorder.none : UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12)),
                    focusedBorder: (readOnly && onTap == null) ? InputBorder.none : const UnderlineInputBorder(borderSide: BorderSide(color: ColorsManager.primary2Color, width: 1.5)),
                    enabledBorder: (readOnly && onTap == null) ? InputBorder.none : UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12)),
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    filled: false,
                    fillColor: Colors.transparent,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                  ),
                ),
              ],
            ),
          ),
          if (trailingIcon != null) ...[
            SizedBox(width: 6.w),
            Icon(trailingIcon, size: 18.r, color: cs.onSurfaceVariant),
          ],
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  final bool isDark;
  const _RowDivider({required this.isDark});

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 0.5,
        indent: 62.w,
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06),
      );
}



// ═══════════════════════════════════════════════════════════════════════════════
// WEB-ONLY WIDGETS (unchanged)
// ═══════════════════════════════════════════════════════════════════════════════

class _AvatarPicker extends StatelessWidget {
  final String initials;
  const _AvatarPicker({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      CircleAvatar(
        radius: 44.r,
        backgroundColor: ColorsManager.primaryColor,
        child: Text(initials,
            style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
      SizedBox(height: 8.h),
      Text('profile.change_avatar'.tr(),
          style: TextStyle(
              fontSize: 13.sp,
              color: ColorsManager.primaryColor,
              fontWeight: FontWeight.w500)),
    ]);
  }
}

