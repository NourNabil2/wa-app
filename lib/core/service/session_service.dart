// lib/core/service/session_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../utils/app_constans.dart';

class SessionService {
  static const _key = AppConstants.sessionKey; // 'session_id'

  // Called once at app boot (already in your main.dart as _initGuestSession)
  static Future<String> initAndGet() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_key);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_key, id);
    }
    return id;
  }

  static Future<String?> get() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  /// Call after successful login — keeps the same UUID so the server can
  /// merge the guest cart into the authenticated cart.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}