// lib/features/profile/domain/repositories/profile_repository.dart

import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/errors/failures.dart';
import '../../../checkout/domain/entities/saved_address_entity.dart';
import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ProfileEntity>> getProfile();
  Future<Either<Failure, ProfileEntity>> updateProfile({String? name, String? phone});
  Future<Either<Failure, AppSettingsEntity>> getSettings();
  Future<Either<Failure, AppSettingsEntity>> updateSettings(AppSettingsEntity settings);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, void>> changePassword(String oldPassword, String newPassword);
  Future<Either<Failure, List<AddressEntity>>> getAddresses();
  Future<Either<Failure, AddressEntity?>> getNearestAddress({required double lat, required double lng});
  Future<Either<Failure, AddressEntity>> addAddress({
    required String label,
    required String fullAddress,
    required String phone,
    required String city,
    bool isDefault,
    String? building,
    String? street,
    String? district,
    String? shortAddress,
    String? postalCode,
    String? additionalNumber,
    double? lat,
    double? lng,
  });
  Future<Either<Failure, AddressEntity>> updateAddress({
    required String id,
    required String label,
    required String fullAddress,
    required String phone,
    required String city,
    bool isDefault,
    String? building,
    String? street,
    String? district,
    String? shortAddress,
    String? postalCode,
    String? additionalNumber,
    double? lat,
    double? lng,
  });
  Future<Either<Failure, void>> deleteAddress(String id);
  Future<Either<Failure, AddressEntity>> setDefaultAddress(String id);
  Future<Either<Failure, Map<String, dynamic>>> lookupAddress(String shortAddress);
  Future<Either<Failure, ProfileEntity>> uploadAvatar(XFile file);
  Future<Either<Failure, void>> deleteAccount();
}