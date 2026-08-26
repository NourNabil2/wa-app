import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../features/checkout/domain/entities/saved_address_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateAddressUseCase {
  final ProfileRepository _repo;
  UpdateAddressUseCase(this._repo);

  Future<Either<Failure, AddressEntity>> call({
    required String id,
    required String label,
    required String fullAddress,
    required String phone,
    required String city,
    bool isDefault = false,
    String? building,
    String? street,
    String? district,
    String? shortAddress,
    String? postalCode,
    String? additionalNumber,
    double? lat,
    double? lng,
  }) {
    return _repo.updateAddress(
      id: id,
      label: label,
      fullAddress: fullAddress,
      phone: phone,
      city: city,
      isDefault: isDefault,
      building: building,
      street: street,
      district: district,
      shortAddress: shortAddress,
      postalCode: postalCode,
      additionalNumber: additionalNumber,
      lat: lat,
      lng: lng,
    );
  }
}