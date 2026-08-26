// lib/features/auth/presentation/widget/country_code_picker.dart
//
// KSA-only phone prefix. The dial code is FIXED to Saudi Arabia (+966) — there
// is no country dropdown. The phone number sent to the backend is always the
// international form 966XXXXXXXXX (leading 0 stripped, no '+').
import 'package:flutter/material.dart';

/// Fixed Saudi Arabia dial code (without '+').
const String kSaudiDialCode = '966';

/// A static, non-interactive "+966 🇸🇦" prefix for the phone field.
/// Mirrors the look of the old picker but with no tap / no sheet.
class CountryCodePicker extends StatelessWidget {
  final bool isDark;

  const CountryCodePicker({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🇸🇦', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Text(
            '+$kSaudiDialCode',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// Normalise a user-entered Saudi national number into the international form
/// the backend expects: 966 + number, leading 0 stripped, no '+'.
/// e.g. "0501234567" → "966501234567", "501234567" → "966501234567".
String buildInternationalPhone(String rawNumber) {
  var digits = rawNumber.replaceAll(RegExp(r'\D'), '');
  // Strip a single leading 0 (national trunk prefix).
  if (digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  // If the user already typed the dial code, don't duplicate it.
  if (digits.startsWith(kSaudiDialCode)) {
    return digits;
  }
  return kSaudiDialCode + digits;
}
