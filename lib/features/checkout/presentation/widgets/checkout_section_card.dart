// lib/features/cart/presentation/widgets/checkout_section_card.dart

import 'package:fastway/core/theme/colors.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/app_size.dart';

final _v = AppSizeVertical.instance;
final _h = AppSizeHorizontal.instance;
final _t = TextSizeApp.instance;

/// A titled card container used throughout the checkout screen.
class CheckoutSectionCard extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final Widget child;
  final bool isExpanded;

  const CheckoutSectionCard({
    super.key,
    required this.title,
    required this.titleIcon,
    required this.child,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: استخدام isDark بدل Colors.white الثابتة
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(_h.s16),
      decoration: BoxDecoration(
        // ✅ بيتغير مع الـ dark mode
        color: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.defaultText.withValues(alpha: isDark ? 0.03 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title Row ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(titleIcon, size: _t.s18, color: ColorsManager.primary2Color),
              SizedBox(width: _h.s8),
              Text(
                title,
                style: TextStyle(
                  fontSize: _t.s12,
                  fontWeight: FontWeight.bold,
                  color: ColorsManager.defaultText,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Padding(
                    padding: EdgeInsets.only(top: _v.s12),
                    child: child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}