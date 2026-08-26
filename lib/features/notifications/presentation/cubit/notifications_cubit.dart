import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/notifications_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository _repository;
  
  int _currentPage = 1;
  bool _isFetchingMore = false;
  int _unreadCount = 0;

  NotificationsCubit({required NotificationsRepository repository})
      : _repository = repository,
        super(NotificationsInitial());

  int get unreadCount => _unreadCount;

  Future<void> loadNotifications({bool refresh = false}) async {
    if (isClosed) return;
    if (refresh) {
      _currentPage = 1;
      emit(NotificationsLoading());
    }

    final result = await _repository.getNotifications(page: _currentPage);
    if (isClosed) return;
    
    result.fold(
      (failure) => emit(NotificationsError(failure.message ?? 'Unknown error')),
      (notifications) {
        if (isClosed) return;
        _updateUnreadCount();
        if (refresh || state is! NotificationsLoaded) {
          emit(NotificationsLoaded(
            notifications: notifications,
            hasMore: notifications.isNotEmpty,
            unreadCount: _unreadCount,
          ));
        } else {
          final currentState = state as NotificationsLoaded;
          emit(NotificationsLoaded(
            notifications: [...currentState.notifications, ...notifications],
            hasMore: notifications.isNotEmpty,
            unreadCount: _unreadCount,
          ));
        }
      },
    );
  }

  Future<void> loadMore() async {
    if (_isFetchingMore || state is! NotificationsLoaded) return;
    
    final currentState = state as NotificationsLoaded;
    if (!currentState.hasMore) return;

    _isFetchingMore = true;
    _currentPage++;
    
    await loadNotifications(refresh: false);
    _isFetchingMore = false;
  }

  Future<void> markAsRead(List<String> ids) async {
    if (isClosed) return;
    final result = await _repository.markAsRead(ids);
    if (isClosed) return;
    
    if (result.isRight() && state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;
      
      final updatedList = currentState.notifications.map((n) {
        if (ids.isEmpty || ids.contains(n.id)) {
          return n.copyWith(readAt: DateTime.now());
        }
        return n;
      }).toList();

      if (ids.isEmpty) {
        _unreadCount = 0;
      } else {
        _unreadCount = (_unreadCount - ids.length).clamp(0, 99);
      }

      emit(NotificationsLoaded(
        notifications: updatedList,
        hasMore: currentState.hasMore,
        unreadCount: _unreadCount,
      ));
    }
  }

  Future<void> fetchUnreadCount() async {
    if (isClosed) return;
    final result = await _repository.getUnreadCount();
    if (isClosed) return;
    result.fold(
      (l) => null,
      (count) {
        if (isClosed) return;
        _unreadCount = count;
        if (state is NotificationsLoaded) {
          final currentState = state as NotificationsLoaded;
          emit(NotificationsLoaded(
            notifications: currentState.notifications,
            hasMore: currentState.hasMore,
            unreadCount: _unreadCount,
          ));
        } else {
          // Called at app boot, before the notifications list has ever been
          // loaded (state is still NotificationsInitial) — emit a Loaded
          // state with an empty list just to carry the count, so the header
          // badge (which only reads unreadCount off a Loaded state) shows
          // the real number immediately instead of staying blank until the
          // user opens the notifications screen.
          emit(NotificationsLoaded(
            notifications: const [],
            hasMore: false,
            unreadCount: _unreadCount,
          ));
        }
      },
    );
  }

  Future<void> _updateUnreadCount() async {
    await fetchUnreadCount();
  }
}
