// lib/core/db/shared_pref_helper.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/user_data/user_model.dart';
import '../utils/app_constans.dart';

/// Two-tier storage:
///  • [_secure]  — FlutterSecureStorage  → sensitive data (token, user JSON)
///  • [_prefs]   — SharedPreferences     → non-sensitive settings (theme, lang, notifs)
class SharedPrefHelper {
  // ── Secure storage (encrypted) ────────────────────────────
  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: false),
    webOptions: WebOptions(
      dbName: 'fastway_secure',
      publicKey: 'fastway_pk',
    ),
  );

  // ── Plain storage (fast, non-sensitive) ───────────────────
  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  // ══════════════════════════════════════════════════════════
  // SECURE — JSON (user data, tokens)
  // ══════════════════════════════════════════════════════════

  static Future<bool> saveJson({
    required String key,
    required Map<String, dynamic> value,
  }) async {
    try {
      final encoded = jsonEncode(value);
      // On web, use SharedPreferences (localStorage) instead of IndexedDB
      if (kIsWeb) {
        final prefs = await _prefs;
        await prefs.setString('secure_$key', encoded);
        return true;
      }
      await _secure.write(key: key, value: encoded);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[SharedPrefHelper] saveJson error for $key: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getJson({required String key}) async {
    try {
      // On web, IndexedDB (flutter_secure_storage) can fail silently in debug
      // Chrome sessions. Fall back to localStorage (SharedPreferences) instead.
      if (kIsWeb) {
        final prefs = await _prefs;
        final raw = prefs.getString('secure_$key');
        if (raw != null && raw.isNotEmpty) {
          return jsonDecode(raw) as Map<String, dynamic>;
        }
        return null;
      }
      final raw = await _secure.read(key: key);
      if (raw != null && raw.isNotEmpty) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[SharedPrefHelper] getJson error for $key: $e');
      return null;
    }
  }

  static Future<UserModel?> getUserData() async {
    try {
      final json = await getJson(key: AppConstants.userKey);
      if (json != null) return UserModel.fromJson(json);
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Secure — String (e.g. auth token) ────────────────────

  static Future<String?> getSecureString({required String key}) async {
    try {
      return await _secure.read(key: key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveSecureString({
    required String key,
    required String value,
  }) async {
    try {
      await _secure.write(key: key, value: value);
    } catch (_) {}
  }

  // ── Secure — Delete ───────────────────────────────────────

  static Future<void> delete({required String key}) async {
    try {
      if (kIsWeb) {
        final prefs = await _prefs;
        await prefs.remove('secure_$key');
        return;
      }
      await _secure.delete(key: key);
    } catch (e) {
      if (kDebugMode) debugPrint('[SharedPrefHelper] delete error for $key: $e');
    }
  }

  static Future<void> clearAll() async {
    try {
      await _secure.deleteAll();
      final prefs = await _prefs;
      await prefs.clear();
    } catch (_) {}
  }

  static Future<bool> containsKey({required String key}) async {
    try {
      return await _secure.containsKey(key: key);
    } catch (_) {
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════
  // PLAIN — String  (language code, theme name, etc.)
  // ══════════════════════════════════════════════════════════

  static Future<void> saveString({
    required String key,
    required String value,
  }) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(key, value);
    } catch (_) {}
  }

  static Future<String?> getString({required String key}) async {
    try {
      final prefs = await _prefs;
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════
  // PLAIN — Bool  (notifications, any toggle)
  // ══════════════════════════════════════════════════════════

  static Future<void> saveBool({
    required String key,
    required bool value,
  }) async {
    try {
      final prefs = await _prefs;
      await prefs.setBool(key, value);
    } catch (_) {}
  }

  static Future<bool?> getBool({required String key}) async {
    try {
      final prefs = await _prefs;
      return prefs.getBool(key);
    } catch (_) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════
  // PLAIN — Int  (future use)
  // ══════════════════════════════════════════════════════════

  static Future<void> saveInt({
    required String key,
    required int value,
  }) async {
    try {
      final prefs = await _prefs;
      await prefs.setInt(key, value);
    } catch (_) {}
  }

  static Future<int?> getInt({required String key}) async {
    try {
      final prefs = await _prefs;
      return prefs.getInt(key);
    } catch (_) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════
  // SECURE — Biometric Login Credentials
  // ══════════════════════════════════════════════════════════

  static Future<void> saveLoginCredentials({
    required String phone,
    required String password,
  }) async {
    try {
      if (kIsWeb) return;
      await _secure.write(key: 'secure_login_phone', value: phone);
      await _secure.write(key: 'secure_login_password', value: password);
    } catch (_) {}
  }

  static Future<Map<String, String>?> getLoginCredentials() async {
    try {
      if (kIsWeb) return null;
      final phone = await _secure.read(key: 'secure_login_phone');
      final password = await _secure.read(key: 'secure_login_password');
      if (phone != null && password != null && phone.isNotEmpty && password.isNotEmpty) {
        return {'phone': phone, 'password': password};
      }
    } catch (_) {}
    return null;
  }

  static Future<void> clearLoginCredentials() async {
    try {
      if (kIsWeb) return;
      await _secure.delete(key: 'secure_login_phone');
      await _secure.delete(key: 'secure_login_password');
    } catch (_) {}
  }
}