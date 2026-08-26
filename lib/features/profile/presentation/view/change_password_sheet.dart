import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/widgets/app_buton.dart';
import 'package:fastway/core/widgets/app_text_feild.dart';
import 'package:fastway/core/widgets/custom_snack_bar.dart';
import 'package:fastway/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:fastway/features/profile/presentation/cubit/profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key});

  static void show(BuildContext context) {
    final profileCubit = context.read<ProfileCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: profileCubit,
        child: const ChangePasswordSheet(),
      ),
    );
  }

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showOld = false, _showNew = false, _showConfirm = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleChangePassword() {
    if (_formKey.currentState!.validate()) {
      context.read<ProfileCubit>().changePassword(
            _oldPasswordController.text.trim(),
            _newPasswordController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bg = isDark ? const Color(0xFF161618) : Colors.white;

    return BlocListener<ProfileCubit, ProfileState>(
      listenWhen: (_, s) => s is ProfileError || s is ProfileLoaded,
      listener: (context, state) {
        if (state is ProfileError) {
          CustomSnackBar.show(context,
              message: state.message, type: SnackBarType.error);
        } else if (state is ProfileLoaded) {
          CustomSnackBar.show(context,
              message: 'Password changed successfully.',
              type: SnackBarType.success);
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(0, 0, 0, bottomInset),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.zero),
          // BoxShadow removed — blur:32 on sheet open
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ─────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.zero),
              ),

              // ── Premium header with gradient icon ───────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF2196F3),
                            ColorsManager.primaryColor
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.zero,
                        // BoxShadow removed from icon badge
                      ),
                      child: const Icon(Icons.lock_reset_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('profile.pass_title'.tr(),
                                style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1A1A1A))),
                            Text('profile.pass_subtitle'.tr(),
                                style: TextStyle(
                                    fontSize: 11.sp,
                                    color: isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[500])),
                          ]),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 18,
                            color:
                                isDark ? Colors.grey[300] : Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.shade100),
              const SizedBox(height: 24),

              // ── Fields ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(
                        label: 'profile.pass_current'.tr(), isDark: isDark),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _oldPasswordController,
                      hintText: 'profile.passwords.current'.tr(),
                      obscureText: !_showOld,
                      prefixIcon: Icon(Icons.lock_outline_rounded,
                          color:
                              ColorsManager.primaryColor.withValues(alpha: 0.7),
                          size: 20.r),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _showOld
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: Colors.grey[400]),
                        onPressed: () => setState(() => _showOld = !_showOld),
                      ),
                      validator: (val) => (val == null || val.isEmpty)
                          ? 'Old password is required'
                          : null,
                    ),
                    SizedBox(height: 20.h),

                    _FieldLabel(label: 'profile.pass_new'.tr(), isDark: isDark),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _newPasswordController,
                      hintText: 'profile.passwords.new'.tr(),
                      obscureText: !_showNew,
                      prefixIcon: Icon(Icons.lock_open_rounded,
                          color:
                              ColorsManager.primaryColor.withValues(alpha: 0.7),
                          size: 20.r),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _showNew
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: Colors.grey[400]),
                        onPressed: () => setState(() => _showNew = !_showNew),
                      ),
                      validator: (val) => (val == null || val.length < 6)
                          ? 'Min 6 characters'
                          : null,
                    ),
                    SizedBox(height: 20.h),

                    _FieldLabel(
                        label: 'profile.pass_confirm'.tr(), isDark: isDark),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _confirmController,
                      hintText: 'Confirm new password',
                      obscureText: !_showConfirm,
                      prefixIcon: Icon(Icons.verified_outlined,
                          color:
                              ColorsManager.primaryColor.withValues(alpha: 0.7),
                          size: 20.r),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _showConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: Colors.grey[400]),
                        onPressed: () =>
                            setState(() => _showConfirm = !_showConfirm),
                      ),
                      validator: (val) => val != _newPasswordController.text
                          ? 'Passwords do not match'
                          : null,
                    ),

                    SizedBox(height: 32.h),

                    // Password strength hint
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            ColorsManager.primaryColor.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Row(children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16,
                            color: ColorsManager.primaryColor
                                .withValues(alpha: 0.8)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                'Use 8+ characters, with a mix of letters, numbers & symbols.',
                                style: TextStyle(
                                    fontSize: 11.sp,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.grey[600]))),
                      ]),
                    ),

                    SizedBox(height: 24.h),

                    BlocBuilder<ProfileCubit, ProfileState>(
                      builder: (context, state) => AppButton(
                        text: 'profile.pass_update'.tr(),
                        onPressed: state is ProfileLoading
                            ? null
                            : _handleChangePassword,
                        isLoading: state is ProfileLoading,
                        borderRadius: 14,
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _FieldLabel({required this.label, required this.isDark});
  @override
  Widget build(BuildContext context) => Text(label,
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.grey[300] : Colors.grey[700]));
}
