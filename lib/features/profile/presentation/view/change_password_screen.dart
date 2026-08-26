import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/layout/simple_web_shell.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/widgets/app_buton.dart';
import 'package:fastway/core/widgets/app_text_feild.dart';
import 'package:fastway/core/widgets/custom_snack_bar.dart';
import 'package:fastway/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:fastway/features/profile/presentation/cubit/profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/widgets/web_breadcrumb.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
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
    return BlocListener<ProfileCubit, ProfileState>(
      listenWhen: (_, state) => state is ProfileError || state is ProfileLoaded,
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
      child: kIsWeb ? _buildWeb(context) : _buildMobile(context),
    );
  }

  // ── Mobile ──────────────────────────────────────────────────────────────────

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'profile.security'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'profile.security'.tr(),
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 24.h),
              Text('profile.passwords.current'.tr(),
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600)),
              SizedBox(height: 8.h),
              AppTextField(
                controller: _oldPasswordController,
                hintText: 'profile.passwords.current'.tr(),
                obscureText: true,
                prefixIcon: Icon(Icons.lock_outline,
                    color: Colors.grey.shade400, size: 20.r),
                validator: (val) => val == null || val.isEmpty
                    ? 'validation.required'.tr()
                    : null,
              ),
              SizedBox(height: 20.h),
              Text('profile.passwords.new'.tr(),
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600)),
              SizedBox(height: 8.h),
              AppTextField(
                controller: _newPasswordController,
                hintText: 'profile.passwords.new'.tr(),
                obscureText: true,
                prefixIcon: Icon(Icons.lock_reset,
                    color: Colors.grey.shade400, size: 20.r),
                validator: (val) => val == null || val.length < 6
                    ? 'validation.min_6'.tr()
                    : null,
              ),
              const Spacer(),
              BlocBuilder<ProfileCubit, ProfileState>(
                builder: (context, state) => AppButton(
                  text: 'profile.pass_update'.tr(),
                  onPressed:
                      state is ProfileLoading ? null : _handleChangePassword,
                  isLoading: state is ProfileLoading,
                  borderRadius: 12,
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  // ── Web ─────────────────────────────────────────────────────────────────────

  Widget _buildWeb(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SimpleWebShell(
      content: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WebBreadcrumb(
                  isDark: isDark,
                  labels: ['dashboard.home'.tr(), 'footer.account'.tr(), 'profile.security'.tr()],
                  onTaps: [
                    () => AppNavigator.pushNamed(context, Routes.dashBoard),
                    () => AppNavigator.pushNamed(context, Routes.profile),
                    null,
                  ],
                ),
                const SizedBox(height: 16),
                // ── Page header ───────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:
                            ColorsManager.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: const Icon(Icons.lock_outline_rounded,
                          color: ColorsManager.primaryColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'profile.security'.tr(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0D0D14),
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                // ── Form card ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                    // BoxShadow removed
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('profile.passwords.current'.tr(),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _oldPasswordController,
                          hintText: 'profile.passwords.current'.tr(),
                          obscureText: true,
                          prefixIcon: Icon(Icons.lock_outline,
                              color: Colors.grey.shade400, size: 20),
                          validator: (val) => val == null || val.isEmpty
                              ? 'validation.required'.tr()
                              : null,
                        ),
                        const SizedBox(height: 20),
                        Text('profile.passwords.new'.tr(),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _newPasswordController,
                          hintText: 'profile.passwords.new'.tr(),
                          obscureText: true,
                          prefixIcon: Icon(Icons.lock_reset,
                              color: Colors.grey.shade400, size: 20),
                          validator: (val) => val == null || val.length < 6
                              ? 'validation.min_6'.tr()
                              : null,
                        ),
                        const SizedBox(height: 28),
                        BlocBuilder<ProfileCubit, ProfileState>(
                          builder: (context, state) => AppButton(
                            text: 'profile.pass_update'.tr(),
                            onPressed: state is ProfileLoading
                                ? null
                                : _handleChangePassword,
                            isLoading: state is ProfileLoading,
                            horizontalPadding: 0,
                            verticalPadding: 0,
                            borderRadius: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
