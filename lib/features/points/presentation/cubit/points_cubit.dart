// lib/features/points/presentation/cubit/points_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_points_summary_usecase.dart';
import '../../domain/usecases/get_points_history_usecase.dart';
import 'points_state.dart';

class PointsCubit extends Cubit<PointsState> {
  final GetPointsSummaryUseCase _getPointsSummaryUseCase;
  final GetPointsHistoryUseCase _getPointsHistoryUseCase;

  PointsCubit({
    required GetPointsSummaryUseCase getPointsSummaryUseCase,
    required GetPointsHistoryUseCase getPointsHistoryUseCase,
  })  : _getPointsSummaryUseCase = getPointsSummaryUseCase,
        _getPointsHistoryUseCase = getPointsHistoryUseCase,
        super(PointsInitial());

  Future<void> loadPoints() async {
    if (isClosed) return;
    emit(PointsLoading());
    final result = await _getPointsSummaryUseCase();
    if (isClosed) return;
    result.fold(
          (failure) => emit(PointsError(failure.message)),
          (summary) => emit(PointsLoaded(summary)),
    );
  }

  Future<void> loadMoreHistory() async {
    if (isClosed) return;
    if (state is! PointsLoaded) return;
    
    final currentState = state as PointsLoaded;
    if (currentState.isLoadingMore || currentState.hasReachedMax) return;

    emit(currentState.copyWith(isLoadingMore: true));
    
    final nextPage = currentState.currentPage + 1;
    final result = await _getPointsHistoryUseCase(nextPage);
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
            hasReachedMax: newHistory.length < 15,
          ));
        }
      },
    );
  }
}