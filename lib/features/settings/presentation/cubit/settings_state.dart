// lib/features/settings/presentation/cubit/settings_state.dart
part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final Locale locale;
  final bool isBiometricLockEnabled;
  final bool isBiometricLoginEnabled;

  const SettingsState({
    required this.themeMode,
    required this.locale,
    required this.isBiometricLockEnabled,
    required this.isBiometricLoginEnabled,
  });

  factory SettingsState.initial() => const SettingsState(
    themeMode: ThemeMode.system,
    locale: Locale('ar'),
    isBiometricLockEnabled: false,
    isBiometricLoginEnabled: false,
  );

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? isBiometricLockEnabled,
    bool? isBiometricLoginEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      isBiometricLockEnabled: isBiometricLockEnabled ?? this.isBiometricLockEnabled,
      isBiometricLoginEnabled: isBiometricLoginEnabled ?? this.isBiometricLoginEnabled,
    );
  }

  @override
  List<Object?> get props => [themeMode, locale, isBiometricLockEnabled, isBiometricLoginEnabled];
}