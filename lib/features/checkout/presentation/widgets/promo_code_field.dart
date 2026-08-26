import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/utils/app_size.dart';
import 'package:fastway/core/widgets/app_text_feild.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/loading_widget.dart';

class PromoCodeField extends StatefulWidget {
  final bool isLoading;
  final String? appliedCode;
  final void Function(String code) onApply;
  final VoidCallback onRemove;

  const PromoCodeField({
    super.key,
    required this.isLoading,
    this.appliedCode,
    required this.onApply,
    required this.onRemove,
  });

  @override
  State<PromoCodeField> createState() => _PromoCodeFieldState();
}

class _PromoCodeFieldState extends State<PromoCodeField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = AppSizeVertical.instance;
    final h = AppSizeHorizontal.instance;
    final t = TextSizeApp.instance;
    final isApplied = widget.appliedCode != null;

    return Container(
      padding: EdgeInsets.all(h.s16),
      decoration: BoxDecoration(
        color: ColorsManager.inputSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.defaultText.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Apply / Remove button ──────────────────
          GestureDetector(
            onTap: isApplied
                ? widget.onRemove
                : widget.isLoading
                ? null
                : () => widget.onApply(_controller.text.trim()),
            child: Container(
              height: v.s40,
              padding: EdgeInsets.symmetric(horizontal: h.s16),
              decoration: BoxDecoration(
                color: isApplied
                    ? ColorsManager.errorSurface
                    : ColorsManager.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: widget.isLoading && !isApplied
                // ✅ LoadingSpinner بدل CircularProgressIndicator
                    ? const LoadingSpinner(size: 16, color: ColorsManager.inputSurface)
                    : Text(
                  isApplied ? 'cart.remove'.tr() : 'cart.apply'.tr(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isApplied
                        ? ColorsManager.errorFill
                        : ColorsManager.inputSurface,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: h.s12),

          // ── Input or applied code ──────────────────
          Expanded(
            child: isApplied
                ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: ColorsManager.primaryColor,
                  size: t.s16,
                ),
                SizedBox(width: h.s6),
                Text(
                  widget.appliedCode!,
                  style:
                  Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: ColorsManager.primaryColor,
                  ),
                ),
              ],
            )
            // AppTextField
                : AppTextField(
              controller: _controller,
              hintText: 'cart.enterPromo'.tr(),
              textAlign: TextAlign.right,
              fillColor: Colors.transparent,
              borderColor: Colors.transparent,
              focusedBorderColor: Colors.transparent,
              hintColor: ColorsManager.inputBorder,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),

          SizedBox(width: h.s8),

          // ── Coupon icon ────────────────────────────
          Icon(
            Icons.confirmation_number_outlined,
            color: ColorsManager.primaryColor,
            size: t.s20,
          ),
        ],
      ),
    );
  }
}