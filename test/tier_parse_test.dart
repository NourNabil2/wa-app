// Parses a REAL captured /api/v1/points payload through the production model,
// so a shape change on the backend fails here rather than in the app.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fastway/features/points/data/models/points_model.dart';

void main() {
  test('PointsSummaryModel parses a real API payload including the tier block', () {
    final raw = File('test/fixtures/points_payload.json').readAsStringSync();
    final data = (jsonDecode(raw) as Map<String, dynamic>)['data'] as Map<String, dynamic>;

    final summary = PointsSummaryModel.fromJson(data);

    // Tier block
    expect(summary.tier, isNotNull);
    expect(summary.tier!.enabled, isTrue);
    expect(summary.tier!.current!.slug, 'batal');
    expect(summary.tier!.current!.nameAr, 'بطل');
    expect(summary.tier!.current!.bonusPointsPercent, 10.0);
    expect(summary.tier!.tierPoints, 1240);
    expect(summary.tier!.next!.pointsNeeded, 260);
    expect(summary.tier!.basis, 'rolling');
    expect(summary.tier!.windowMonths, 12);
    expect(summary.tier!.allTiers.length, 4);

    // The top tier is open-ended — null must survive as null, not become 0.
    final legend = summary.tier!.allTiers.last;
    expect(legend.slug, 'ustura');
    expect(legend.maxPoints, isNull);
    expect(legend.extraDiscountPercent, 5.0);
    expect(legend.benefitsAr.length, 2);

    // Derived getters the widgets rely on
    expect(summary.levelName(true), 'بطل');
    expect(summary.levelName(false), 'Champion');
    expect(summary.pointsToNextLevel, 260);
    expect(summary.progressPercent, closeTo(0.48, 0.001));
    expect(summary.bonusPointsPercent, 10.0);

    // Redemption label reads correctly at a non-default rate
    expect(summary.redemptionRateLabel, '100 points = 5 SAR');
  });

  test('a payload with no tier block degrades gracefully', () {
    final summary = PointsSummaryModel.fromJson({'current_points': 10});
    expect(summary.tier, isNull);
    expect(summary.levelName(true), '');
    expect(summary.pointsToNextLevel, 0);
    expect(summary.progressPercent, 0.0);
  });
}
