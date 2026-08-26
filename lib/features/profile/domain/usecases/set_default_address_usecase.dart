import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../features/checkout/domain/entities/saved_address_entity.dart';
import '../repositories/profile_repository.dart';

class SetDefaultAddressUseCase {
  final ProfileRepository _repo;
  SetDefaultAddressUseCase(this._repo);
  Future<Either<Failure, AddressEntity>> call(String id) => _repo.setDefaultAddress(id);
}