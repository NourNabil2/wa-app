import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, User>> call(LoginParams params) async {
    final result = await repository.login(
      email: params.email,
      password: params.password,
    );

    return result.fold(
          (failure) {
        if (failure.message == 'errors.server.accountNotVerified'.tr()) {
          return Left(AccountNotVerifiedFailure(params.email));
        }
        return Left(failure);
      },
          (user) => Right(user),
    );
  }
}

class LoginParams {
  final String email;
  final String password;

  LoginParams({required this.email, required this.password});
}

