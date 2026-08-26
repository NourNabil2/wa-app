// lib/features/points/data/models/points_model.dart

import '../../domain/entities/points_entity.dart';

class PointsSummaryModel extends PointsSummaryEntity {
  const PointsSummaryModel({
    required super.memberSince,
    required super.memberSinceLabel,
    required super.memberSinceLabelAr,
    required super.currentPoints,
    required super.pointsValueSar,
    required super.pointsValueLabel,
    required super.pointsValueLabelAr,
    required super.totalOrders,
    required super.totalSpent,
    required super.totalSavedByPoints,
    required super.totalPointsEarned,
    required super.totalPointsSpent,
    required super.totalPointsRestored,
    required super.netPointsRedeemed,
    required super.redemptionEnabled,
    required super.redemptionRate,
    required super.redemptionRateLabel,
    required super.redemptionRateLabelAr,
    required super.redemptionMaxPercent,
    required super.history,
    super.tier,
  });

  factory PointsSummaryModel.fromJson(Map<String, dynamic> json) {
    String ss(dynamic v, [String fallback = '']) {
      if (v == null) return fallback;
      if (v is String) return v;
      if (v is Map) return v['en']?.toString() ?? v.values.firstOrNull?.toString() ?? fallback;
      return v.toString();
    }

    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final redemption = json['redemption'] as Map<String, dynamic>? ?? {};

    return PointsSummaryModel(
      memberSince: ss(json['member_since']),
      memberSinceLabel: ss(json['member_since_label']),
      memberSinceLabelAr: ss(json['member_since_label_ar']),
      currentPoints: json['current_points'] as int? ?? 0,
      pointsValueSar: (json['points_value_sar'] as num?)?.toDouble() ?? 0.0,
      pointsValueLabel: ss(json['points_value_label']),
      pointsValueLabelAr: ss(json['points_value_label_ar']),

      totalOrders: stats['total_orders'] as int? ?? 0,
      totalSpent: (stats['total_spent'] as num?)?.toDouble() ?? 0.0,
      totalSavedByPoints: (stats['total_saved_by_points'] as num?)?.toDouble() ?? 0.0,
      totalPointsEarned: stats['total_points_earned'] as int? ?? 0,
      totalPointsSpent: stats['total_points_spent'] as int? ?? 0,
      totalPointsRestored: stats['total_points_restored'] as int? ?? 0,
      netPointsRedeemed: stats['net_points_redeemed'] as int? ?? 0,

      redemptionEnabled: redemption['enabled'] as bool? ?? false,
      redemptionRate: (redemption['rate'] as num?)?.toInt() ?? 100,
      redemptionRateLabel: ss(redemption['rate_label']),
      redemptionRateLabelAr: ss(redemption['rate_label_ar']),
      redemptionMaxPercent: (redemption['max_percent'] as num?)?.toInt() ?? 0,

      history: (json['history'] as List<dynamic>?)
          ?.map((e) => PointsHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],

      // Real loyalty standing. This used to be a hardcoded mock ('gold', 500) —
      // the endpoint now returns the customer's actual tier, the next one up, and
      // the whole ladder.
      tier: json['tier'] is Map<String, dynamic>
          ? TierSummaryModel.fromJson(json['tier'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PointsHistoryModel extends PointsHistoryEntity {
  const PointsHistoryModel({
    required super.id,
    required super.title,
    super.titleAr,
    required super.points,
    required super.date,
    super.isCredit,
  });

  factory PointsHistoryModel.fromJson(Map<String, dynamic> json) {
    String ss(dynamic v, [String fallback = '']) {
      if (v == null) return fallback;
      if (v is String) return v;
      if (v is Map) return v['en']?.toString() ?? v.values.firstOrNull?.toString() ?? fallback;
      return v.toString();
    }
    return PointsHistoryModel(
      id: json['id']?.toString() ?? '',
      title: ss(json['title']),
      titleAr: json['title_ar'] != null ? ss(json['title_ar']) : null,
      points: json['points'] as int? ?? 0,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      // Direction comes from the server. Left null when absent so the entity
      // falls back to the old sign check rather than defaulting a redemption
      // to "earned".
      isCredit: json['is_credit'] as bool?,
    );
  }
}

class TierModel extends TierEntity {
  const TierModel({
    required super.slug,
    required super.name,
    required super.nameAr,
    super.color,
    required super.minPoints,
    super.maxPoints,
    required super.bonusPointsPercent,
    required super.extraDiscountPercent,
    required super.benefits,
    required super.benefitsAr,
  });

  static List<String> _strings(dynamic v) => (v as List<dynamic>?)
      ?.map((e) => e.toString())
      .toList() ?? const [];

  factory TierModel.fromJson(Map<String, dynamic> json) => TierModel(
        slug: json['slug']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        nameAr: json['name_ar']?.toString() ?? '',
        color: json['color']?.toString(),
        minPoints: (json['min_points'] as num?)?.toInt() ?? 0,
        // null is meaningful: the band is open-ended (top tier).
        maxPoints: (json['max_points'] as num?)?.toInt(),
        bonusPointsPercent: (json['bonus_points_percent'] as num?)?.toDouble() ?? 0.0,
        extraDiscountPercent: (json['extra_discount_percent'] as num?)?.toDouble() ?? 0.0,
        benefits: _strings(json['benefits']),
        benefitsAr: _strings(json['benefits_ar']),
      );
}

class NextTierModel extends NextTierEntity {
  const NextTierModel({
    required super.slug,
    required super.name,
    required super.nameAr,
    super.color,
    required super.pointsNeeded,
  });

  factory NextTierModel.fromJson(Map<String, dynamic> json) => NextTierModel(
        slug: json['slug']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        nameAr: json['name_ar']?.toString() ?? '',
        color: json['color']?.toString(),
        pointsNeeded: (json['points_needed'] as num?)?.toInt() ?? 0,
      );
}

class TierSummaryModel extends TierSummaryEntity {
  const TierSummaryModel({
    required super.enabled,
    super.current,
    required super.tierPoints,
    super.next,
    required super.progressPercent,
    required super.basis,
    required super.windowMonths,
    required super.allTiers,
  });

  factory TierSummaryModel.fromJson(Map<String, dynamic> json) => TierSummaryModel(
        enabled: json['enabled'] as bool? ?? false,
        current: json['current'] is Map<String, dynamic>
            ? TierModel.fromJson(json['current'] as Map<String, dynamic>)
            : null,
        tierPoints: (json['tier_points'] as num?)?.toInt() ?? 0,
        next: json['next'] is Map<String, dynamic>
            ? NextTierModel.fromJson(json['next'] as Map<String, dynamic>)
            : null,
        progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0.0,
        basis: json['basis']?.toString() ?? 'rolling',
        windowMonths: (json['window_months'] as num?)?.toInt() ?? 12,
        allTiers: (json['all_tiers'] as List<dynamic>?)
                ?.map((e) => TierModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
