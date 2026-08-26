import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_wallet_summary_usecase.dart';
import '../../domain/usecases/get_wallet_history_usecase.dart';
import 'wallet_state.dart';

class WalletCubit extends Cubit<WalletState> {
  final GetWalletSummaryUseCase _getWalletSummaryUseCase;
  final GetWalletHistoryUseCase _getWalletHistoryUseCase;

  WalletCubit({
    required GetWalletSummaryUseCase getWalletSummaryUseCase,
    required GetWalletHistoryUseCase getWalletHistoryUseCase,
  })  : _getWalletSummaryUseCase = getWalletSummaryUseCase,
        _getWalletHistoryUseCase = getWalletHistoryUseCase,
        super(WalletInitial());

  Future<void> loadWallet() async {
    if (isClosed) return;
    emit(WalletLoading());
    final result = await _getWalletSummaryUseCase();
    if (isClosed) return;
    result.fold(
      (failure) => emit(WalletError(failure.message)),
      (summary) => emit(WalletLoaded(summary)),
    );
  }

  Future<void> loadMoreHistory() async {
    if (isClosed) return;
    if (state is! WalletLoaded) return;

    final currentState = state as WalletLoaded;
    if (currentState.isLoadingMore || currentState.hasReachedMax) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final nextPage = currentState.currentPage + 1;
    final result = await _getWalletHistoryUseCase(nextPage);
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(currentState.copyWith(isLoadingMore: false));
      },
      (newHistory) {
        if (newHistory.isEmpty) {
          emit(currentState.copyWith(isLoadingMore: false, hasReachedMax: true));
        } else {
          final updatedSummary = currentState.summary.copyWith(
            history: List.of(currentState.summary.history)..addAll(newHistory),
          );
          emit(currentState.copyWith(
            summary: updatedSummary,
            isLoadingMore: false,
            currentPage: nextPage,
            hasReachedMax: newHistory.length < 20,
          ));
        }
      },
    );
  }
}
