// lib/core/widgets/drag_scroll.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Re-enables mouse drag-to-scroll for the scrollable it wraps.
///
/// [AppScrollBehavior] (main.dart) deliberately leaves PointerDeviceKind.mouse
/// OUT of dragDevices app-wide: with the mouse registered as a drag device every
/// Scrollable installs a drag-to-scroll recognizer, which beats SelectionArea's
/// TapAndPanGestureRecognizer in the gesture arena — so click-dragging across
/// text scrolled the page instead of selecting the text.
///
/// Horizontal carousels hold no selectable text and users do expect to drag
/// them, so they opt the mouse back in by wrapping themselves in this widget.
class DragScroll extends StatelessWidget {
  const DragScroll({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      child: child,
    );
  }
}
