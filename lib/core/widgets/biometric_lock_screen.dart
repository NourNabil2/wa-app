import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../features/user_data/user_cubit.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../theme/colors.dart';

class BiometricLockScreen extends StatefulWidget {
  final Widget child;

  const BiometricLockScreen({super.key, required this.child});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> with WidgetsBindingObserver {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isLocked = false;
  bool _isAuthenticating = false;

  bool _wasLoggedIn = false;
  bool _wasBiometricEnabled = false;

  static bool _initialStartDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial check on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialStartDone) {
        _checkLockStatus(initialStart: true);
        _initialStartDone = true;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLockStatus(initialStart: false);
    } else if (state == AppLifecycleState.paused) {
      _lockAppIfNeeded();
    }
  }

  void _lockAppIfNeeded() {
    if (kIsWeb) return;

    _wasLoggedIn = context.read<UserCubit>().isLoggedIn;
    _wasBiometricEnabled = context.read<SettingsCubit>().state.isBiometricLockEnabled;

    if (_wasLoggedIn && _wasBiometricEnabled) {
      setState(() => _isLocked = true);
    }
  }

  void _checkLockStatus({required bool initialStart}) {
    if (kIsWeb) return;

    final isLoggedIn = context.read<UserCubit>().isLoggedIn;
    final isEnabled = context.read<SettingsCubit>().state.isBiometricLockEnabled;

    if (!isLoggedIn || !isEnabled) {
      if (_isLocked) {
        setState(() => _isLocked = false);
      }
      return;
    }

    if (initialStart) {
      setState(() => _isLocked = true);
    }

    if (_isLocked && !_isAuthenticating) {
      if (initialStart) {
        // Delaying auth on initial app startup ensures the native splash screen
        // is fully dismissed before the OS modal blocks the main thread.
        // Otherwise, it can freeze on a white screen or the launch screen.
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _isLocked) _authenticate();
        });
      } else {
        _authenticate();
      }
    }
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
    });

    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: 'biometric.auth_reason'.tr(),
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows device PIN fallback
        ),
      );
    } on PlatformException catch (e) {
      debugPrint("Biometric Auth Error: $e");
    }

    if (!mounted) return;

    if (authenticated) {
      setState(() {
        _isLocked = false;
      });
    }

    setState(() {
      _isAuthenticating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (_isLocked)
          Positioned.fill(
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Directionality(
                textDirection: context.locale.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 80,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'biometric.auth_reason'.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _authenticate,
                        icon: const Icon(Icons.fingerprint),
                        label: Text('biometric.unlock'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorsManager.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
