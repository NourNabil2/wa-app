// lib/features/auth/presentation/view/login_screen.dart
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
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../../core/db/shared_pref_helper.dart';
import '../../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../../../core/routes/routes.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/app_buton.dart';
import '../../../../../core/widgets/app_text_feild.dart';
import '../../../../../core/widgets/custom_snack_bar.dart';
import '../../../../../features/wishlist/presentation/cubit/wishlist_cubit.dart';
import '../../../../../features/cart/presentation/cubit/cart_cubit.dart';
import '../country_code_picker.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  bool _hasBiometricCredentials = false;
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkBiometricCredentials();
  }

  Future<void> _checkBiometricCredentials() async {
    final creds = await SharedPrefHelper.getLoginCredentials();
    if (creds != null && mounted) {
      setState(() {
        _hasBiometricCredentials = true;
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    bool authenticated = false;
    try {
      authenticated = await _auth.authenticate(
        localizedReason: 'biometric.login_auth_reason'.tr(),
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      debugPrint("Biometric Auth Error: $e");
    }

    if (!mounted) return;
    if (authenticated) {
      context.read<AuthCubit>().loginWithBiometric();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      final phone = buildInternationalPhone(_phoneController.text.trim());
      context.read<AuthCubit>().loginWithPassword(
        phone,
        _passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWeb = isWebLayout(context);

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (_, s) =>
      s is AuthFailure || s is LoginSuccess || s is AccountNotVerified,
      listener: (context, state) {
        if (state is AuthFailure) {
          CustomSnackBar.show(context,
              message: state.message, type: SnackBarType.error);
        } else if (state is LoginSuccess) {
          Navigator.pushNamedAndRemoveUntil(
              context, Routes.dashBoard, (_) => false);
        } else if (state is AccountNotVerified) {
          AppNavigator.pushNamed(context, Routes.verification,
              arguments: state.email);
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
            'auth.login'.tr(),
            style: TextStyle(
              fontSize: isWeb ? 32 : 28.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : ColorsManager.surfaceDarkElevated,
              letterSpacing: -0.4,
            ),
          ),
          SizedBox(height: isWeb ? 6 : 4.h),
          // ── Back-link to OTP login ──────────────────────────────
          GestureDetector(
            onTap: () => AppNavigator.pushReplacementNamed(context, Routes.login),
            child: Text(
              '← ${'auth.sendOtpWhatsapp'.tr()}',
              style: TextStyle(
                fontSize: isWeb ? 13 : 12.sp,
                color: ColorsManager.primaryColor,
                decoration: TextDecoration.underline,
                decorationColor: ColorsManager.primaryColor,
              ),
            ),
          ),
          SizedBox(height: isWeb ? 8 : 6.h),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'auth.noAccount'.tr(),
                style: TextStyle(
                  fontSize: isWeb ? 14 : 13.sp,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () =>
                    AppNavigator.pushReplacementNamed(context, Routes.signup),
                child: Text(
                  'auth.createAccount'.tr(),
                  style: TextStyle(
                    fontSize: isWeb ? 14 : 13.sp,
                    fontWeight: FontWeight.w600,
                    color: ColorsManager.primaryColor,
                    decoration: TextDecoration.underline,
                    decorationColor: ColorsManager.primaryColor,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isWeb ? 40 : 32.h),

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
              borderRadius: 50,
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
            borderRadius: 50,
          ),

          SizedBox(height: isWeb ? 40 : 40.h),

          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              return AppButton(
                text: 'auth.login'.tr(),
                onPressed: state is AuthLoading ? null : _handleLogin,
                isLoading: state is AuthLoading,
                horizontalPadding: 0,
                verticalPadding: isWeb ? 16 : 0, // زرار أعرض للويب
                borderRadius: 50,
              );
            },
          ),
          
          BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, settingsState) {
              if (settingsState.isBiometricLoginEnabled && _hasBiometricCredentials && !kIsWeb) {
                return Padding(
                  padding: EdgeInsets.only(top: 16.h),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _handleBiometricLogin,
                      icon: const Icon(Icons.fingerprint, color: ColorsManager.primaryColor),
                      label: Text(
                        'biometric.login_button_title'.tr(),
                        style: TextStyle(
                          color: ColorsManager.primaryColor,
                          fontSize: isWeb ? 16 : 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 14.h),
                        side: const BorderSide(color: ColorsManager.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),


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