// lib/features/profile/data/repositories/profile_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result_handler.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../checkout/domain/entities/saved_address_entity.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_datasource.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/profile_model.dart';
import 'package:image_picker/image_picker.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remote;
  final ProfileLocalDataSource  _local;   // settings + logout stay local

  ProfileRepositoryImpl(this._remote, this._local);

  @override
  Future<Either<Failure, ProfileEntity>> getProfile() async {
    try {
      return Right(await _remote.getProfile());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProfileEntity>> updateProfile({String? name, String? phone}) async {
    try {
      final updatedProfile = await _remote.updateProfile(name: name, phone: phone);
      return Right(updatedProfile);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppSettingsEntity>> getSettings() async {
    try {
      return Right(await _local.getSettings());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppSettingsEntity>> updateSettings(
      AppSettingsEntity settings) async {
    try {
      final model = AppSettingsModel(
        language: settings.language,
        themeMode: settings.themeMode,
        notificationsEnabled: settings.notificationsEnabled,
      );
      return Right(await _local.updateSettings(model));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _local.logout();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword(String oldPassword, String newPassword) async {
    try {
      await _remote.changePassword(oldPassword, newPassword);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<AddressEntity>>> getAddresses() {
    return ResultHandler.handle(() => _remote.getAddresses());
  }

  @override
  Future<Either<Failure, AddressEntity?>> getNearestAddress({required double lat, required double lng}) {
    return ResultHandler.handle(() => _remote.getNearestAddress(lat, lng));
  }

  @override
  Future<Either<Failure, AddressEntity>> addAddress({
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
    return ResultHandler.handle(() => _remote.addAddress({
      'label': label,
      'full_address': fullAddress,
      'phone': phone,
      'city': city,
      'is_default': isDefault,
      if (building != null) 'building': building,
      if (street != null) 'street': street,
      if (district != null) 'district': district,
      if (shortAddress != null) 'short_address': shortAddress,
      if (postalCode != null) 'postal_code': postalCode,
      if (additionalNumber != null) 'additional_number': additionalNumber,
      if (lat != null) 'latitude': lat,
      if (lng != null) 'longitude': lng,
    }));
  }

  @override
  Future<Either<Failure, AddressEntity>> updateAddress({
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
    return ResultHandler.handle(() => _remote.updateAddress(id, {
      'label': label,
      'full_address': fullAddress,
      'phone': phone,
      'city': city,
      'is_default': isDefault,
      if (building != null) 'building': building,
      if (street != null) 'street': street,
      if (district != null) 'district': district,
      if (shortAddress != null) 'short_address': shortAddress,
      if (postalCode != null) 'postal_code': postalCode,
      if (additionalNumber != null) 'additional_number': additionalNumber,
      if (lat != null) 'latitude': lat,
      if (lng != null) 'longitude': lng,
    }));
  }

  @override
  Future<Either<Failure, void>> deleteAddress(String id) {
    return ResultHandler.handle(() => _remote.deleteAddress(id));
  }

  @override
  Future<Either<Failure, AddressEntity>> setDefaultAddress(String id) {
    return ResultHandler.handle(() => _remote.setDefaultAddress(id));
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> lookupAddress(String shortAddress) {
    return ResultHandler.handle(() => _remote.lookupAddress(shortAddress));
  }

  @override
  Future<Either<Failure, ProfileEntity>> uploadAvatar(XFile file) {
    return ResultHandler.handle(() => _remote.uploadAvatar(file));
  }

  @override
  Future<Either<Failure, void>> deleteAccount() {
    return ResultHandler.handle(() => _remote.deleteAccount());
  }
}