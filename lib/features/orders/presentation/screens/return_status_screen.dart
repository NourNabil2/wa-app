import 'package:fastway/core/theme/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/layout/simple_web_shell.dart';
import 'package:fastway/core/responsive/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/order_entity.dart';

class ReturnStatusScreen extends StatelessWidget {
  final OrderEntity order;

  const ReturnStatusScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    if (isWebLayout(context)) {
      return SimpleWebShell(content: _WebReturnContent(order: order));
    }
    return _MobileReturnContent(order: order);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOBILE
// ═══════════════════════════════════════════════════════════════════════════════

class _MobileReturnContent extends StatelessWidget {
  final OrderEntity order;
  const _MobileReturnContent({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order.activeReturn?.status ?? 'requested';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('orders.return_status_title'.tr()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: _ReturnCard(order: order, status: status, isDark: isDark),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WEB
// ═══════════════════════════════════════════════════════════════════════════════

class _WebReturnContent extends StatelessWidget {
  final OrderEntity order;
  const _WebReturnContent({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order.activeReturn?.status ?? 'requested';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.42),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Page header ───────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: ColorsManager.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: const Icon(Icons.assignment_return_rounded,
                        color: ColorsManager.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'orders.return_status_title'.tr(),
                        style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0D0D14),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.orderNumber,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: ColorsManager.primaryColor),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _ReturnCard(order: order, status: status, isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class _ReturnCard extends StatelessWidget {
  final OrderEntity order;
  final String status;
  final bool isDark;

  const _ReturnCard({required this.order, required this.status, required this.isDark});

  Widget _buildTimeline(String currentStatus) {
    final steps = [
      {'key': 'requested', 'label': 'orders.return_status.requested'.tr()},
      {
        'key': currentStatus == 'rejected' ? 'rejected' : 'approved',
        'label': currentStatus == 'rejected'
            ? 'orders.return_status.rejected'.tr()
            : 'orders.return_status.approved'.tr()
      },
      {'key': 'refunded', 'label': 'orders.return_status.refunded'.tr()},
    ];

    int currentIndex = 0;
    if (currentStatus == 'approved' || currentStatus == 'rejected') currentIndex = 1;
    if (currentStatus == 'refunded') currentIndex = 2;

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isCompleted = index <= currentIndex;
        final isLast = index == steps.length - 1;
        final isRejected = step['key'] == 'rejected';

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? (isRejected ? Colors.red : ColorsManager.primaryColor)
                        : Colors.grey.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted
                      ? Icon(isRejected ? Icons.close : Icons.check,
                          size: 14.sp, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2.w,
                    height: 40.h,
                    color: isCompleted
                        ? (isRejected ? Colors.red : ColorsManager.primaryColor)
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
              ],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Text(
                  step['label']!,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted
                        ? (isRejected ? Colors.red : ColorsManager.defaultText)
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? ColorsManager.surfaceDarkCard : ColorsManager.inputSurface,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: ColorsManager.inputBorder.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.defaultText.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${'orders.order_number'.tr()}: ${order.orderNumber}',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: ColorsManager.defaultText,
            ),
          ),
          SizedBox(height: 16.h),
          _buildTimeline(status),
        ],
      ),
    );
  }
}
