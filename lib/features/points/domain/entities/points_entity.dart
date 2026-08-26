// lib/features/points/domain/entities/points_entity.dart

import 'package:equatable/equatable.dart';

class PointsSummaryEntity extends Equatable {
  final String memberSince;
  final String memberSinceLabel;
  final String memberSinceLabelAr;
  final int currentPoints;
  final double pointsValueSar;
  final String pointsValueLabel;
  final String pointsValueLabelAr;

  // Stats
  final int totalOrders;
  final double totalSpent;
  final double totalSavedByPoints;
  final int totalPointsEarned;
  final int totalPointsSpent;
  final int totalPointsRestored;
  final int netPointsRedeemed;

  // Redemption
  final bool redemptionEnabled;
  final int redemptionRate;
  final String redemptionRateLabel;
  final String redemptionRateLabelAr;
  final int redemptionMaxPercent;

  final List<PointsHistoryEntity> history;

  /// Real loyalty standing from the API. Null only on a very old backend.
  final TierSummaryEntity? tier;

  const PointsSummaryEntity({
    required this.memberSince,
    required this.memberSinceLabel,
    required this.memberSinceLabelAr,
    required this.currentPoints,
    required this.pointsValueSar,
    required this.pointsValueLabel,
    required this.pointsValueLabelAr,
    required this.totalOrders,
    required this.totalSpent,
    required this.totalSavedByPoints,
    required this.totalPointsEarned,
    required this.totalPointsSpent,
    required this.totalPointsRestored,
    required this.netPointsRedeemed,
    required this.redemptionEnabled,
    required this.redemptionRate,
    required this.redemptionRateLabel,
    required this.redemptionRateLabelAr,
    required this.redemptionMaxPercent,
    required this.history,
    this.tier,
  });

  /// Display name of the current tier, localised. Kept as a getter so the
  /// existing header widgets need no change — it now resolves from real data
  /// instead of the hardcoded 'gold' the model used to invent.
  String levelName(bool isArabic) =>
      isArabic ? (tier?.current?.nameAr ?? '') : (tier?.current?.name ?? '');

  /// Points still needed for the next tier. 0 when already at the top.
  int get pointsToNextLevel => tier?.next?.pointsNeeded ?? 0;

  /// 0.0–1.0 for the progress bar. Comes from the server, which knows the band
  /// boundaries — deriving it client-side from the spendable balance was wrong,
  /// because redeeming points does not move a customer's tier.
  double get progressPercent => ((tier?.progressPercent ?? 0) / 100).clamp(0.0, 1.0);

  /// Extra points percentage this customer earns, e.g. 10 for +10%.
  double get bonusPointsPercent => tier?.current?.bonusPointsPercent ?? 0;

  PointsSummaryEntity copyWith({
    List<PointsHistoryEntity>? history,
  }) {
    return PointsSummaryEntity(
      memberSince: memberSince,
      memberSinceLabel: memberSinceLabel,
      memberSinceLabelAr: memberSinceLabelAr,
      currentPoints: currentPoints,
      pointsValueSar: pointsValueSar,
      pointsValueLabel: pointsValueLabel,
      pointsValueLabelAr: pointsValueLabelAr,
      totalOrders: totalOrders,
      totalSpent: totalSpent,
      totalSavedByPoints: totalSavedByPoints,
      totalPointsEarned: totalPointsEarned,
      totalPointsSpent: totalPointsSpent,
      totalPointsRestored: totalPointsRestored,
      netPointsRedeemed: netPointsRedeemed,
      redemptionEnabled: redemptionEnabled,
      redemptionRate: redemptionRate,
      redemptionRateLabel: redemptionRateLabel,
      redemptionRateLabelAr: redemptionRateLabelAr,
      redemptionMaxPercent: redemptionMaxPercent,
      history: history ?? this.history,
      tier: tier,
    );
  }

  @override
  List<Object?> get props => [
    currentPoints, totalOrders, history, redemptionEnabled
  ];
}

class PointsHistoryEntity extends Equatable {
  final String id;
  final String title;
  final String? titleAr;

  /// The MAGNITUDE of the movement — always positive, redemptions included.
  ///
  /// The server stores every row's points as a positive number and reports the
  /// direction separately, so the sign here carries no meaning. Read [isEarned].
  final int points;
  final DateTime date;

  /// Direction as reported by the server (`is_credit`), or null on an older
  /// payload that predates the field.
  final bool? isCredit;

  const PointsHistoryEntity({
    required this.id,
    required this.title,
    this.titleAr,
    required this.points,
    required this.date,
    this.isCredit,
  });

  /// Did this row ADD points?
  ///
  /// Was `points > 0`, which was always true — the server sends magnitudes, so
  /// every redemption rendered with a "+" as if the customer had gained points.
  /// The server now states the direction; the sign check only remains as a
  /// fallback for a payload without the field.
  bool get isEarned => isCredit ?? (points > 0);

  @override
  List<Object?> get props => [id, title, titleAr, points, date, isCredit];
}

/// One loyalty tier (رياضي / محترف / بطل / أسطورة) as described by the API.
class TierEntity extends Equatable {
  final String slug;
  final String name;
  final String nameAr;
  final String? color;
  final int minPoints;

  /// null means the band is open-ended — the top tier.
  final int? maxPoints;

  final double bonusPointsPercent;
  final double extraDiscountPercent;
  final List<String> benefits;
  final List<String> benefitsAr;

  const TierEntity({
    required this.slug,
    required this.name,
    required this.nameAr,
    this.color,
    required this.minPoints,
    this.maxPoints,
    required this.bonusPointsPercent,
    required this.extraDiscountPercent,
    required this.benefits,
    required this.benefitsAr,
  });

  String displayName(bool isArabic) => isArabic ? nameAr : name;
  List<String> displayBenefits(bool isArabic) => isArabic ? benefitsAr : benefits;

  bool get hasBonusPoints => bonusPointsPercent > 0;
  bool get hasExtraDiscount => extraDiscountPercent > 0;

  @override
  List<Object?> get props => [slug, minPoints, maxPoints, bonusPointsPercent, extraDiscountPercent];
}

/// The next tier up, and how far away it is.
class NextTierEntity extends Equatable {
  final String slug;
  final String name;
  final String nameAr;
  final String? color;
  final int pointsNeeded;

  const NextTierEntity({
    required this.slug,
    required this.name,
    required this.nameAr,
    this.color,
    required this.pointsNeeded,
  });

  String displayName(bool isArabic) => isArabic ? nameAr : name;

  @override
  List<Object?> get props => [slug, pointsNeeded];
}

/// The customer's loyalty standing plus the full ladder.
class TierSummaryEntity extends Equatable {
  /// False when the store has tiers switched off — hide the tier UI entirely.
  final bool enabled;

  final TierEntity? current;

  /// Points EARNED inside the rolling window. Deliberately NOT the spendable
  /// balance: redeeming points never lowers a tier, so these two numbers diverge
  /// and must be labelled differently in the UI.
  final int tierPoints;

  final NextTierEntity? next;

  /// 0–100, progress through the CURRENT band.
  final double progressPercent;

  final String basis;
  final int windowMonths;
  final List<TierEntity> allTiers;

  const TierSummaryEntity({
    required this.enabled,
    this.current,
    required this.tierPoints,
    this.next,
    required this.progressPercent,
    required this.basis,
    required this.windowMonths,
    required this.allTiers,
  });

  bool get isTopTier => next == null;

  @override
  List<Object?> get props => [enabled, current, tierPoints, next, progressPercent];
}
