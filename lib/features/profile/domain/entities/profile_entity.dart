// lib/features/profile/domain/entities/profile_entity.dart

import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final int totalOrders;
  final int rewardPoints;
  final double pointsValueSar;
  final int totalPointsEarned;

  /// Loyalty tier, localised name + colour. Null when the customer has no tier
  /// or the store has tiers switched off.
  final String? tierName;
  final String? tierNameAr;
  final String? tierColor;

  const ProfileEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.totalOrders = 0,
    this.rewardPoints = 0,
    this.pointsValueSar = 0.0,
    this.totalPointsEarned = 0,
    this.tierName,
    this.tierNameAr,
    this.tierColor,
  });

  /// Localised tier name, or null when the customer has no tier.
  String? tierLabel(bool isArabic) => isArabic ? tierNameAr : tierName;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props =>
      [id, name, email, phone, avatarUrl, totalOrders, rewardPoints, pointsValueSar, totalPointsEarned];
}

class AppSettingsEntity extends Equatable {
  final String language;      // 'ar' | 'en'
  final String themeMode;     // 'light' | 'dark' | 'system'
  final bool notificationsEnabled;

  const AppSettingsEntity({
    this.language = 'ar',
    this.themeMode = 'light',
    this.notificationsEnabled = true,
  });

  @override
  List<Object?> get props => [language, themeMode, notificationsEnabled];
}