import 'package:flutter/material.dart';
import 'responsive_layout.dart';

/// Adds the standard horizontal page padding for the current breakpoint.
///
/// Inside [WebShell] the content area is already capped at 1440 px and
/// centered, so this widget only needs to add the inner padding —
/// no extra Center / ConstrainedBox is required.
///
/// On mobile and tablet it uses the narrower responsive padding (16/24 px).
/// On desktop it uses 32 px.
///
/// Usage:
/// ```dart
/// MaxWidthContainer(child: MyContent())
/// ```
class MaxWidthContainer extends StatelessWidget {
  final Widget child;
  // maxWidth is kept for API compatibility but no longer applied here —
  // the shell-level ConstrainedBox already handles it.
  final double maxWidth;
  final EdgeInsets? padding;

  const MaxWidthContainer({
    super.key,
    required this.child,
    this.maxWidth = 1440,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final edgePadding = padding ?? responsivePagePadding(context);
    return Padding(
      padding: edgePadding,
      child: child,
    );
  }
}
