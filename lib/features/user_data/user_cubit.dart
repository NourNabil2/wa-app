import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fastway/features/user_data/user_repo.dart';
import 'package:meta/meta.dart';

import '../auth/domain/entities/user.dart';


part 'user_state.dart';

class UserCubit extends Cubit<User?> {
  final UserRepository _userRepository;
  late final StreamSubscription<User?> _subscription;

  UserCubit(this._userRepository) : super(_userRepository.currentUser) {
    _subscription = _userRepository.userStream.listen(emit);
  }

  // ── Convenience getters ───────────────────────────────────
  bool get isLoggedIn => state != null;
  String get displayName => state?.name ?? '';
  String get token => state?.token ?? '';

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}