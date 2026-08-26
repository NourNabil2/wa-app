// lib/core/widgets/custom_snackbar.dart

import 'package:fastway/core/theme/colors.dart';
import 'package:flutter/material.dart';

enum SnackBarType { success, error, warning, info }

/// Compact toast-style snackbar.
/// • Slides in from the top with a fade.
/// • Appears top-RIGHT for LTR languages, top-LEFT for RTL.
/// • Small, themed card with a coloured accent stripe.
class CustomSnackBar {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.success,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
    bool showCloseButton = true,
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          if (_currentEntry == entry) _currentEntry = null;
          entry.remove();
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void hide() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ToastWidget extends StatefulWidget {
  final String message;
  final SnackBarType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );

    _slide = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6)),
    );

    _ctrl.forward();
    Future.delayed(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  // ── type helpers ──────────────────────────────────────────────────────────

  Color get _accentColor {
    switch (widget.type) {
      case SnackBarType.success:
        return ColorsManager.successFill;
      case SnackBarType.error:
        return ColorsManager.errorFill;
      case SnackBarType.warning:
        return ColorsManager.warningFill;
      case SnackBarType.info:
        return ColorsManager.infoFill;
    }
  }

  Color get _iconColor {
    switch (widget.type) {
      case SnackBarType.success:
        return ColorsManager.successFill;
      case SnackBarType.error:
        return ColorsManager.errorFill;
      case SnackBarType.warning:
        return ColorsManager.warningFill;
      case SnackBarType.info:
        return ColorsManager.infoFill;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case SnackBarType.success:
        return Icons.check_circle_rounded;
      case SnackBarType.error:
        return Icons.cancel_rounded;
      case SnackBarType.warning:
        return Icons.warning_amber_rounded;
      case SnackBarType.info:
        return Icons.info_rounded;
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    final isDesktop = mq.size.width > 768;

    // Width: compact on mobile, capped on desktop
    final toastWidth = (isDesktop ? 320 : (mq.size.width - 32).clamp(0, 360)).toDouble();
    final topPad = mq.padding.top + (isDesktop ? 20.0 : 12.0);

    return Positioned(
      top: topPad,
      // RTL → top-left, LTR → top-right
      left: isRtl ? 16.0 : null,
      right: isRtl ? null : 16.0,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, _slide.value * 80),
          child: Opacity(
            opacity: _fade.value.clamp(0.0, 1.0),
            child: child,
          ),
        ),
        child: SizedBox(
          width: toastWidth,
          child: _buildCard(context, isRtl),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, bool isRtl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1E2230) : Colors.white;
    final textColor = isDark ? Colors.white : ColorsManager.gray900;
    final subTextColor = isDark ? Colors.white60 : ColorsManager.gray500;
    final borderColor = isDark ? Colors.white10 : ColorsManager.gray200;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _dismiss,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // ── content ──────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.only(
                    top: 12,
                    bottom: 12,
                    left: isRtl ? 12 : 16,
                    right: isRtl ? 16 : 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // icon
                      Icon(_icon, color: _iconColor, size: 20),
                      const SizedBox(width: 10),

                      // message
                      Expanded(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // close X
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _dismiss,
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── coloured stripe ──────────────────────────────────────
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: isRtl ? null : 0,
                  right: isRtl ? 0 : null,
                  child: Container(
                    width: 4,
                    color: _accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Context extension — unchanged API
// ─────────────────────────────────────────────────────────────────────────────

extension CustomSnackBarExtension on BuildContext {
  void showSuccess(String message, {String? actionLabel, VoidCallback? onAction}) {
    CustomSnackBar.show(this, message: message, type: SnackBarType.success);
  }

  void showError(String message, {String? actionLabel, VoidCallback? onAction}) {
    CustomSnackBar.show(this, message: message, type: SnackBarType.error);
  }

  void showWarning(String message, {String? actionLabel, VoidCallback? onAction}) {
    CustomSnackBar.show(this, message: message, type: SnackBarType.warning);
  }

  void showInfo(String message, {String? actionLabel, VoidCallback? onAction}) {
    CustomSnackBar.show(this, message: message, type: SnackBarType.info);
  }
}