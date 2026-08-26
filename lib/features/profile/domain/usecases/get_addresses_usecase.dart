import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../features/checkout/domain/entities/saved_address_entity.dart';
import '../repositories/profile_repository.dart';

class GetAddressesUseCase {
  final ProfileRepository _repo;
  GetAddressesUseCase(this._repo);
  Future<Either<Failure, List<AddressEntity>>> call() => _repo.getAddresses();
}