// lib/features/orders/presentation/widgets/delivery_sla_widget.dart
//
// T8.6 — Delivery SLA countdown widget
// Shows a live countdown bar for in-transit orders:
//   • shipped + delivery_estimate  → deadline
//   • shipped but no estimate      → created_at + 5 business days (fallback)
//   • delivered / cancelled        → nothing

import 'package:fastway/core/theme/colors.dart';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/order_entity.dart';

class DeliverySlaWidget extends StatefulWidget {
  final OrderEntity order;

  const DeliverySlaWidget({super.key, required this.order});

  @override
  State<DeliverySlaWidget> createState() => _DeliverySlaWidgetState();
}

class _DeliverySlaWidgetState extends State<DeliverySlaWidget> {
  late Timer _timer;
  Duration _remaining = Duration.zero;
  DateTime? _deadline;
  bool _isLate = false;

  @override
  void initState() {
    super.initState();
    _deadline = _computeDeadline();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _update());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // ── Compute delivery deadline ─────────────────────────────────────────────
  DateTime? _computeDeadline() {
    final shippedAt = widget.order.shippedAt;
    final estimate  = widget.order.deliveryEstimate; // e.g. "2-3 days", "24 hours"

    final baseDate = shippedAt ?? widget.order.createdAt;

    // Parse the estimate string if available
    if (estimate != null && estimate.isNotEmpty) {
      final days = _parseDaysFromEstimate(estimate);
      if (days != null) {
        return baseDate.add(Duration(days: days));
      }
    }

    // Default SLA: 5 business days from order creation
    return baseDate.add(const Duration(days: 5));
  }

  int? _parseDaysFromEstimate(String estimate) {
    // Handles: "2-3 days", "3 days", "24 hours", "48h", "2 أيام"
    final lower = estimate.toLowerCase();

    // Hours: "24 hours" / "48h"
    final hourMatch = RegExp(r'(\d+)\s*h').firstMatch(lower);
    if (hourMatch != null) {
      final hours = int.tryParse(hourMatch.group(1)!);
      if (hours != null) return (hours / 24).ceil();
    }

    // Days range: "2-3 days" → take the higher bound
    final rangeMatch = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(lower);
    if (rangeMatch != null) {
      return int.tryParse(rangeMatch.group(2)!);
    }

    // Single number: "3 days"
    final singleMatch = RegExp(r'(\d+)').firstMatch(lower);
    if (singleMatch != null) {
      return int.tryParse(singleMatch.group(1)!);
    }

    return null;
  }

  void _update() {
    if (!mounted) return;
    final deadline = _deadline;
    if (deadline == null) return;

    final now = DateTime.now();
    final diff = deadline.difference(now);
    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
      _isLate    = diff.isNegative;
    });
  }

  // ── Should we show this widget? ──────────────────────────────────────────
  bool get _shouldShow {
    final status = widget.order.status;
    if (status == 'delivered' || status == 'cancelled' || status == 'cancellation_requested') {
      return false;
    }
    return _deadline != null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    final deadline = _deadline!;
    final now      = DateTime.now();
    final total    = deadline.difference(widget.order.shippedAt ?? widget.order.createdAt);
    final elapsed  = now.difference(widget.order.shippedAt ?? widget.order.createdAt);
    final progress = (elapsed.inSeconds / (total.inSeconds == 0 ? 1 : total.inSeconds)).clamp(0.0, 1.0);

    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final barColor = _isLate
        ? const Color(0xFFEF4444)
        : (progress > 0.75
            ? const Color(0xFFF59E0B)
            : ColorsManager.primaryColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: barColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: barColor.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ─────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isLate ? Icons.warning_amber_rounded : Icons.local_shipping_rounded,
                  size: 16,
                  color: barColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLate
                          ? 'orders.tracking.delivery_overdue'.tr()
                          : 'orders.tracking.estimated_delivery'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    Text(
                      _isLate
                          ? 'orders.tracking.expected_overdue'.tr(args: [DateFormat('d MMM').format(deadline)])
                          : DateFormat('EEEE, d MMMM').format(deadline),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: barColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Live countdown badge
              if (!_isLate) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    _formatDuration(_remaining),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: barColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          // ── Progress bar ──────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),

          const SizedBox(height: 8),

          // ── Shipped date / label ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.order.shippedAt != null
                    ? 'orders.tracking.shipped_at'.tr(args: [DateFormat('d MMM').format(widget.order.shippedAt!)])
                    : 'orders.tracking.order_placed'.tr(args: [DateFormat('d MMM').format(widget.order.createdAt)]),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: barColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inDays > 0) {
      final hours = d.inHours.remainder(24);
      return '${d.inDays}d ${hours}h';
    }
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }
}
