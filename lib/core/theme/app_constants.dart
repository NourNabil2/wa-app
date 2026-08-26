import 'package:flutter/material.dart';

class AppConstants {
  // Radius
  static const BorderRadius radiusNone = BorderRadius.zero;
  static const BorderRadius radiusSm   = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMd   = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusLg   = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(999));

  // Spacing
  static const double spaceXS = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXL = 32.0;

  // Max widths
  static const double maxWidthContent  = 800.0;
  static const double maxWidthDesktop  = 1160.0;
  static const double breakpointMobile = 768.0;
  static const double breakpointTablet = 900.0;
}
