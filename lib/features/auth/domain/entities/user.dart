import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id; // BUG-15 FIX: was int, now String for consistency
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String token;
  final DateTime? emailVerifiedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    required this.token,
    this.emailVerifiedAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    avatar,
    token,
    emailVerifiedAt,
  ];

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    String? token,
    DateTime? emailVerifiedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      token: token ?? this.token,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
    );
  }
}