// ============================================
// AUTH TITLE - Simplified Animation
// lib/features/auth/presentation/widgets/auth_title.dart
// ============================================

import 'package:flutter/material.dart';

class AuthTitle extends StatelessWidget {
  final bool isLogin;

  const AuthTitle({
    super.key,
    required this.isLogin,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: Column(
        key: ValueKey(isLogin),
        children: [
          Text(
            isLogin ? 'Welcome Back' : 'Create Account',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLogin
                ? 'Sign in to continue'
                : 'Fill your details to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
