import 'package:fastway/core/theme/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/widgets/selectable.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/points_entity.dart';

class PointsStatsRow extends StatelessWidget {
  final PointsSummaryEntity summary;

  const PointsStatsRow({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.05 : 0.01), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Selectable(
          child: Row(
            children: [
              _StatItem(value: '${summary.totalOrders}', label: 'profile.total_orders'.tr()),
              _Divider(isDark: isDark),
              _StatItem(value: '${summary.totalPointsEarned}', label: 'points.totalEarned'.tr()),
              _Divider(isDark: isDark),
              _StatItem(value: '${summary.netPointsRedeemed}', label: 'points.stats.used'.tr()),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[500] : Colors.grey[500])),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05));
  }
}