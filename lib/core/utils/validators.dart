import 'package:easy_localization/easy_localization.dart';

class Validators {
  // ── Auth ──────────────────────────────────────────────────

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) return 'validation.nameRequired'.tr();
    if (value.trim().length < 2) return 'validation.nameTooShort'.tr();
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'validation.emailRequired'.tr();
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'validation.emailInvalid'.tr();
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'validation.phoneRequired'.tr();
    if (!RegExp(r'^\+?[\d\s-]{7,15}$').hasMatch(value.trim())) {
      return 'validation.phoneInvalid'.tr();
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'validation.passwordRequired'.tr();
    if (value.length < 6) return 'validation.passwordMinLength'.tr();
    return null;
  }

  static String? Function(String?) validateConfirmPassword(
      String? Function() getPassword) {
    return (value) {
      if (value != getPassword()) return 'validation.passwordMismatch'.tr();
      return null;
    };
  }

  // ── General ───────────────────────────────────────────────

  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) return 'Age is required';
    final age = int.tryParse(value);
    if (age == null || age < 1 || age > 100) return 'Please enter a valid age';
    return null;
  }

  static String? validateTeamName(String? value) {
    if (value == null || value.isEmpty) return 'Team name is required';
    if (value.length < 3) return 'Team name must be at least 3 characters';
    return null;
  }
}