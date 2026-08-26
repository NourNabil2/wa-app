// lib/features/cart/presentation/widgets/selectable_option_tile.dart

import 'package:fastway/core/utils/app_size.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

final _v = AppSizeVertical.instance;
final _h = AppSizeHorizontal.instance;
final _t = TextSizeApp.instance;

class SelectableOptionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trailingLabel;
  final Color? trailingColor;
  final Widget? trailingWidget;
  final Widget? leadingWidget;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;
  final bool isEnabled;

  const SelectableOptionTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailingLabel,
    this.trailingColor,
    this.trailingWidget,
    this.leadingWidget,
    required this.isSelected,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget tile = AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: _h.s14, vertical: _v.s12),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorsManager.primaryColor.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? Radius.zero : Radius.zero,
            bottom: isLast ? Radius.zero : Radius.zero,
          ),
          border: Border.all(
            color: isSelected
                ? ColorsManager.primaryColor
                : ColorsManager.backgroundCard,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // ── Trailing label/widget (left in RTL) ───────────
            if (trailingWidget != null)
              trailingWidget!
            else if (trailingLabel != null)
              Text(
                trailingLabel!,
                style: TextStyle(
                  fontSize: _t.s12,
                  fontWeight: FontWeight.w600,
                  color: trailingColor ?? ColorsManager.primaryColor,
                ),
              ),

            const Spacer(),

            // ── Title + Subtitle ───────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _t.s14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: ColorsManager.defaultText,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: _v.s2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: _t.s12,
                      color: ColorsManager.defaultTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(width: _h.s10),

            // ── Leading / Check ────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Container(
                key: const ValueKey('check'),
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: ColorsManager.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: _t.s14,
                  color: Colors.white,
                ),
              )
                  : leadingWidget ??
                  Container(
                    key: const ValueKey('empty'),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      border: Border.all(color: ColorsManager.inputBorder),
                      shape: BoxShape.circle,
                    ),
                  ),
            ),
          ],
        ),
      );

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: tile,
      ),
    );
  }
}