// lib/core/widgets/safe_mouse_region.dart
//
// Safe hover widget for Flutter Web — avoids box.dart:2251 and
// mouse_tracker.dart:199 assertions.
//
// Root cause of box.dart:2251:
// ─────────────────────────────
// MouseRegion registers a RenderMouseRegion with Flutter's mouse tracker.
// When widgets are lazily mounted (SliverList, BlocBuilder data load, etc.),
// the render object attaches and registers before layout runs on it.
// hasSize == false → RenderBox.hitTest assert fails.
//
// Strategy:
// ─────────────────────────────
// If ONLY a cursor is needed → use AnnotatedRegion<SystemMouseCursor>.
//   Works through the compositor annotation layer, never needs hasSize.
//
// If onEnter / onExit callbacks are also needed → still use MouseRegion,
//   but always keep it in the tree from the FIRST build (never insert it
//   dynamically), and defer callbacks to addPostFrameCallback to prevent
//   the mouse_tracker.dart:199 reentrancy assertion.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SafeMouseRegion extends StatefulWidget {
  final MouseCursor cursor;
  final void Function(PointerEnterEvent)? onEnter;
  final void Function(PointerExitEvent)? onExit;
  final void Function(PointerHoverEvent)? onHover;
  final HitTestBehavior hitTestBehavior;
  final Widget child;

  const SafeMouseRegion({
    super.key,
    this.cursor = MouseCursor.defer,
    this.onEnter,
    this.onExit,
    this.onHover,
    this.hitTestBehavior = HitTestBehavior.opaque,
    required this.child,
  });

  @override
  State<SafeMouseRegion> createState() => _SafeMouseRegionState();
}

class _SafeMouseRegionState extends State<SafeMouseRegion> {
  // Whether one frame has passed since mount.
  // Before _active: cursor is AnnotatedRegion only (no hit-test box).
  // After  _active: full MouseRegion with callbacks.
  bool _active = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _active = true);
    });
  }

  // Deferred callbacks prevent mouse_tracker.dart:199 reentrancy.
  void Function(PointerEnterEvent)? get _safeEnter {
    if (!_active) return null;
    final cb = widget.onEnter;
    if (cb == null) return null;
    return (event) => WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) cb(event);
        });
  }

  void Function(PointerExitEvent)? get _safeExit {
    if (!_active) return null;
    final cb = widget.onExit;
    if (cb == null) return null;
    return (event) => WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) cb(event);
        });
  }

  @override
  Widget build(BuildContext context) {
    // No callbacks → cursor-only via AnnotatedRegion (no hit-test box, no size assertion).
    if (widget.onEnter == null && widget.onExit == null && widget.onHover == null) {
      return AnnotatedRegion<MouseCursor>(
        value: widget.cursor,
        child: widget.child,
      );
    }

    // Callbacks needed → use MouseRegion.
    // Always keep it in the tree (never dynamically insert) so the render
    // object is always laid out before any hit-test can occur.
    // Before _active: cursor deferred, callbacks null → no state mutations.
    return MouseRegion(
      cursor: _active ? widget.cursor : MouseCursor.defer,
      hitTestBehavior: widget.hitTestBehavior,
      onEnter: _safeEnter,
      onExit: _safeExit,
      onHover: _active ? widget.onHover : null,
      child: widget.child,
    );
  }
}
