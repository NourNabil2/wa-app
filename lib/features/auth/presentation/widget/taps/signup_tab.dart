// lib/features/auth/presentation/view/signup_screen.dart
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:fastway/core/responsive/responsive_layout.dart';
import 'package:fastway/core/utils/assets.dart';
import 'package:fastway/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fastway/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/routes/routes.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/app_buton.dart';
import '../../../../../core/widgets/app_text_feild.dart';
import '../../../../../core/widgets/custom_snack_bar.dart';
import '../../../../../features/wishlist/presentation/cubit/wishlist_cubit.dart';
import '../../../../../features/cart/presentation/cubit/cart_cubit.dart';
import '../country_code_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _termsAccepted = false;
  bool _policyAccepted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignup() {
    if (!_termsAccepted) {
      CustomSnackBar.show(context, message: 'auth.accept_terms_error'.tr(), type: SnackBarType.error);
      return;
    }
    if (!_policyAccepted) {
      CustomSnackBar.show(context, message: 'auth.accept_policy_error'.tr(), type: SnackBarType.error);
      return;
    }
    if (_formKey.currentState!.validate()) {
      final phone = buildInternationalPhone(_phoneController.text.trim());
      context.read<AuthCubit>().signup(
        name: _nameController.text.trim(),
        phone: phone,
        password: _passwordController.text.trim(),
        email: '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWeb = isWebLayout(context);

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (_, s) =>
      s is AuthFailure || s is SignupSuccess || s is AuthAuthenticated || s is LoginSuccess,
      listener: (context, state) {
        if (state is AuthFailure) {
          CustomSnackBar.show(context,
              message: state.message, type: SnackBarType.error);
        } else if (state is SignupSuccess) {
          AppNavigator.pushNamed(context, Routes.verification,
              arguments: state.email);
        } else if (state is AuthAuthenticated || state is LoginSuccess) {
          Navigator.pushNamedAndRemoveUntil(
              context, Routes.dashBoard, (_) => false);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        body: isWeb
            ? _buildWebBody(context, isDark)
            : _buildMobileBody(context, isDark),
      ),
    );
  }

  Widget _buildWebBody(BuildContext context, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        final brandH  = isNarrow ? 140.0 : 210.0;

        return SingleChildScrollView(
          child: Column(
            children: [
              // Removed brand banner

              // ── Form below ───────────────────────────────────────────
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isNarrow ? 24 : 48,
                      vertical: 40,
                    ),
                    child: _buildForm(context, isDark, isWeb: true),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildMobileBody(BuildContext context, bool isDark) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: _buildForm(context, isDark, isWeb: false),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isDark, {required bool isWeb}) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // 👈 التوسيط العمودي هنا
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // 👈 عشان الـ Column ياخد مساحة المحتوى بس
        children: [
          Center(
            child: Image.asset(
              Assets.logoApp,
              height: isWeb ? 80 : 60.h,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: isWeb ? 40 : 32.h),
          Text(
            'auth.createAccount'.tr(),
            style: TextStyle(
              fontSize: isWeb ? 32 : 28.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : ColorsManager.surfaceDarkElevated,
              letterSpacing: -0.4,
            ),
          ),
          SizedBox(height: isWeb ? 8 : 6.h),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'auth.hasAccount'.tr(),
                style: TextStyle(
                  fontSize: isWeb ? 14 : 13.sp,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 4),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () =>
                      AppNavigator.pushReplacementNamed(context, Routes.login),
                  child: Text(
                    'auth.login'.tr(),
                    style: TextStyle(
                      fontSize: isWeb ? 14 : 13.sp,
                      fontWeight: FontWeight.w600,
                      color: ColorsManager.primary2Color,
                      decoration: TextDecoration.underline,
                      decorationColor: ColorsManager.primary2Color,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isWeb ? 40 : 32.h),

          _FieldLabel(label: 'auth.fullName'.tr(), isWeb: isWeb),
          SizedBox(height: isWeb ? 10 : 8.h),
          AppTextField(
            controller: _nameController,
            hintText: 'John Doe',
            prefixIcon: Icon(Icons.person_outline,
                color: Colors.grey.shade400, size: isWeb ? 20 : 20.r),
            validator: Validators.validateName,
            borderRadius: 12,
          ),

          SizedBox(height: isWeb ? 20 : 16.h),

          _FieldLabel(label: 'auth.phone'.tr(), isWeb: isWeb),
          SizedBox(height: isWeb ? 10 : 8.h),
          Directionality(
            textDirection: TextDirection.ltr,
            child: AppTextField(
              controller: _phoneController,
              hintText: '5xxxxxxxx',
              keyboardType: TextInputType.phone,
              prefixIcon: CountryCodePicker(isDark: isDark),
              validator: Validators.validatePhone,
              borderRadius: 12,
              textAlign: TextAlign.left,
            ),
          ),

          SizedBox(height: isWeb ? 20 : 16.h),

          _FieldLabel(label: 'auth.password'.tr(), isWeb: isWeb),
          SizedBox(height: isWeb ? 10 : 8.h),
          AppTextField(
            controller: _passwordController,
            hintText: '********',
            obscureText: _obscurePassword,
            prefixIcon: Icon(Icons.lock_outline,
                color: Colors.grey.shade400, size: isWeb ? 20 : 20.r),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.grey.shade400,
                size: isWeb ? 20 : 20.r,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: Validators.validatePassword,
            borderRadius: 12,
          ),

          SizedBox(height: isWeb ? 16 : 16.h),

          // ── Terms & Privacy Checkboxes ─────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _termsAccepted,
                  onChanged: (val) => setState(() => _termsAccepted = val ?? false),
                  activeColor: ColorsManager.primary2Color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => launchUrl(Uri.parse('https://web.fastwayprotein.com/terms'), mode: LaunchMode.inAppWebView),
                    child: Text(
                      'auth.agree_terms'.tr(),
                      style: TextStyle(
                        fontSize: isWeb ? 13 : 13.sp,
                        color: ColorsManager.primary2Color,
                        decoration: TextDecoration.underline,
                        decorationColor: ColorsManager.primary2Color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isWeb ? 12 : 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _policyAccepted,
                  onChanged: (val) => setState(() => _policyAccepted = val ?? false),
                  activeColor: ColorsManager.primary2Color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => launchUrl(Uri.parse('https://web.fastwayprotein.com/privacy'), mode: LaunchMode.inAppWebView),
                    child: Text(
                      'auth.agree_policy'.tr(),
                      style: TextStyle(
                        fontSize: isWeb ? 13 : 13.sp,
                        color: ColorsManager.primary2Color,
                        decoration: TextDecoration.underline,
                        decorationColor: ColorsManager.primary2Color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isWeb ? 40 : 40.h),

          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              return AppButton(
                text: 'auth.createAccount'.tr(),
                onPressed: state is AuthLoading ? null : _handleSignup,
                isLoading: state is AuthLoading,
                backgroundColor: ColorsManager.primary2Color,
                horizontalPadding: 0,
                verticalPadding: isWeb ? 16 : 0,
                borderRadius: 12,
              );
            },
          ),



          SizedBox(height: isWeb ? 0 : 16.h),

          if (!isWeb)
            Center(
              child: Text(
                'auth.termsAgreement'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11.sp, color: Colors.grey.shade400),
              ),
            ),

          SizedBox(height: isWeb ? 0 : 32.h),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool isWeb;
  const _FieldLabel({required this.label, this.isWeb = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: isWeb ? 14 : 13.sp,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
      ),
    );
  }
}