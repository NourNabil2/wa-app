// lib/core/routes/app_navigator.dart
//
// Single entry point for all navigation.
// On web: updates the browser URL bar via history.pushState.
// On mobile: standard Navigator.pushNamed (no-op for URL).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppNavigator {
  /// Navigate to [routeName] and sync the browser URL on web.
  /// Use this instead of `Navigator.pushNamed(context, routeName)` everywhere.
  static Future<T?> pushNamed<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {

    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  /// Navigate and remove all previous routes (e.g. after login).
  static Future<T?> pushNamedAndRemoveAll<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {

    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      (_) => false,
      arguments: arguments,
    );
  }

  /// Replace the current route (e.g. splash → dashboard).
  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {

    return Navigator.pushReplacementNamed<T, TO>(
      context,
      routeName,
      arguments: arguments,
    );
  }
}
