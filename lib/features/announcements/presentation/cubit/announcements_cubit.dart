import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/announcements_repository.dart';
import 'announcements_state.dart';

class AnnouncementsCubit extends Cubit<AnnouncementsState> {
  final AnnouncementsRepository repository;

  AnnouncementsCubit({required this.repository}) : super(AnnouncementsInitial());

  Future<void> fetchAnnouncements() async {
    if (isClosed) return;
    emit(AnnouncementsLoading());
    final result = await repository.getAnnouncements();
    if (isClosed) return;
    result.fold(
      (failure) => emit(const AnnouncementsError(message: 'Failed to fetch announcements')),
      (announcements) {
        if (isClosed) return;
        final active = announcements.where((_) => true).toList();
        emit(AnnouncementsLoaded(announcements: active));
      },
    );
  }
}
