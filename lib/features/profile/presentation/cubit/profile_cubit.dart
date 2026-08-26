import 'package:image_picker/image_picker.dart';
import 'package:fastway/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:fastway/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:fastway/features/user_data/user_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/profile_entity.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final GetProfileUseCase _getProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final GetSettingsUseCase _getSettingsUseCase;
  final UpdateSettingsUseCase _updateSettingsUseCase;
  final LogoutProfileUseCase _logoutUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;
  final UploadAvatarUseCase _uploadAvatarUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;

  ProfileCubit({
    required GetProfileUseCase getProfileUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required GetSettingsUseCase getSettingsUseCase,
    required UpdateSettingsUseCase updateSettingsUseCase,
    required LogoutProfileUseCase logoutUseCase,
    required ChangePasswordUseCase changePasswordUseCase,
    required UploadAvatarUseCase uploadAvatarUseCase,
    required DeleteAccountUseCase deleteAccountUseCase,
  })  : _getProfileUseCase = getProfileUseCase,
        _updateProfileUseCase = updateProfileUseCase,
        _getSettingsUseCase = getSettingsUseCase,

        _updateSettingsUseCase = updateSettingsUseCase,
        _logoutUseCase = logoutUseCase,
        _changePasswordUseCase = changePasswordUseCase,
        _uploadAvatarUseCase = uploadAvatarUseCase,
        _deleteAccountUseCase = deleteAccountUseCase,
        super(ProfileInitial());

  Future<void> loadProfile() async {
    if (isClosed) return;
    emit(ProfileLoading());

    final profileResult = await _getProfileUseCase();
    final settingsResult = await _getSettingsUseCase();
    if (isClosed) return;

    profileResult.fold(
      (failure) => emit(ProfileError(failure.message)),
      (profile) => settingsResult.fold(
        (failure) => emit(ProfileError(failure.message)),
        (settings) => emit(ProfileLoaded(profile: profile, settings: settings)),
      ),
    );
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    final current = state;
    if (current is! ProfileLoaded) return;
    
    emit(ProfileLoading());
    final result = await _updateProfileUseCase(name: name, phone: phone);
    
    result.fold(
      (failure) {
        emit(ProfileError(failure.message));
        emit(current); // restore previous state
      },
      (updatedProfile) async {
        await UserRepository().updateUser(name: updatedProfile.name, phone: updatedProfile.phone);
        emit(current.copyWith(profile: updatedProfile));
      },
    );
  }

  Future<void> updateLanguage(String langCode) async {
    final current = state;
    if (current is! ProfileLoaded) return;

    final updated = AppSettingsEntity(
      language: langCode,
      themeMode: current.settings.themeMode,
      notificationsEnabled: current.settings.notificationsEnabled,
    );

    final result = await _updateSettingsUseCase(updated);
    if (isClosed) return;
    result.fold(
      (_) {},
      (settings) => emit(current.copyWith(settings: settings)),
    );
  }

  Future<void> updateTheme(String themeMode) async {
    final current = state;
    if (current is! ProfileLoaded) return;

    final updated = AppSettingsEntity(
      language: current.settings.language,
      themeMode: themeMode,
      notificationsEnabled: current.settings.notificationsEnabled,
    );

    final result = await _updateSettingsUseCase(updated);
    if (isClosed) return;
    result.fold(
      (_) {}, // silently fail — UI already optimistic
      (settings) => emit(current.copyWith(settings: settings)),
    );
  }

  Future<void> toggleNotifications(bool enabled) async {
    final current = state;
    if (current is! ProfileLoaded) return;

    final updated = AppSettingsEntity(
      language: current.settings.language,
      themeMode: current.settings.themeMode,
      notificationsEnabled: enabled,
    );

    // Optimistic update
    emit(current.copyWith(settings: updated));
    await _updateSettingsUseCase(updated);
  }

  Future<void> logout() async {
    if (isClosed) return;
    emit(ProfileLoggingOut());
    final result = await _logoutUseCase();
    if (isClosed) return;
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (_) async {
        // BUG-22 FIX: Clear user data (token, cart, checkout) from SharedPrefs
        await UserRepository().clearUser();
        if (isClosed) return;
        emit(ProfileLoggedOut());
      },
    );
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    if (isClosed) return;
    final current = state;
    emit(ProfileLoading());
    final result = await _changePasswordUseCase(oldPassword, newPassword);
    if (isClosed) return;
    result.fold(
      (failure) {
        emit(ProfileError(failure.message));
        if (current is ProfileLoaded) {
          emit(current);
        }
      },
      (_) {
        if (current is ProfileLoaded) {
          emit(current);
        } else {
          loadProfile();
        }
      },
    );
  }

  Future<void> uploadAvatar(XFile file) async {
    if (isClosed) return;
    final current = state;
    if (current is! ProfileLoaded) return;
    emit(ProfileLoading());
    final result = await _uploadAvatarUseCase(file);
    if (isClosed) return;
    result.fold(
      (failure) {
        emit(ProfileError(failure.message));
        emit(current);
      },
      (profile) {
        emit(current.copyWith(profile: profile));
      },
    );
  }

  Future<void> deleteAccount() async {
    if (isClosed) return;
    emit(ProfileLoading());
    final result = await _deleteAccountUseCase();
    if (isClosed) return;
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (_) async {
        await UserRepository().clearUser();
        if (isClosed) return;
        emit(ProfileLoggedOut());
      },
    );
  }
}
