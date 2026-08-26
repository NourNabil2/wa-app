import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../entities/verify_otp_params.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository repository;

  VerifyOtpUseCase(this.repository);

  Future<Either<Failure, User>> call(VerifyOtpParams params) {
    return repository.verifyOtp(
      identifier: params.identifier,
      otp: params.otp,
    );
  }
}
