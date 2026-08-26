// lib/core/responsive/hoverable_card.dart
//
// Hover cursor on desktop WITHOUT MouseRegion.
//
// Root cause of box.dart:2251 on Flutter Web:
// --------------------------------------------------
// MouseRegion (and SafeMouseRegion) register a RenderMouseRegion with the
// mouse tracker. When widgets are lazily mounted by SliverChildBuilderDelegate
// (e.g. a product grid), the new render object is attached and immediately
// registered with the mouse tracker BEFORE the sliver has run layout on it.
// hasSize == false → assert(hasSize) in hitTest → crash.
//
// The fix: use AnnotatedRegion<SystemMouseCursor> for the pointer cursor.
// AnnotatedRegion works via a LAYER annotation (no render-box hit testing),
// so it is never asked for its size. Zero assertions possible.

import 'package:flutter/material.dart';
import 'responsive_layout.dart';

class HoverableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  // Kept for API compatibility — ignored (GPU-heavy effects removed)
  final double hoverLift;
  final double hoverScale;
  final double hoverShadowBlur;
  final double hoverShadowSpread;
  final double hoverShadowOpacity;
  final Duration duration;
  final Color? shadowColor;

  const HoverableCard({
    super.key,
    required this.child,
    this.onTap,
    this.hoverLift = -4,
    this.hoverScale = 1.015,
    this.hoverShadowBlur = 32,
    this.hoverShadowSpread = 0,
    this.hoverShadowOpacity = 0.12,
    this.duration = const Duration(milliseconds: 250),
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = isWebLayout(context);
    final content = RepaintBoundary(child: child);

    if (!isDesktop) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    // AnnotatedRegion sets the mouse cursor via the COMPOSITOR layer tree,
    // not via RenderBox hit-testing. It never needs hasSize. Safe always.
    return AnnotatedRegion<MouseCursor>(
      value: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCALE VARIANT — also stripped to zero GPU cost
// ─────────────────────────────────────────────────────────────────────────────
class HoverableScaleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double hoverScale; // kept for API compat — ignored
  final Duration duration;  // kept for API compat — ignored

  const HoverableScaleCard({
    super.key,
    required this.child,
    this.onTap,
    this.hoverScale = 1.02,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = isWebLayout(context);
    final content = RepaintBoundary(child: child);

    if (!isDesktop) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return AnnotatedRegion<MouseCursor>(
      value: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLICK CURSOR — adds pointer cursor on web to ANY child widget.
// Uses AnnotatedRegion (layer annotation) — safe with lazy slivers.
// ─────────────────────────────────────────────────────────────────────────────
class ClickCursor extends StatelessWidget {
  final Widget child;
  const ClickCursor({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!isWebLayout(context)) return child;
    return AnnotatedRegion<MouseCursor>(
      value: SystemMouseCursors.click,
      child: child,
    );
  }
}