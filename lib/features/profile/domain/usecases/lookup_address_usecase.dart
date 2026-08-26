import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

class LookupAddressUseCase {
  final ProfileRepository _repo;
  LookupAddressUseCase(this._repo);

  Future<Either<Failure, Map<String, dynamic>>> call(String shortAddress) {
    return _repo.lookupAddress(shortAddress);
  }
}
