import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../checkout/domain/entities/saved_address_entity.dart';
import '../repositories/profile_repository.dart';

class GetNearestAddressUseCase {
  final ProfileRepository _repository;

  GetNearestAddressUseCase(this._repository);

  Future<Either<Failure, AddressEntity?>> call({
    required double lat,
    required double lng,
  }) {
    return _repository.getNearestAddress(lat: lat, lng: lng);
  }
}
