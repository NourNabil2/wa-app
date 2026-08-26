//
// import 'package:clinic_app/features/auth/domain/usecases/usecase.dart';
// import 'package:dartz/dartz.dart';
// import '../../../../core/errors/error_handler.dart';
// import '../../../../core/errors/failures.dart';
// import '../entities/user.dart';
// import '../repositories/auth_repository.dart';
//
// class GetCurrentUserUseCase implements UseCase<User?, NoParams> {
//   final AuthRepository repository;
//
//   GetCurrentUserUseCase(this.repository);
//
//   @override
//   Future<Either<Failure, User?>> call(NoParams params) async {
//     try {
//
//       final user = await repository.getCachedUser();
//
//       return Right(user);
//     } catch (e, stackTrace) {
//
//       return Left(ErrorHandler.handleException(e, stackTrace));
//     }
//   }
// }
