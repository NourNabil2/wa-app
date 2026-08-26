import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Clean breakpoint definitions matching web/desktop design patterns.
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double wideDesktop = 1600;
}

/// The core responsive wrapper used on every screen.
///
/// Returns different widget trees based on the current viewport width:
/// - mobile:  < 600px
/// - tablet:  600–899px  (falls back to mobile if not provided)
/// - desktop: ≥ 900px
///
/// Usage:
/// ```dart
/// ResponsiveLayout(
///   mobile: MobileHomeScreen(),
///   tablet: TabletHomeScreen(), // optional
///   desktop: DesktopHomeScreen(),
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= Breakpoints.tablet) {
          return desktop;
        }
        if (width >= Breakpoints.mobile && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}

/// Responsive value helper — picks the right value for the current breakpoint.
///
/// Usage:
/// ```dart
/// final cols = responsiveValue<int>(context,
///   mobile: 2,
///   tablet: 3,
///   desktop: 4,
/// );
/// ```
T responsiveValue<T>(
  BuildContext context, {
  required T mobile,
  T? tablet,
  required T desktop,
}) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= Breakpoints.tablet) return desktop;
  if (width >= Breakpoints.mobile && tablet != null) return tablet;
  return mobile;
}

/// Returns the number of grid columns for the current breakpoint.
int responsiveGridColumns(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= Breakpoints.desktop) return 4;
  if (width >= Breakpoints.tablet) return 3;
  if (width >= Breakpoints.mobile) return 3;
  return 2;
}

/// Returns the appropriate page padding for the current breakpoint.
/// On desktop, uses 3 % of the available width (clamped 32 → 120 px)
/// so the layout breathes naturally on any screen size.
EdgeInsets responsivePagePadding(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w >= Breakpoints.tablet) {
    final h = (w * 0.03).clamp(32.0, 120.0);
    return EdgeInsets.symmetric(horizontal: h);
  }
  if (w >= Breakpoints.mobile) {
    return const EdgeInsets.symmetric(horizontal: 24);
  }
  return const EdgeInsets.symmetric(horizontal: 16);
}

/// Returns the appropriate child aspect ratio for product cards.
/// The image uses AspectRatio(1.0) so image height == cell width.
double responsiveChildAspectRatio(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  final cols = w >= Breakpoints.desktop ? 4 : w >= Breakpoints.tablet ? 3 : w >= Breakpoints.mobile ? 3 : 2;
  final cellW = (w - 12.0 * (cols - 1) - 24) / cols;
  
  return cellW / (cellW + 190);
}

/// Returns true when running on web platform (any viewport width).
/// Use this to decide web vs native-app UI — not for layout breakpoints.
/// For width-based responsive sizing, use responsiveValue() or isMobileLayout().
bool isWebLayout(BuildContext context) => kIsWeb;

/// Returns true when running on mobile (< 600px).
bool isMobileLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width < Breakpoints.mobile;

/// Returns true when running on tablet (600–899px).
bool isTabletLayout(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return w >= Breakpoints.mobile && w < Breakpoints.tablet;
}
