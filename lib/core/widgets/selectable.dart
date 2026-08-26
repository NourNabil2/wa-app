// lib/core/widgets/selectable.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Makes the text it wraps selectable and copyable on web, with an I-beam cursor.
///
/// Use this instead of hand-rolling `MouseRegion` + `SelectionArea` at each site:
///
/// ```dart
/// Selectable(child: Text(product.sku!)),
/// ```
///
/// ## Wrap TEXT ONLY — never a button, card, link or chip
///
/// On web, [SelectionArea] injects a transparent HTML element over whatever it
/// wraps (class `web-selectable-region-context-menu`) so the browser's native
/// right-click menu can offer "Copy". That element sits ABOVE Flutter's canvas,
/// so it — not the widget beneath it — decides the mouse cursor. web/index.html
/// therefore forces `cursor: text` on it, which is what finally makes the I-beam
/// appear over selectable text.
///
/// The consequence: anything inside a [Selectable] renders with the text cursor.
/// Wrap a button and it loses its hand cursor (this is exactly how the whole app
/// lost its hand cursors once, when a single SelectionArea was placed at the root).
/// Keep the wrap tight around the text itself.
///
/// ## Selection scope
///
/// Each [Selectable] is its own selection scope, so a drag cannot select across
/// two of them (e.g. from the price into the SKU). Each block is selected on its
/// own. This is deliberate: one big SelectionArea spanning the page would put the
/// overlay over every button in it.
///
/// ## Mobile
///
/// A no-op off web — mobile already has native long-press-to-copy, and desktop
/// style drag-selection is not the right interaction for touch.
class Selectable extends StatelessWidget {
  const Selectable({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: SelectionArea(child: child),
    );
  }
}
