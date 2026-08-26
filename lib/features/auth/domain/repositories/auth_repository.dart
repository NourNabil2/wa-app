import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

/// Result of requesting an OTP. [debugOtp] is only populated when the admin
/// "Show OTP on screen" testing toggle (+ APP_DEBUG) is enabled on the server.
class OtpRequestResult {
  final String phone;
  final String? debugOtp;
  const OtpRequestResult({required this.phone, this.debugOtp});
}

abstract class AuthRepository {
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, OtpRequestResult>> requestOtp({required String phone});

  Future<Either<Failure, User>> loginWithPassword({
    required String phone,
    required String password,
  });

  Future<Either<Failure, String>> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<Either<Failure, User>> verifyOtp({
    required String identifier,
    required String otp,
  });

  Future<Either<Failure, void>> resendOtp({required String phone});

  Future<void> logout();
}