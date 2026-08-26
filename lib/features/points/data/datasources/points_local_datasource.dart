// // lib/features/points/data/datasources/points_local_datasource.dart
//
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../models/points_model.dart';
// import '../../domain/entities/points_entity.dart';
// import 'package:easy_localization/easy_localization.dart';
//
// abstract class PointsLocalDataSource {
//   Future<PointsSummaryModel> getPointsSummary();
//   Future<String> redeemReward(String rewardId);
// }
//
// class PointsLocalDataSourceImpl implements PointsLocalDataSource {
//   final SharedPreferences _prefs;
//   static const String _pointsKey = 'points_data';
//
//   PointsLocalDataSourceImpl(this._prefs);
//
//   static const _mockImageUrl =
//       'https://m.media-amazon.com/images/I/71XvwXEIyHL._AC_SL1500_.jpg';
//
//   static final List<RewardEntity> _mockRewards = [
//     const RewardModel(
//       id: 'r1', title: 'كوبون خصم 50 ر.س',
//       imageUrl: _mockImageUrl,
//       discountValue: 50, requiredPoints: 500, isAvailable: true,
//     ),
//     const RewardModel(
//       id: 'r2', title: 'كوبون خصم 50 ر.س',
//       imageUrl: _mockImageUrl,
//       discountValue: 50, requiredPoints: 500, isAvailable: true,
//     ),
//     const RewardModel(
//       id: 'r3', title: 'كوبون خصم 50 ر.س',
//       imageUrl: _mockImageUrl,
//       discountValue: 50, requiredPoints: 500, isAvailable: false,
//     ),
//     const RewardModel(
//       id: 'r4', title: 'كوبون خصم 50 ر.س',
//       imageUrl: _mockImageUrl,
//       discountValue: 50, requiredPoints: 500, isAvailable: true,
//     ),
//   ];
//
//   static final List<PointsHistoryEntity> _mockHistory = [
//     PointsHistoryModel(
//       id: 'h1', title: 'loyalty.transaction.earned'.tr(),
//       points: 64, date: DateTime(2026, 2, 25),
//     ),
//     PointsHistoryModel(
//       id: 'h2', title: 'loyalty.transaction.redeemed'.tr(),
//       points: -500, date: DateTime(2026, 2, 25),
//     ),
//   ];
//
//   @override
//   Future<PointsSummaryModel> getPointsSummary() async {
//     await Future.delayed(const Duration(milliseconds: 300));
//
//     final json = _prefs.getString(_pointsKey);
//     int currentPoints = 2450;
//     int redeemedCount = 5;
//     int totalOrders = 12;
//
//     if (json != null) {
//       final saved = jsonDecode(json) as Map<String, dynamic>;
//       currentPoints = saved['current_points'] as int? ?? 2450;
//       redeemedCount = saved['redeemed_count'] as int? ?? 5;
//       totalOrders = saved['total_orders'] as int? ?? 12;
//     }
//
//     // Determine level based on points
//     final level = _getLevel(currentPoints);
//     final nextLevelPoints = _getNextLevelGap(currentPoints);
//
//     // Update reward availability based on current points
//     final rewards = _mockRewards.map((r) {
//       return RewardModel(
//         id: r.id, title: r.title, imageUrl: r.imageUrl,
//         discountValue: r.discountValue, requiredPoints: r.requiredPoints,
//         isAvailable: r.id == 'r3' ? false : currentPoints >= r.requiredPoints,
//       );
//     }).toList();
//
//     return PointsSummaryModel(
//       currentPoints: currentPoints,
//       nextLevelPoints: nextLevelPoints,
//       level: level,
//       redeemedCount: redeemedCount,
//       totalOrders: totalOrders,
//       availableRewards: rewards,
//       history: _mockHistory,
//     );
//   }
//
//   @override
//   Future<String> redeemReward(String rewardId) async {
//     await Future.delayed(const Duration(milliseconds: 800));
//
//     final reward = _mockRewards.firstWhere(
//           (r) => r.id == rewardId,
//       orElse: () => throw Exception('Reward not found'),
//     );
//
//     if (!reward.isAvailable) throw Exception('Reward not available');
//
//     // Deduct points
//     final json = _prefs.getString(_pointsKey);
//     int currentPoints = 2450;
//     int redeemedCount = 5;
//     int totalOrders = 12;
//
//     if (json != null) {
//       final saved = jsonDecode(json) as Map<String, dynamic>;
//       currentPoints = saved['current_points'] as int? ?? 2450;
//       redeemedCount = saved['redeemed_count'] as int? ?? 5;
//       totalOrders = saved['total_orders'] as int? ?? 12;
//     }
//
//     if (currentPoints < reward.requiredPoints) {
//       throw Exception('نقاطك غير كافية لاستبدال هذه المكافأة');
//     }
//
//     final updated = {
//       'current_points': currentPoints - reward.requiredPoints,
//       'redeemed_count': redeemedCount + 1,
//       'total_orders': totalOrders,
//     };
//     await _prefs.setString(_pointsKey, jsonEncode(updated));
//
//     return 'تم استبدال المكافأة بنجاح! كوبون: FAST-${rewardId.toUpperCase()}';
//   }
//
//   String _getLevel(int points) {
//     if (points >= 5000) return 'بلاتيني';
//     if (points >= 2000) return 'ذهبي';
//     if (points >= 1000) return 'فضي';
//     return 'برونزي';
//   }
//
//   int _getNextLevelGap(int points) {
//     if (points >= 5000) return 0;
//     if (points >= 2000) return 5000 - points;
//     if (points >= 1000) return 2000 - points;
//     return 1000 - points;
//   }
// }