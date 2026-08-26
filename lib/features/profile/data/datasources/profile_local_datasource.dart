// lib/features/profile/data/datasources/profile_local_datasource.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile_model.dart';

abstract class ProfileLocalDataSource {
  Future<ProfileModel> getProfile();
  Future<AppSettingsModel> getSettings();
  Future<AppSettingsModel> updateSettings(AppSettingsModel settings);
  Future<void> logout();
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  final SharedPreferences _prefs;
  static const String _settingsKey = 'app_settings';
  static const String _profileKey = 'user_profile';

  ProfileLocalDataSourceImpl(this._prefs);

  @override
  Future<ProfileModel> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final json = _prefs.getString(_profileKey);
    if (json != null) {
      return ProfileModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
    }

    // Default mock profile matching the screenshots
    return const ProfileModel(
      id: 'u1',
      name: 'أحمد محمد',
      email: 'ahmed@example.com',
      phone: '0501234567',
      totalOrders: 12,
      rewardPoints: 2450,
    );
  }

  @override
  Future<AppSettingsModel> getSettings() async {
    final json = _prefs.getString(_settingsKey);
    if (json != null) {
      return AppSettingsModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
    }
    return const AppSettingsModel();
  }

  @override
  Future<AppSettingsModel> updateSettings(AppSettingsModel settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    return settings;
  }

  @override
  Future<void> logout() async {
    // Clear all user-related keys
    await _prefs.remove(_profileKey);
    await _prefs.remove(_settingsKey);
    await _prefs.remove('cart_data');
    await _prefs.remove('checkout_data');
    await _prefs.remove('points_data');
  }
}