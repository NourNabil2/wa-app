
import '../auth/domain/entities/user.dart';


class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.avatar,
    required super.token,
    super.emailVerifiedAt,
  });

  // ── From JSON (SharedPreferences / API) ──────────────────
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '', // handles both String "17" and num 17
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      token: json['token'] as String? ?? '',
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'] as String)
          : null,
    );
  }

  // ── From Entity ───────────────────────────────────────────
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      avatar: user.avatar,
      token: user.token,
      emailVerifiedAt: user.emailVerifiedAt,
    );
  }

  // ── To JSON (for SharedPreferences) ─────────────────────
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'token': token,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
    };
  }

  // ── To Entity ─────────────────────────────────────────────
  User toEntity() => User(
    id: id,
    name: name,
    email: email,
    phone: phone,
    avatar: avatar,
    token: token,
    emailVerifiedAt: emailVerifiedAt,
  );
}