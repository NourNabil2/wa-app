// lib/features/auth/presentation/view/phone_login_screen.dart
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
import '../../../../core/db/shared_pref_helper.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_buton.dart';
import '../../../../core/widgets/app_text_feild.dart';
import '../../../../core/widgets/custom_snack_bar.dart';
import '../widget/country_code_picker.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../wishlist/presentation/cubit/wishlist_cubit.dart';
class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

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
    super.dispose();
  }

  void _handleSendOtp() {
    if (_formKey.currentState!.validate()) {
      final phone = buildInternationalPhone(_phoneController.text.trim());
      context.read<AuthCubit>().requestOtp(phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWeb = isWebLayout(context);

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (_, s) => s is OtpSent || s is AuthFailure || s is LoginSuccess,
      listener: (context, state) {
        if (state is OtpSent) {
          AppNavigator.pushNamed(
            context,
            Routes.verification,
            arguments: {'phone': state.phone, 'debugOtp': state.debugOtp},
          );
        } else if (state is AuthFailure) {
          CustomSnackBar.show(context,
              message: state.message, type: SnackBarType.error);
        } else if (state is LoginSuccess) {
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
        final brandH = isNarrow ? 140.0 : 210.0;

        return SingleChildScrollView(
          child: Column(
            children: [
              // Removed brand banner
              // ── Form ─────────────────────────────────────────────────
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () =>
                      AppNavigator.pushReplacementNamed(context, Routes.signup),
                  child: Text(
                    'auth.createAccount'.tr(),
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



          Text(
            'auth.phone'.tr(),
            style: TextStyle(
              fontSize: isWeb ? 14 : 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
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

          SizedBox(height: isWeb ? 40 : 40.h),

          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              return AppButton(
                text: 'auth.sendOtpWhatsapp'.tr(),
                onPressed: state is AuthLoading ? null : _handleSendOtp,
                isLoading: state is AuthLoading,
                backgroundColor: ColorsManager.primary2Color,
                horizontalPadding: 0,
                verticalPadding: isWeb ? 16 : 0,
                borderRadius: 12,
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
                      icon: const Icon(Icons.fingerprint, color: ColorsManager.primary2Color),
                      label: Text(
                        'biometric.login_button_title'.tr(),
                        style: TextStyle(
                          color: ColorsManager.primary2Color,
                          fontSize: isWeb ? 16 : 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 14.h),
                        side: const BorderSide(color: ColorsManager.primary2Color),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          SizedBox(height: isWeb ? 16 : 12.h),

          // ── Password fallback link ────────────────────────────────
          Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: TextButton(
                onPressed: () =>
                    AppNavigator.pushNamed(context, Routes.passwordLogin),
                child: Text(
                  'auth.loginWithPassword'.tr(),
                  style: TextStyle(
                    fontSize: isWeb ? 14 : 13.sp,
                    color: Colors.grey.shade600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),


        ],
      ),
    );
  }
}
