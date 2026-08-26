// lib/features/checkout/presentation/widgets/points_redemption_card.dart
//
// تصميم استبدال النقاط — خانة يدوية + أزرار نسب سريعة
// المفاتيح من الـ API:
//   'available_points'  — الرصيد
//   'max_points'        — أقصى نقاط ممكن تستخدمها
//   'rate'              — معدل التحويل (100 = 1 ريال)
//   'rate_label'        — label بالإنجليزي
//   'rate_label_ar'     — label بالعربي

import 'package:fastway/core/theme/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/utils/assets.dart';
import 'package:fastway/core/widgets/CustomIcon.dart';
import 'package:fastway/core/widgets/sar_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/app_size.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';

class PointsRedemptionCard extends StatefulWidget {
  final CheckoutLoaded state;
  final CheckoutCubit cubit;

  const PointsRedemptionCard({
    super.key,
    required this.state,
    required this.cubit,
  });

  @override
  State<PointsRedemptionCard> createState() => _PointsRedemptionCardState();
}

class _PointsRedemptionCardState extends State<PointsRedemptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;
  late TextEditingController _pointsController;
  late TextEditingController _sarController;
  final FocusNode _pointsFocusNode = FocusNode();
  final FocusNode _sarFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    final currentPoints = widget.state.pointsToUse;
    final pointsInfo = widget.state.checkout.pointsInfo;
    final num rate = (pointsInfo?['rate'] as num?) ?? 100;

    _pointsController = TextEditingController(
      text: currentPoints > 0 ? currentPoints.toString() : '',
    );
    _sarController = TextEditingController(
      text: currentPoints > 0 ? (currentPoints / rate).toStringAsFixed(2) : '',
    );

    if (currentPoints > 0) {
      _isExpanded = true;
      _animController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant PointsRedemptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newPoints = widget.state.pointsToUse;
    final pointsInfo = widget.state.checkout.pointsInfo;
    final num rate = (pointsInfo?['rate'] as num?) ?? 100;

    if (!_pointsFocusNode.hasFocus && !_sarFocusNode.hasFocus) {
      final currentPointsParsed = int.tryParse(_pointsController.text) ?? 0;
      if (newPoints != currentPointsParsed) {
        _pointsController.text = newPoints > 0 ? newPoints.toString() : '';
        _sarController.text =
            newPoints > 0 ? (newPoints / rate).toStringAsFixed(2) : '';
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _pointsController.dispose();
    _sarController.dispose();
    _pointsFocusNode.dispose();
    _sarFocusNode.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
        widget.cubit.updatePointsToUse(0);
        _pointsController.clear();
        _sarController.clear();
      }
    });
  }

  void _setPoints(int points) {
    final pointsInfo = widget.state.checkout.pointsInfo;
    if (pointsInfo == null) return;
    final int maxRedeemable = (pointsInfo['max_points'] as num?)?.toInt() ?? 0;
    final num rate = (pointsInfo['rate'] as num?) ?? 100;

    final clamped = points.clamp(0, maxRedeemable);
    widget.cubit.updatePointsToUse(clamped);

    _pointsController.text = clamped > 0 ? clamped.toString() : '';
    _sarController.text =
        clamped > 0 ? (clamped / rate).toStringAsFixed(2) : '';
  }

  void _onPointsFieldChanged(String value) {
    final pointsInfo = widget.state.checkout.pointsInfo;
    if (pointsInfo == null) return;
    final int maxRedeemable = (pointsInfo['max_points'] as num?)?.toInt() ?? 0;
    final num rate = (pointsInfo['rate'] as num?) ?? 100;

    final parsedPoints = int.tryParse(value) ?? 0;
    final clamped = parsedPoints.clamp(0, maxRedeemable);

    if (parsedPoints == 0 && value.isEmpty) {
      _sarController.text = '';
    } else {
      _sarController.text = (clamped / rate).toStringAsFixed(2);
    }

    widget.cubit.updatePointsToUse(clamped);
  }

  void _onSarFieldChanged(String value) {
    final pointsInfo = widget.state.checkout.pointsInfo;
    if (pointsInfo == null) return;
    final int maxRedeemable = (pointsInfo['max_points'] as num?)?.toInt() ?? 0;
    final num rate = (pointsInfo['rate'] as num?) ?? 100;

    final sar = double.tryParse(value) ?? 0.0;
    final parsedPoints = (sar * rate).round();
    final clamped = parsedPoints.clamp(0, maxRedeemable);

    if (sar == 0.0 && value.isEmpty) {
      _pointsController.text = '';
    } else {
      _pointsController.text = clamped.toString();
    }

    widget.cubit.updatePointsToUse(clamped);
  }

  void _onPointsFieldSubmitted(String value) {
    _pointsFocusNode.unfocus();
  }

  void _onSarFieldSubmitted(String value) {
    _sarFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final v = AppSizeVertical.instance;
    final h = AppSizeHorizontal.instance;
    final t = TextSizeApp.instance;

    final pointsInfo = widget.state.checkout.pointsInfo;
    if (pointsInfo == null) return const SizedBox.shrink();

    final bool enabled = pointsInfo['enabled'] as bool? ?? false;
    final int balance = (pointsInfo['available_points'] as num?)?.toInt() ?? 0;
    final int maxRedeemable = (pointsInfo['max_points'] as num?)?.toInt() ?? 0;
    final num rate = (pointsInfo['rate'] as num?) ?? 100;

    if (!enabled || balance <= 0) return const SizedBox.shrink();

    if (maxRedeemable <= 0) {
      return _buildNotEnoughBanner(h, v, t, balance);
    }

    final int pointsToUse = widget.state.pointsToUse;
    final double discountSar = pointsToUse / rate;
    final double maxDiscountSar = maxRedeemable / rate;

    // Colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color themeDark = ColorsManager.primaryColor;
    final Color themeMid = ColorsManager.primaryColor;
    const Color greenAccent = ColorsManager.primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ─────────────────────────────────────────
          InkWell(
            onTap: _toggleExpand,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: h.s16, vertical: v.s12),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.stars_rounded,
                      color: themeDark,
                      size: 26,
                    ),
                  ),
                  SizedBox(width: h.s10),

                  // Title + balance
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'checkout.redeem_points'.tr(),
                          style: TextStyle(
                            fontSize: t.s14,
                            fontWeight: FontWeight.w700,
                            color: ColorsManager.defaultText,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'checkout.points_your_balance'.tr(args: [
                                balance.toString(),
                                (balance / rate).toStringAsFixed(2),
                              ]),
                              style: TextStyle(
                                fontSize: t.s12,
                                color: ColorsManager.defaultTextSecondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            SarText(
                              price:
                                  '', // The value is already in the tr() above, we just need the symbol
                              style: TextStyle(
                                fontSize: t.s12,
                                color: ColorsManager.defaultTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Toggle
                  Transform.scale(
                    scale: 0.8,
                    child: Switch.adaptive(
                      value: _isExpanded,
                      onChanged: (_) => _toggleExpand(),
                      activeColor: themeDark,
                      activeTrackColor: themeMid.withValues(alpha: 0.35),
                      inactiveThumbColor: Colors.grey.shade400,
                      inactiveTrackColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable Content ─────────────────────────────
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: -1,
            child: Column(
              children: [
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? Colors.white12 : Colors.grey.shade100,
                  indent: h.s16,
                  endIndent: h.s16,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(h.s16, v.s12, h.s16, v.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Input fields ────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Points input
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black12 : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Padding(
                                    padding:
                                        EdgeInsets.only(right: 8, left: h.s10),
                                    child: Icon(Icons.stars_rounded, color: themeDark, size: 20),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _pointsController,
                                      focusNode: _pointsFocusNode,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(
                                            maxRedeemable.toString().length +
                                                1),
                                      ],
                                      style: TextStyle(
                                        fontSize: t.s14,
                                        fontWeight: FontWeight.w600,
                                        color: ColorsManager.defaultText,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            'checkout.points_enter_hint'.tr(),
                                        hintStyle: TextStyle(
                                          fontSize: t.s12,
                                          color: ColorsManager
                                              .defaultTextSecondary
                                              .withValues(alpha: 0.6),
                                          fontWeight: FontWeight.w400,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                        isDense: true,
                                      ),
                                      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                                      onChanged: _onPointsFieldChanged,
                                      onSubmitted: _onPointsFieldSubmitted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: h.s4),
                            child: Icon(Icons.sync_alt_rounded, color: themeMid, size: 20),
                          ),

                          // SAR input
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black12 : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Padding(
                                    padding:
                                        EdgeInsets.only(right: 8, left: h.s10),
                                    child: const SarSymbol(size: 16),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _sarController,
                                      focusNode: _sarFocusNode,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d+\.?\d{0,2}')),
                                      ],
                                      style: TextStyle(
                                        fontSize: t.s14,
                                        fontWeight: FontWeight.w600,
                                        color: greenAccent,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'checkout.points_sar_hint'
                                            .tr(),
                                        hintStyle: TextStyle(
                                          fontSize: t.s12,
                                          color: ColorsManager
                                              .defaultTextSecondary
                                              .withValues(alpha: 0.6),
                                          fontWeight: FontWeight.w400,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                        isDense: true,
                                      ),
                                      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                                      onChanged: _onSarFieldChanged,
                                      onSubmitted: _onSarFieldSubmitted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: v.s10),

                      // ── Quick-select chips ───────────────────
                      Row(
                        children: [
                          _buildChip(
                            label: '25%',
                            points: (maxRedeemable * 0.25).round(),
                            isSelected:
                                pointsToUse == (maxRedeemable * 0.25).round() &&
                                    pointsToUse > 0,
                            t: t,
                            themeDark: themeDark,
                            themeMid: themeMid,
                          ),
                          const SizedBox(width: 6),
                          _buildChip(
                            label: '50%',
                            points: (maxRedeemable * 0.50).round(),
                            isSelected:
                                pointsToUse == (maxRedeemable * 0.50).round() &&
                                    pointsToUse > 0,
                            t: t,
                            themeDark: themeDark,
                            themeMid: themeMid,
                          ),
                          const SizedBox(width: 6),
                          _buildChip(
                            label: '75%',
                            points: (maxRedeemable * 0.75).round(),
                            isSelected:
                                pointsToUse == (maxRedeemable * 0.75).round() &&
                                    pointsToUse > 0,
                            t: t,
                            themeDark: themeDark,
                            themeMid: themeMid,
                          ),
                          const SizedBox(width: 6),
                          _buildChip(
                            label: 'checkout.points_max'.tr(),
                            points: maxRedeemable,
                            isSelected: pointsToUse == maxRedeemable,
                            isMax: true,
                            t: t,
                            themeDark: themeDark,
                            themeMid: themeMid,
                            greenAccent: greenAccent,
                          ),
                        ],
                      ),

                      SizedBox(height: v.s8),

                      // ── Rate info ─────────────────────────────
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${_getRateLabel(context, pointsInfo)}  ·  ${'checkout.points_max_discount'.tr(args: [
                                    maxDiscountSar.toStringAsFixed(2)
                                  ])}',
                              style: TextStyle(
                                fontSize: t.s10,
                                color: ColorsManager.defaultTextSecondary
                                    .withValues(alpha: 0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(width: 4),
                            SarText(
                              price: '',
                              style: TextStyle(
                                fontSize: t.s10,
                                color: ColorsManager.defaultTextSecondary
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Chip builder ─────────────────────────────────────────────────────────

  Widget _buildChip({
    required String label,
    required int points,
    required bool isSelected,
    bool isMax = false,
    required TextSizeApp t,
    required Color themeDark,
    required Color themeMid,
    Color? greenAccent,
  }) {
    final v = AppSizeVertical.instance;
    final h = AppSizeHorizontal.instance;

    final activeColor = isMax ? (greenAccent ?? themeDark) : themeDark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isSelected) {
            _setPoints(0);
          } else {
            _setPoints(points);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : activeColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : activeColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: t.s12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : activeColor.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── "Not enough points" banner ───────────────────────────────────────────

  Widget _buildNotEnoughBanner(
    AppSizeHorizontal h,
    AppSizeVertical v,
    TextSizeApp t,
    int balance,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: h.s16, vertical: v.s12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8D5A3)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const CustomIcon(
              assetPath: Assets.coinsIcon,
              size: 18,
              noColor: true,
            ),
          ),
          SizedBox(width: h.s10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'checkout.points_balance'.tr(args: [balance.toString()]),
                  style: TextStyle(
                    fontSize: t.s12,
                    fontWeight: FontWeight.w600,
                    color: ColorsManager.defaultText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'checkout.points_not_enough'.tr(),
                  style: TextStyle(
                    fontSize: t.s12,
                    color: ColorsManager.defaultTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// يجيب الـ rate label حسب اللغة الحالية
  String _getRateLabel(BuildContext context, Map<String, dynamic> pointsInfo) {
    // rate_label / rate_label_ar can be a plain String OR a localised Map {"en":"...","ar":"..."}
    String safeStr(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      if (v is Map) {
        return v['en']?.toString() ?? v.values.firstOrNull?.toString() ?? '';
      }
      return v.toString();
    }

    final fallback = 'checkout.points.rate_label'.tr(args: ['100', '1']);
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ar') {
      final ar = safeStr(pointsInfo['rate_label_ar']);
      if (ar.isNotEmpty) return ar;
      final en = safeStr(pointsInfo['rate_label']);
      if (en.isNotEmpty) return en;
      return fallback;
    }
    final en = safeStr(pointsInfo['rate_label']);
    return en.isNotEmpty ? en : fallback;
  }
}
