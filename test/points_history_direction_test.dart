// The customer's points history must show a redemption as a LOSS.
//
// The server sends `points` as a magnitude — every row is positive, redemptions
// included — and states the direction in `is_credit`. Inferring direction from
// the sign therefore marked every redemption as a gain ("+250" for points the
// customer had just spent).
import 'package:flutter_test/flutter_test.dart';
import 'package:fastway/features/points/data/models/points_model.dart';

void main() {
  Map<String, dynamic> row(String type, int points, {bool? isCredit}) => {
        'id': '1',
        'type': type,
        'points': points,
        'title': 'x',
        'date': '2026-08-02',
        if (isCredit != null) 'is_credit': isCredit,
      };

  test('a redemption sent as a positive magnitude is NOT shown as earned', () {
    final tx = PointsHistoryModel.fromJson(row('redeemed', 250, isCredit: false));

    expect(tx.points, 250, reason: 'the magnitude is preserved for display');
    expect(tx.isEarned, isFalse, reason: 'a redemption must render with a minus');
  });

  test('an earning is shown as earned', () {
    expect(PointsHistoryModel.fromJson(row('earned', 240, isCredit: true)).isEarned, isTrue);
  });

  test('a tier bonus is shown as earned', () {
    expect(PointsHistoryModel.fromJson(row('tier_bonus', 48, isCredit: true)).isEarned, isTrue);
  });

  test('a reversal is not shown as earned', () {
    expect(PointsHistoryModel.fromJson(row('reversed', 600, isCredit: false)).isEarned, isFalse);
  });

  test('falls back to the sign when the server omits is_credit', () {
    // An older payload must not crash, and must not silently flip to "spent".
    expect(PointsHistoryModel.fromJson(row('earned', 240)).isEarned, isTrue);
    expect(PointsHistoryModel.fromJson(row('redeemed', 0)).isEarned, isFalse);
  });
}
