// lib/features/profile/presentation/widgets/profile_field_tile.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class ProfileFieldTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;
  final bool isLast; // ✅ NEW: controls whether to show bottom divider

  const ProfileFieldTile({
    super.key,
    required this.icon,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent, // ✅ FIX: Make transparent per request
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: maxLines > 1
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  // ── Icon ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      icon,
                      size: 22,
                      color: ColorsManager.primaryColor,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ── Label + Value ────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Label
                        Text(
                          label,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            height: 1,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // ✅ FIX: TextField sits flush — no decoration artifacts
                        TextField(
                          controller: controller,
                          keyboardType: keyboardType,
                          readOnly: readOnly,
                          maxLines: maxLines,
                          textAlign: TextAlign.end,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 15,
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            filled: false,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.zero,
                            hintText: hint,
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: cs.onSurface.withValues(alpha: 0.3),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Trailing chevron for readOnly (date picker etc.) ─
                  // ✅ FIX: Chevron replaces the calendar prefix icon — cleaner
                  if (readOnly) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons
                          .chevron_left_rounded, // RTL: points left = "forward"
                      size: 20,
                      color: cs.onSurface.withValues(alpha: 0.3),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
