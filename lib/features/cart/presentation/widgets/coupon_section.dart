// lib/features/cart/presentation/widgets/coupon_section.dart

import 'package:fastway/core/theme/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/widgets/app_text_feild.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/loading_widget.dart';

class CouponSection extends StatefulWidget {
  final Function(String) onApply;
  final VoidCallback onRemove;
  final String? appliedCoupon;
  final bool isLoading;

  const CouponSection({
    super.key, 
    required this.onApply, 
    required this.onRemove,
    this.appliedCoupon,
    this.isLoading = false,
  });

  @override
  State<CouponSection> createState() => _CouponSectionState();
}

class _CouponSectionState extends State<CouponSection> {
  final _controller = TextEditingController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.appliedCoupon != null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = AppSizeHorizontal.instance;
    final v = AppSizeVertical.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? ColorsManager.surfaceDarkCard : Colors.white;

    return Container(
      padding: EdgeInsets.all(h.s16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              children: [
                Icon(Icons.local_offer_outlined, size: 20.sp, color: ColorsManager.primary2Color),
                SizedBox(width: h.s8),
                Expanded(
                  child: Text(
                    'cart.coupon_title'.tr(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: isDark ? Colors.white : ColorsManager.defaultText,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.remove : Icons.add,
                  color: ColorsManager.primary2Color,
                  size: 20.sp,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Column(
                    children: [
                      SizedBox(height: v.s16),
                      if (widget.appliedCoupon != null) ...[
                        _AppliedCouponBadge(
                          code: widget.appliedCoupon!,
                          onRemove: widget.onRemove,
                        ),
                      ] else ...[
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: AppTextField(
                                  controller: _controller,
                                  hintText: 'cart.coupon_hint'.tr(),
                                  textAlign: TextAlign.right,
                                  fillColor: isDark ? const Color(0xFF2C2C2E) : ColorsManager.defaultSurface,
                                  borderColor: Colors.transparent,
                                  focusedBorderColor: ColorsManager.primaryColor,
                                  contentPadding: EdgeInsets.symmetric(horizontal: h.s16, vertical: v.s14),
                                ),
                              ),
                              SizedBox(width: h.s12),
                              MouseRegion(
                                cursor: widget.isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: widget.isLoading ? null : () => widget.onApply(_controller.text),
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.symmetric(horizontal: h.s20),
                                    decoration: BoxDecoration(
                                      color: widget.isLoading ? Colors.grey.withValues(alpha: 0.2) : ColorsManager.primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: widget.isLoading
                                        ? const LoadingSpinner(size: 20)
                                        : Text(
                                            'cart.apply'.tr(),
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: v.s8),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            'cart.coupon_hint_text'.tr(),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isDark ? Colors.grey[500] : ColorsManager.defaultTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _AppliedCouponBadge extends StatelessWidget {
  final String code;
  final VoidCallback onRemove;

  const _AppliedCouponBadge({required this.code, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final h = AppSizeHorizontal.instance;
    final v = AppSizeVertical.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: h.s16, vertical: v.s12),
      decoration: BoxDecoration(
        color: ColorsManager.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorsManager.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: ColorsManager.primaryColor, size: 20),
          SizedBox(width: h.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'cart.coupon_applied'.tr(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                Text(
                  code,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: ColorsManager.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, color: isDark ? Colors.grey[600] : ColorsManager.defaultTextSecondary, size: 20),
          ),
        ],
      ),
    );
  }
}