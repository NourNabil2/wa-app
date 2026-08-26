import 'package:fastway/core/theme/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shows a polished bottom-sheet modal for empty states (cart / wishlist /
/// notifications) instead of navigating away to a full page.
///
/// On web, prefer [EmptyModal.showDropdown] which opens as an Overlay
/// dropdown directly below the triggering button.
class EmptyModal {
  // ── Mobile bottom-sheet (unchanged) ────────────────────────────────────────
  static Future<void> show(
    BuildContext context, {
    required IconData icon,
    required String titleKey,
    required String subtitleKey,
    String? actionLabelKey,
    VoidCallback? onAction,
    Color? iconColor,
    String? secondaryLabelKey,
    VoidCallback? onSecondaryAction,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EmptyModalSheet(
        icon: icon,
        iconColor: iconColor,
        titleKey: titleKey,
        subtitleKey: subtitleKey,
        actionLabelKey: actionLabelKey,
        onAction: onAction,
        secondaryLabelKey: secondaryLabelKey,
        onSecondaryAction: onSecondaryAction,
        bg: bg,
        subtitleColor: subtitleColor,
        isDark: isDark,
      ),
    );
  }

  // ── Web dropdown (anchored below the triggering widget) ────────────────────
  static OverlayEntry? _activeDropdown;

  static void showDropdown(
    BuildContext context, {
    required GlobalKey anchorKey,
    required IconData icon,
    required String titleKey,
    required String subtitleKey,
    String? actionLabelKey,
    VoidCallback? onAction,
    Color? iconColor,
    String? secondaryLabelKey,
    VoidCallback? onSecondaryAction,
  }) {
    // Close any open dropdown first
    _dismiss();

    final renderBox =
        anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size   = renderBox.size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final entry = OverlayEntry(
      builder: (_) => _DropdownEmptyModal(
        left: offset.dx,
        top: offset.dy + size.height + 12,
        icon: icon,
        iconColor: iconColor,
        titleKey: titleKey,
        subtitleKey: subtitleKey,
        actionLabelKey: actionLabelKey,
        onAction: () {
          _dismiss();
          onAction?.call();
        },
        secondaryLabelKey: secondaryLabelKey,
        onSecondaryAction: () {
          _dismiss();
          onSecondaryAction?.call();
        },
        isDark: isDark,
        onDismiss: _dismiss,
      ),
    );

    _activeDropdown = entry;
    Overlay.of(context).insert(entry);
  }

  static void _dismiss() {
    _activeDropdown?.remove();
    _activeDropdown = null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Web Dropdown variant — rendered via Overlay, anchored to the button
// ─────────────────────────────────────────────────────────────────────────────

class _DropdownEmptyModal extends StatefulWidget {
  final double left;
  final double top;
  final IconData icon;
  final Color? iconColor;
  final String titleKey;
  final String subtitleKey;
  final String? actionLabelKey;
  final VoidCallback? onAction;
  final String? secondaryLabelKey;
  final VoidCallback? onSecondaryAction;
  final bool isDark;
  final VoidCallback onDismiss;

  const _DropdownEmptyModal({
    required this.left,
    required this.top,
    required this.icon,
    this.iconColor,
    required this.titleKey,
    required this.subtitleKey,
    this.actionLabelKey,
    this.onAction,
    this.secondaryLabelKey,
    this.onSecondaryAction,
    required this.isDark,
    required this.onDismiss,
  });

  @override
  State<_DropdownEmptyModal> createState() => _DropdownEmptyModalState();
}

class _DropdownEmptyModalState extends State<_DropdownEmptyModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, -0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF1C1C2E) : Colors.white;
    final subtitleColor =
        widget.isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final effectiveIconColor = widget.iconColor ?? ColorsManager.primaryColor;
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Keep within screen bounds
    const cardWidth = 280.0;
    final clampedLeft =
        (widget.left + cardWidth > screenWidth - 8)
            ? screenWidth - cardWidth - 8
            : widget.left;

    return Stack(
      children: [
        // Dismiss backdrop
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onDismiss,
          ),
        ),

        // Card
        Positioned(
          left: clampedLeft,
          top: widget.top,
          width: cardWidth,
          child: FadeTransition(
            opacity: _opacity,
            child: SlideTransition(
              position: _slide,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: widget.isDark ? 0.5 : 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              effectiveIconColor.withValues(alpha: 0.15),
                              effectiveIconColor.withValues(alpha: 0.04),
                            ],
                          ),
                        ),
                        child: Icon(widget.icon,
                            size: 30, color: effectiveIconColor),
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        widget.titleKey.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: widget.isDark
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Subtitle
                      Text(
                        widget.subtitleKey.tr(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: subtitleColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Primary action
                      if (widget.actionLabelKey != null &&
                          widget.onAction != null)
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton(
                            onPressed: widget.onAction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorsManager.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: Text(
                              widget.actionLabelKey!.tr(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),

                      // Secondary action
                      if (widget.secondaryLabelKey != null &&
                          widget.onSecondaryAction != null) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: TextButton(
                            onPressed: widget.onSecondaryAction,
                            style: TextButton.styleFrom(
                              foregroundColor: subtitleColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: Text(
                              widget.secondaryLabelKey!.tr(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile bottom-sheet (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyModalSheet extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String titleKey;
  final String subtitleKey;
  final String? actionLabelKey;
  final VoidCallback? onAction;
  final String? secondaryLabelKey;
  final VoidCallback? onSecondaryAction;
  final Color bg;
  final Color subtitleColor;
  final bool isDark;

  const _EmptyModalSheet({
    required this.icon,
    this.iconColor,
    required this.titleKey,
    required this.subtitleKey,
    this.actionLabelKey,
    this.onAction,
    this.secondaryLabelKey,
    this.onSecondaryAction,
    required this.bg,
    required this.subtitleColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? ColorsManager.primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(32.w, 16.h, 32.w, 36.h),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ────────────────────────────────────────────────
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 28.h),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(50),
              ),
            ),

            // ── Icon blob ──────────────────────────────────────────────────
            Container(
              width: 88.w,
              height: 88.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    effectiveIconColor.withValues(alpha: 0.15),
                    effectiveIconColor.withValues(alpha: 0.04),
                  ],
                ),
              ),
              child: Icon(icon, size: 44.sp, color: effectiveIconColor),
            ),
            SizedBox(height: 20.h),

            // ── Title ──────────────────────────────────────────────────────
            Text(
              titleKey.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                height: 1.3,
              ),
            ),
            SizedBox(height: 10.h),

            // ── Subtitle ───────────────────────────────────────────────────
            Text(
              subtitleKey.tr(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.sp,
                color: subtitleColor,
                height: 1.6,
              ),
            ),
            SizedBox(height: 28.h),

            // ── Primary action ─────────────────────────────────────────────
            if (actionLabelKey != null && onAction != null)
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  onAction!();
                },
                child: Container(
                  width: double.infinity,
                  height: 52.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2196F3), ColorsManager.primaryColor],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: ColorsManager.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      actionLabelKey!.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                ),
              ),

            // ── Secondary action ───────────────────────────────────────────
            if (secondaryLabelKey != null && onSecondaryAction != null) ...[
              SizedBox(height: 12.h),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  onSecondaryAction!();
                },
                child: Container(
                  width: double.infinity,
                  height: 48.h,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Center(
                    child: Text(
                      secondaryLabelKey!.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : const Color(0xFF444466),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
