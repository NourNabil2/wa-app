import 'package:dartz/dartz.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';
import '../../../user_data/user_repo.dart';  // <-- Import UserRepository
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/app_constans.dart';

class LogoutUseCase {
  final AuthRepository repository;


  LogoutUseCase(this.repository, );

  Future<Either<Failure, void>> call() async {
    try {
      // 1. Logout from API
      await repository.logout();

      // 2. Clear local user
      await UserRepository().clearUser();

      // 3. Purge session ID (prevent Cart leakage) and generate a new one
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.sessionKey, const Uuid().v4());

      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }
}