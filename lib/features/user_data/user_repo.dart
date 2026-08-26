import 'dart:async';
import 'package:fastway/features/user_data/user_model.dart';
import '../../core/db/shared_pref_helper.dart';
import '../../core/utils/app_constans.dart';
import '../auth/domain/entities/user.dart';

/// Single source of truth for the current user.
/// Singleton — one instance across the whole app.
class UserRepository {
  // ── Singleton ────────────────────────────────────────────
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;
  UserRepository._internal();

  // ── Stream ───────────────────────────────────────────────
  final _controller = StreamController<User?>.broadcast();
  Stream<User?> get userStream => _controller.stream;

  // ── State ────────────────────────────────────────────────
  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // ── Lifecycle ────────────────────────────────────────────

  /// Call once in main() before runApp
  Future<void> loadUser() async {
    // getJson returns Map<String, dynamic>? directly — no type casting needed
    final json = await SharedPrefHelper.getJson(key: AppConstants.userKey);
    if (json != null) {
      _currentUser = UserModel.fromJson(json).toEntity();
      _controller.add(_currentUser);
    }
  }

  // ── Write ─────────────────────────────────────────────────

  /// Called after login / register
  Future<void> setUser(User user) async {
    _currentUser = user;
    _controller.add(user);
    await SharedPrefHelper.saveJson(
      key: AppConstants.userKey,
      value: UserModel.fromEntity(user).toJson(),
    );
  }

  /// Called on logout
  Future<void> clearUser() async {
    _currentUser = null;
    _controller.add(null);
    await SharedPrefHelper.delete(key: AppConstants.userKey);
  }

  /// Update specific fields (e.g. profile edit)
  Future<void> updateUser({String? name, String? phone, String? avatar}) async {
    if (_currentUser == null) return;
    await setUser(_currentUser!.copyWith(name: name, phone: phone, avatar: avatar));
  }

  void dispose() => _controller.close();
}