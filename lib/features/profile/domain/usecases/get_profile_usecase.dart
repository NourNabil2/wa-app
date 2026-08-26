// lib/features/profile/domain/usecases/get_profile_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/errors/failures.dart';
import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetProfileUseCase {
  final ProfileRepository _repository;
  GetProfileUseCase(this._repository);
  Future<Either<Failure, ProfileEntity>> call() => _repository.getProfile();
}

// lib/features/profile/domain/usecases/get_settings_usecase.dart

class GetSettingsUseCase {
  final ProfileRepository _repository;
  GetSettingsUseCase(this._repository);
  Future<Either<Failure, AppSettingsEntity>> call() => _repository.getSettings();
}

// lib/features/profile/domain/usecases/update_settings_usecase.dart

class UpdateSettingsUseCase {
  final ProfileRepository _repository;
  UpdateSettingsUseCase(this._repository);
  Future<Either<Failure, AppSettingsEntity>> call(AppSettingsEntity settings) =>
      _repository.updateSettings(settings);
}

// lib/features/profile/domain/usecases/logout_profile_usecase.dart

class LogoutProfileUseCase {
  final ProfileRepository _repository;
  LogoutProfileUseCase(this._repository);
  Future<Either<Failure, void>> call() => _repository.logout();
}

class ChangePasswordUseCase {
  final ProfileRepository _repository;
  ChangePasswordUseCase(this._repository);
  Future<Either<Failure, void>> call(String oldPassword, String newPassword) =>
      _repository.changePassword(oldPassword, newPassword);
}

class UploadAvatarUseCase {
  final ProfileRepository _repository;
  UploadAvatarUseCase(this._repository);
  Future<Either<Failure, ProfileEntity>> call(XFile file) => _repository.uploadAvatar(file);
}

class DeleteAccountUseCase {
  final ProfileRepository _repository;
  DeleteAccountUseCase(this._repository);
  Future<Either<Failure, void>> call() => _repository.deleteAccount();
}