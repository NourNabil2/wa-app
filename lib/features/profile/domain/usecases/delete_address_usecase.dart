import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

class DeleteAddressUseCase {
  final ProfileRepository _repo;
  DeleteAddressUseCase(this._repo);
  Future<Either<Failure, void>> call(String id) => _repo.deleteAddress(id);
}