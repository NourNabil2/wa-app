// lib/features/cart/presentation/widgets/saved_address_tile.dart

import 'package:fastway/core/utils/app_size.dart';
import 'package:fastway/features/checkout/domain/entities/saved_address_entity.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

final _v = AppSizeVertical.instance;
final _h = AppSizeHorizontal.instance;
final _t = TextSizeApp.instance;

class SavedAddressTile extends StatelessWidget {
  final AddressEntity address;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const SavedAddressTile({
    super.key,
    required this.address,
    required this.isSelected,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: isLast ? 0 : _v.s8),
        padding: EdgeInsets.all(_h.s14),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorsManager.primaryColor.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? ColorsManager.primaryColor
                : ColorsManager.backgroundCard,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // ── Checkmark ──────────────────────────────
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
                  : Container(
                key: const ValueKey('empty'),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  border:
                  Border.all(color: ColorsManager.inputBorder),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            SizedBox(width: _h.s12),

            // ── Address Info ───────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    address.label,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: _t.s14,
                      fontWeight: FontWeight.w600,
                      color: ColorsManager.defaultText,
                    ),
                  ),
                  SizedBox(height: _v.s3),
                  Text(
                    address.fullAddress,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: _t.s12,
                      color: ColorsManager.defaultTextSecondary,
                    ),
                  ),
                  SizedBox(height: _v.s2),
                  Text(
                    address.phone,
                    style: TextStyle(
                      fontSize: _t.s12,
                      color: ColorsManager.defaultTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}