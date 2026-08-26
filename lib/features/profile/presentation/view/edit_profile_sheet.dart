import 'package:fastway/core/theme/colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fastway/core/widgets/app_buton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/widgets/custom_snack_bar.dart';
import '../../domain/entities/profile_entity.dart';
import '../cubit/profile_cubit.dart';

class EditProfileSheet extends StatefulWidget {
  final ProfileEntity profile;

  const EditProfileSheet({super.key, required this.profile});

  static void show(BuildContext context, ProfileEntity profile) {
    final profileCubit = context.read<ProfileCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: profileCubit,
        child: EditProfileSheet(profile: profile),
      ),
    );
  }

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  String _gender = 'male';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _emailController = TextEditingController(text: widget.profile.email);
    _phoneController = TextEditingController(text: widget.profile.phone ?? '');
    _dobController = TextEditingController(text: '05/15/1995');
    _addressController = TextEditingController();
    _heightController = TextEditingController(text: '170');
    _weightController = TextEditingController(text: '70');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _heightController.dispose();
    _weightController.dispose();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FB),
        borderRadius: const BorderRadius.vertical(top: Radius.zero),
        // BoxShadow removed — blur:32 on sheet open
      ),
      child: Column(
        children: [
          // ── Drag handle ────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.zero),
          ),

          // ── Gradient header banner ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0D1B2A), const Color(0xFF1A2D42)]
                    : [ColorsManager.primaryColor, const Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 3),
                        // BoxShadow removed from avatar
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(widget.profile.initials ?? '?',
                            style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                    ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('profile.edit_title'.tr(),
                            style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        Text(widget.profile.email ?? '',
                            style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.white.withValues(alpha: 0.75))),
                      ]),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 20, 16, bottomInset + 20),
              children: [
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
                    _RowDivider(isDark: isDark),
                    _FieldRow(
                      icon: Icons.email_outlined,
                      label: 'profile.email'.tr(),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      isDark: isDark,
                    ),
                    _RowDivider(isDark: isDark),
                    _FieldRow(
                      icon: Icons.phone_outlined,
                      label: 'profile.phone'.tr(),
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      isDark: isDark,
                    ),
                    _RowDivider(isDark: isDark),
                    _FieldRow(
                      icon: Icons.calendar_month_outlined,
                      label: 'profile.dob'.tr(),
                      controller: _dobController,
                      readOnly: true,
                      onTap: () => _pickDate(context),
                      isDark: isDark,
                      trailingIcon: Icons.chevron_left_rounded,
                    ),
                    _RowDivider(isDark: isDark),
                    _FieldRow(
                      icon: Icons.location_on_outlined,
                      label: 'profile.address'.tr(),
                      hint: 'profile.addressHint'.tr(),
                      controller: _addressController,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'profile.physicalInfo'.tr(),
                  icon: Icons.monitor_weight_outlined,
                  isDark: isDark,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatMiniField(
                              icon: Icons.straighten_rounded,
                              label: 'profile.height'.tr(),
                              unit: 'profile.unit.cm'.tr(),
                              controller: _heightController,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatMiniField(
                              icon: Icons.monitor_weight_outlined,
                              label: 'profile.weight'.tr(),
                              unit: 'profile.unit.kg'.tr(),
                              controller: _weightController,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _RowDivider(isDark: isDark),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: _GenderPills(
                        selected: _gender,
                        onChanged: (g) => setState(() => _gender = g),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Pinned save button
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.paddingOf(context).bottom + 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161618) : Colors.white,
              // BoxShadow removed from save bar
            ),
            child: AppButton(
              text: 'profile.save_changes'.tr(),
              isLoading: _isSaving,
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
}

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
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 14, color: ColorsManager.primaryColor),
              const SizedBox(width: 5),
              Text(title,
                  style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: ColorsManager.primaryColor,
                      letterSpacing: 0.2)),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? ColorsManager.surfaceDarkCard : const Color(0xFFF4F5F7),
            borderRadius: BorderRadius.zero,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.zero,
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
    required this.controller,
    required this.isDark,
    this.hint,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: ColorsManager.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(icon, size: 17, color: ColorsManager.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11.sp,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
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
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ],
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 6),
            Icon(trailingIcon, size: 18, color: cs.onSurfaceVariant),
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
        indent: 62,
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06),
      );
}

class _StatMiniField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String unit;
  final TextEditingController controller;
  final bool isDark;
  const _StatMiniField(
      {required this.icon,
      required this.label,
      required this.unit,
      required this.controller,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: ColorsManager.primaryColor),
              const SizedBox(width: 5),
              Text(label,
                  style:
                      TextStyle(fontSize: 11.sp, color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface),
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero),
                ),
              ),
              Text(unit,
                  style:
                      TextStyle(fontSize: 12.sp, color: cs.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenderPills extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final bool isDark;
  const _GenderPills(
      {required this.selected, required this.onChanged, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.wc_rounded,
                size: 13, color: ColorsManager.primaryColor),
            const SizedBox(width: 5),
            Text('profile.gender_label'.tr(),
                style: TextStyle(fontSize: 11.sp, color: cs.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _Pill(
                label: 'profile.gender.male'.tr(),
                icon: Icons.male_rounded,
                isSelected: selected == 'male',
                onTap: () => onChanged('male')),
            const SizedBox(width: 10),
            _Pill(
                label: 'profile.gender.female'.tr(),
                icon: Icons.female_rounded,
                isSelected: selected == 'female',
                onTap: () => onChanged('female')),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _Pill(
      {required this.label,
      required this.icon,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? ColorsManager.primaryColor
                : cs.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.zero,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected ? Colors.white : cs.onSurfaceVariant),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : cs.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
