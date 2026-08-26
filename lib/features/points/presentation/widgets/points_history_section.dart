// lib/features/points/presentation/widgets/points_history_section.dart

import 'package:fastway/core/theme/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/utils/app_size.dart';
import 'package:fastway/core/widgets/selectable.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/points_entity.dart';

final _v = AppSizeVertical.instance;
final _h = AppSizeHorizontal.instance;
final _t = TextSizeApp.instance;

class PointsHistorySection extends StatelessWidget {
  final List<PointsHistoryEntity> history;

  const PointsHistorySection({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _h.s16),
      child: Container(
        padding: EdgeInsets.all(_h.s16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? ColorsManager.surfaceDarkCard : Colors.white,
          borderRadius: BorderRadius.zero,
          boxShadow: [
            BoxShadow(
              color: ColorsManager.defaultText.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── Header ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    // 👈 شلت الـ Navigator لأنه بيعمل ريستارت للصفحة وأنت أصلاً فيها
                    // لو هتعمل صفحة منفصلة للـ History بعدين، ابقى حط مسارها هنا
                  },
                  child: Row(
                    children: [
                      Text(
                        'points.viewAll'.tr(),
                        style: TextStyle(
                          fontSize: _t.s12,
                          color: ColorsManager.primary2Color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: _h.s4),
                      Icon(
                        Icons.chevron_left,
                        size: _t.s16,
                        color: ColorsManager.primary2Color,
                      ),
                    ],
                  ),
                ),
                Text(
                  'points.history'.tr(),
                  style: TextStyle(
                    fontSize: _t.s16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : ColorsManager.defaultText,
                  ),
                ),
              ],
            ),

            SizedBox(height: _v.s12),

            // ── History items ─────────────────────────
            if (history.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: _v.s16),
                child: Center(
                  child: Text(
                    'points.no_history'.tr(),
                    style: TextStyle(
                      fontSize: _t.s16,
                      fontWeight: FontWeight.w600,
                      color: ColorsManager.defaultTextSecondary,
                    ),
                  ),
                ),
              )
            else
              ...List.generate(history.length, (i) {
                final item = history[i];
                return Column(
                  children: [
                    _HistoryItem(item: item),
                    if (i < history.length - 1)
                      Divider(
                        height: _v.s16,
                        color: ColorsManager.backgroundCard,
                      ),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final PointsHistoryEntity item;

  const _HistoryItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final t = TextSizeApp.instance;
    final h = AppSizeHorizontal.instance;
    final v = AppSizeVertical.instance;

    final isEarned = item.isEarned;
    final pointsColor =
    isEarned ? ColorsManager.primary2Color : ColorsManager.errorFill;
    final bgColor = isEarned
        ? ColorsManager.primary2Color.withValues(alpha: 0.1)
        : ColorsManager.errorFill.withValues(alpha: 0.1);

    final dateStr =
        '${item.date.day} ${_monthName(item.date.month)} ${item.date.year}';

    return Selectable(
      child: Row(
        children: [
          // ── Points badge (left in RTL) ────────────
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                isEarned ? Icons.add_rounded : Icons.remove_rounded,
                color: pointsColor,
                size: t.s20,
              ),
            ),
          ),

          SizedBox(width: h.s12),

          // ── Points value ──────────────────────────
          Text(
            isEarned ? '+${item.points}' : '${item.points}',
            style: TextStyle(
              fontSize: t.s16,
              fontWeight: FontWeight.bold,
              color: pointsColor,
            ),
          ),

          const Spacer(),

          // ── Title + date ──────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  fontSize: t.s14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : ColorsManager.defaultText,
                ),
              ),
              SizedBox(height: v.s3),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: t.s12,
                  color: ColorsManager.defaultTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    final months = [
      '', 'points.months.jan'.tr(), 'points.months.feb'.tr(), 'points.months.mar'.tr(), 'points.months.apr'.tr(), 'points.months.may'.tr(), 'points.months.jun'.tr(),
      'points.months.jul'.tr(), 'points.months.aug'.tr(), 'points.months.sep'.tr(), 'points.months.oct'.tr(), 'points.months.nov'.tr(), 'points.months.dec'.tr(),
    ];
    return months[month];
  }
}