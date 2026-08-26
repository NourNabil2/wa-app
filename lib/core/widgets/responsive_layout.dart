// lib/core/utils/responsive_layout.dart
import 'package:flutter/material.dart';

/// Breakpoints matching common web/desktop design patterns
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double wideDesktop = 1600;
}

/// Returns true when running on a "web-like" wide screen
bool isWebLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= Breakpoints.tablet;

bool isMobileLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width < Breakpoints.mobile;

bool isTabletLayout(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return w >= Breakpoints.mobile && w < Breakpoints.tablet;
}

/// Adaptive value helper
T adaptive<T>(BuildContext context, {required T mobile, T? tablet, required T desktop}) {
  final w = MediaQuery.sizeOf(context).width;
  if (w >= Breakpoints.tablet) return desktop;
  if (w >= Breakpoints.mobile && tablet != null) return tablet;
  return mobile;
}