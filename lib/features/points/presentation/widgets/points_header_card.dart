// lib/features/points/presentation/widgets/points_header_card.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/responsive/responsive_layout.dart'; // 👈 استدعاء الـ Responsive
import 'package:fastway/core/utils/app_size.dart';
import 'package:fastway/core/widgets/selectable.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../domain/entities/points_entity.dart';

final _v = AppSizeVertical.instance;
final _h = AppSizeHorizontal.instance;
final _t = TextSizeApp.instance;

class PointsHeaderCard extends StatelessWidget {
  final PointsSummaryEntity summary;

  const PointsHeaderCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final isWeb = isWebLayout(context); // 👈 فحص الويب

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ColorsManager.primary2Color,
        // تدوير الحواف من فوق في الويب عشان ميبقاش قاطع بشكل حاد
        borderRadius: isWeb ? const BorderRadius.vertical(top: Radius.zero) : null,
      ),
      child: SafeArea(
        bottom: false,
        top: !isWeb, // لو ويب مش محتاجين SafeArea من فوق
        child: Padding(
          padding: EdgeInsets.fromLTRB(_h.s20, _v.s16, _h.s20, _v.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ── Title row ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 👈 إخفاء زرار الرجوع لو إحنا على الويب لأنه تاب أساسي
                  isWeb ? const SizedBox() : GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: _t.s20,
                      ),
                    ),
                  ),
                  Text(
                    'points.title'.tr(),
                    style: TextStyle(
                      fontSize: _t.s18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              SizedBox(height: _v.s24),

              // ── Trophy + points ───────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Selectable(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'points.current_points'.tr(),
                            style: TextStyle(
                              fontSize: _t.s14,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          SizedBox(height: _v.s4),
                          Text(
                            '${summary.currentPoints}',
                            style: TextStyle(
                              fontSize: _t.s40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: _v.s4),
                          Text(
                            'loyalty.worthSar'.tr(namedArgs: {'amount': summary.pointsValueSar.toStringAsFixed(2)}),
                            style: TextStyle(
                              fontSize: _t.s14,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: _h.s16),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      size: _t.s32,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),


            ],
          ),
        ),
      ),
    );
  }
}