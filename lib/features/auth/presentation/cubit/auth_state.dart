// lib/features/auth/presentation/cubit/auth_state.dart
// ============================================
import 'package:equatable/equatable.dart';

import '../../domain/entities/user.dart';


abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class LoginSuccess extends AuthState {}

class SignupSuccess extends AuthState {
  final String email;

  const SignupSuccess({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class OtpLoading extends AuthState {
  const OtpLoading();
}

class OtpFailure extends AuthState {
  final String message;

  const OtpFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class AccountNotVerified extends AuthState {
  final String email;

  const AccountNotVerified({required this.email});

  @override
  List<Object?> get props => [email];
}

/// BUG-67 FIX: emitted when a new OTP is successfully sent to the user's phone
class OtpResent extends AuthState {
  const OtpResent();
}

class OtpSent extends AuthState {
  final String phone;
  final String? debugOtp; // only set when server testing toggle is on
  const OtpSent({required this.phone, this.debugOtp});
  @override List<Object?> get props => [phone, debugOtp];
}
