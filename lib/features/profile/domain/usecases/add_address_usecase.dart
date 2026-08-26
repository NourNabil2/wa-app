import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../features/checkout/domain/entities/saved_address_entity.dart';
import '../repositories/profile_repository.dart';

class AddAddressUseCase {
  final ProfileRepository _repo;
  AddAddressUseCase(this._repo);

  Future<Either<Failure, AddressEntity>> call({
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
    return _repo.addAddress(
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