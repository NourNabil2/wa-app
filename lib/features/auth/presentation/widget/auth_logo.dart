// ============================================
// AUTH LOGO - Simplified
// lib/features/auth/presentation/widgets/auth_logo.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:fastway/core/theme/colors.dart';

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: ColorsManager.primaryColor,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.medical_services_rounded,
        size: 36,
        color: Colors.white,
      ),
    );
  }
}
