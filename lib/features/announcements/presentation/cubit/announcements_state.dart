import 'package:equatable/equatable.dart';
import '../../domain/entities/announcement_entity.dart';

abstract class AnnouncementsState extends Equatable {
  const AnnouncementsState();

  @override
  List<Object> get props => [];
}

class AnnouncementsInitial extends AnnouncementsState {}

class AnnouncementsLoading extends AnnouncementsState {}

class AnnouncementsLoaded extends AnnouncementsState {
  final List<AnnouncementEntity> announcements;

  const AnnouncementsLoaded({required this.announcements});

  @override
  List<Object> get props => [announcements];
}

class AnnouncementsError extends AnnouncementsState {
  final String message;

  const AnnouncementsError({required this.message});

  @override
  List<Object> get props => [message];
}
