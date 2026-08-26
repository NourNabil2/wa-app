// lib/features/auth/presentation/pages/otp_verification_page.dart
// ============================================
import 'dart:async';
import 'package:fastway/core/widgets/CustomIcon.dart';
import 'package:fastway/core/widgets/custom_app_bar.dart';
import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/responsive/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:fastway/core/widgets/app_buton.dart';
import 'package:fastway/core/widgets/custom_snack_bar.dart';
import 'package:fastway/core/routes/routes.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/utils/assets.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../../../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../../../../features/wishlist/presentation/cubit/wishlist_cubit.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phone;

  /// Testing-only: when the server returns the OTP (admin toggle + APP_DEBUG),
  /// the boxes are auto-filled and a hint is shown.
  final String? debugOtp;

  const OtpVerificationPage({super.key, required this.phone, this.debugOtp});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  static const int _otpLength = 6;
  static const int _countdownSeconds = 60;

  final List<TextEditingController> _controllers =
  List.generate(_otpLength, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
  List.generate(_otpLength, (_) => FocusNode());

  // ── Countdown timer for resend ──────────────────────────────────
  Timer? _countdownTimer;
  int _secondsRemaining = _countdownSeconds;
  bool get _canResend => _secondsRemaining == 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _autoFillDebugOtp();
  }

  /// Testing-only: prefill the boxes from a server-provided debug OTP.
  void _autoFillDebugOtp() {
    final code = widget.debugOtp;
    if (code == null || code.length != _otpLength) return;
    for (var i = 0; i < _otpLength; i++) {
      _controllers[i].text = code[i];
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsRemaining = _countdownSeconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  bool get _isOtpComplete => _otpCode.length == _otpLength;

  void _onDigitEntered(int index, String value) {
    if (value.length == 1 && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _handleVerify() {
    if (!_isOtpComplete) return;
    context.read<AuthCubit>().verifyOtp(
      phone: widget.phone,
      otp: _otpCode,
    );
  }

  /// BUG-67 FIX: Wire resend OTP with countdown timer
  void _handleResend() {
    if (!_canResend) return;
    context.read<AuthCubit>().resendOtp(phone: widget.phone);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (_, current) =>
      current is OtpFailure ||
      current is OtpResent ||
          current is AuthAuthenticated, // BUG-68 FIX: removed LoginSuccess
      listener: (context, state) {
        if (state is OtpFailure) {
          CustomSnackBar.show(
            context,
            message: state.message,
            type: SnackBarType.error,
          );
        } else if (state is OtpResent) {
          // BUG-67 FIX: OTP resent successfully — show success + restart countdown
          CustomSnackBar.show(
            context,
            message: 'auth.otp.resent'.tr(),
            type: SnackBarType.success,
          );
          _startCountdown();
        } else if (state is AuthAuthenticated) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.dashBoard,
                (_) => false,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is OtpLoading;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isWeb = isWebLayout(context);

        final content = _buildContent(context, isLoading);

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
          appBar: isWeb ? null : CustomAppBar(
            title: 'auth.otp.title'.tr(),
            isTransparent: true,
          ),
          body: isWeb
              ? _buildWebBody(context, content)
              : SafeArea(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: content,
                  ),
                ),
        );
      },
    );
  }

  // ── Web layout: brand banner on top + width-constrained card ──────────────
  Widget _buildWebBody(BuildContext context, Widget content) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        final brandH = isNarrow ? 140.0 : 210.0;

        return SingleChildScrollView(
          child: Column(
            children: [
              // Removed brand banner
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isNarrow ? 24 : 48,
                      vertical: 40,
                    ),
                    child: content,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Shared form content (used by both web & mobile) ───────────────────────
  Widget _buildContent(BuildContext context, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Image.asset(
            Assets.logoApp,
            height: 60,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 32),
        _OtpHeader(phone: widget.phone),
        if (widget.debugOtp != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade400),
            ),
            child: Text(
              '🧪 Test mode — OTP: ${widget.debugOtp}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade900,
              ),
            ),
          ),
        ],
        const SizedBox(height: 40),
        _OtpInputRow(
          controllers: _controllers,
          focusNodes: _focusNodes,
          onChanged: _onDigitEntered,
          onKeyEvent: _onKeyEvent,
        ),
        const SizedBox(height: 36),
        AppButton(
          text: 'auth.otp.verify'.tr(),
          onPressed: (isLoading || !_isOtpComplete) ? null : _handleVerify,
          isLoading: isLoading,
          horizontalPadding: 0,
          verticalPadding: 0,
          borderRadius: 12,
          backgroundColor: ColorsManager.primary2Color,
        ),
        const SizedBox(height: 20),
        _ResendRow(
          onResend: (isLoading || !_canResend) ? null : _handleResend,
          secondsRemaining: _secondsRemaining,
        ),
        const SizedBox(height: 16),
        // Password fallback link
        TextButton(
          onPressed: () =>
              Navigator.pushReplacementNamed(context, Routes.passwordLogin),
          child: Text(
            'auth.loginWithPassword'.tr(),
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w300,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Sub-Widgets ────────────────────────────────────────────────────────────

class _OtpHeader extends StatelessWidget {
  final String phone;

  const _OtpHeader({required this.phone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CustomIcon(
          assetPath: Assets.verifiedIcon,
          size: AppSizeVertical.instance.s70,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'auth.otp.headline'.tr(),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'auth.otp.whatsappSubtitle'.tr(namedArgs: {'phone': phone}),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _OtpInputRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;
  final void Function(int index, KeyEvent event) onKeyEvent;

  const _OtpInputRow({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Directionality لضمان إن الخانات دايماً من شمال لين
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(controllers.length, (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _OtpDigitField(
                controller: controllers[index],
                focusNode: focusNodes[index],
                onChanged: (value) => onChanged(index, value),
                onKeyEvent: (event) => onKeyEvent(index, event),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _OtpDigitField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  const _OtpDigitField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  State<_OtpDigitField> createState() => _OtpDigitFieldState();
}

class _OtpDigitFieldState extends State<_OtpDigitField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFocused = widget.focusNode.hasFocus;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: widget.onKeyEvent,
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        textDirection: TextDirection.ltr,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: widget.onChanged,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: isFocused
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : Colors.grey.shade50,
        ),
      ),
    );
  }
}

class _ResendRow extends StatelessWidget {
  final VoidCallback? onResend;
  final int secondsRemaining;

  const _ResendRow({required this.onResend, required this.secondsRemaining});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canResend = secondsRemaining == 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'auth.otp.noCode'.tr(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        if (canResend)
          TextButton(
            onPressed: onResend,
            child: Text(
              'auth.otp.resend'.tr(),
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Text(
              '${'auth.otp.resendIn'.tr()} ${secondsRemaining}s',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ),
      ],
    );
  }
}