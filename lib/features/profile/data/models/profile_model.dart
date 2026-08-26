// lib/features/profile/data/models/profile_model.dart

import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.avatarUrl,
    super.totalOrders,
    super.rewardPoints,
    super.pointsValueSar,
    super.totalPointsEarned,
    super.tierName,
    super.tierNameAr,
    super.tierColor,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      totalOrders: json['total_orders'] as int? ?? 0,
      rewardPoints: json['points'] as int? ?? 0,
      pointsValueSar: (json['points_value_sar'] as num?)?.toDouble() ?? 0.0,
      totalPointsEarned: json['total_points_earned'] as int? ?? 0,
      // `tier` is an object (or null). It used to be a plain string on older
      // backends, so guard the type rather than casting blindly.
      tierName:   json['tier'] is Map ? (json['tier']['name'] as String?) : null,
      tierNameAr: json['tier'] is Map ? (json['tier']['name_ar'] as String?) : null,
      tierColor:  json['tier'] is Map ? (json['tier']['color'] as String?) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'avatar_url': avatarUrl,
    'total_orders': totalOrders,
    'points': rewardPoints,
    'points_value_sar': pointsValueSar,
    'total_points_earned': totalPointsEarned,
  };
}

class AppSettingsModel extends AppSettingsEntity {
  const AppSettingsModel({
    super.language,
    super.themeMode,
    super.notificationsEnabled,
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      language: json['language'] as String? ?? 'ar',
      themeMode: json['theme_mode'] as String? ?? 'light',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'language': language,
    'theme_mode': themeMode,
    'notifications_enabled': notificationsEnabled,
  };
}