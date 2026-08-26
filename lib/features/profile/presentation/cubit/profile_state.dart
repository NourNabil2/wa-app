// lib/features/profile/presentation/cubit/profile_state.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/profile_entity.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final ProfileEntity profile;
  final AppSettingsEntity settings;

  const ProfileLoaded({required this.profile, required this.settings});

  ProfileLoaded copyWith(
      {ProfileEntity? profile, AppSettingsEntity? settings}) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => [profile, settings];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}

class ProfileLoggingOut extends ProfileState {}

class ProfileLoggedOut extends ProfileState {}
