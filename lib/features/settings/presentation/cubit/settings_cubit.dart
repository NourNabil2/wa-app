// lib/features/settings/presentation/cubit/settings_cubit.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/db/shared_pref_helper.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  static const _themeKey = 'theme_mode';

  /// SharedPreferences key holding the app language ('ar' | 'en').
  ///
  /// Public because it is the single source of truth for the language outside the
  /// widget tree: main() reads it as EasyLocalization's startLocale, and the Dio
  /// interceptor sends it as Accept-Language. Do not confuse it with
  /// AppConstants.languageKey / languageCode — nothing writes those.
  static const String langKey = 'language';

  SettingsCubit() : super(SettingsState.initial());

  // ── Boot ──────────────────────────────────────────────────────────────
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString(_themeKey) ?? 'system';
    final lang  = prefs.getString(langKey)  ?? 'ar';
    // Backwards compatibility for old biometric_enabled key mapping to lock
    final bioLock = prefs.getBool('biometric_enabled') ?? prefs.getBool('biometric_lock_enabled') ?? false;
    final bioLogin = prefs.getBool('biometric_login_enabled') ?? false;
    emit(SettingsState(
      themeMode: _toThemeMode(theme),
      locale: Locale(lang),
      isBiometricLockEnabled: bioLock,
      isBiometricLoginEnabled: bioLogin,
    ));
  }

  // ── Theme ─────────────────────────────────────────────────────────────
  Future<void> setTheme(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, value);
    emit(state.copyWith(themeMode: _toThemeMode(value)));
  }

  // ── Language ──────────────────────────────────────────────────────────
  /// Must also call context.setLocale() for EasyLocalization to update
  /// translated strings. Call this from the widget layer where context
  /// is available, THEN call this method for MaterialApp locale.
  Future<void> setLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(langKey, langCode);
    emit(state.copyWith(locale: Locale(langCode)));
  }

  // ── Biometric ─────────────────────────────────────────────────────────
  Future<void> setBiometricLockEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_lock_enabled', isEnabled);
    await prefs.setBool('biometric_enabled', isEnabled); // for backward compatibility
    emit(state.copyWith(isBiometricLockEnabled: isEnabled));
  }

  Future<void> setBiometricLoginEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_login_enabled', isEnabled);
    emit(state.copyWith(isBiometricLoginEnabled: isEnabled));
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  ThemeMode _toThemeMode(String v) {
    switch (v) {
      case 'dark':   return ThemeMode.dark;
      case 'light':  return ThemeMode.light;
      default:       return ThemeMode.system;
    }
  }
}