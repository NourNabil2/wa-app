// // lib/features/auth/data/datasources/auth_local_data_source_impl.dart
// // ============================================
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../../user_data/user_model.dart';
// import 'auth_local_data_source.dart';
//
// class AuthLocalDataSourceImpl implements AuthLocalDataSource {
//   final SharedPreferences sharedPreferences;
//
//   static const String _userKey = 'cached_user';
//   static const String _tokenKey = 'auth_token';
//
//   AuthLocalDataSourceImpl({required this.sharedPreferences});
//
//   @override
//   Future<void> cacheUser(UserModel user) async {
//     final userJson = json.encode(user.toJson());
//     await sharedPreferences.setString(_userKey, userJson);
//     await sharedPreferences.setString(_tokenKey, user.token);
//   }
//
//   @override
//   Future<UserModel?> getCachedUser() async {
//     final userJson = sharedPreferences.getString(_userKey);
//     if (userJson != null) {
//       return UserModel.fromJson(json.decode(userJson));
//     }
//     return null;
//   }
//
//   @override
//   Future<void> clearCache() async {
//     await sharedPreferences.remove(_userKey);
//     await sharedPreferences.remove(_tokenKey);
//   }
//
//   @override
//   Future<String?> getToken() async {
//     return sharedPreferences.getString(_tokenKey);
//   }
// }
