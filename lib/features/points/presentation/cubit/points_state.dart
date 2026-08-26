// lib/features/points/presentation/cubit/points_state.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/points_entity.dart';

abstract class PointsState extends Equatable {
  const PointsState();
  @override
  List<Object?> get props => [];
}

class PointsInitial extends PointsState {}

class PointsLoading extends PointsState {}

class PointsLoaded extends PointsState {
  final PointsSummaryEntity summary;
  final bool isLoadingMore;
  final bool hasReachedMax;
  final int currentPage;

  const PointsLoaded(
    this.summary, {
    this.isLoadingMore = false,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  PointsLoaded copyWith({
    PointsSummaryEntity? summary,
    bool? isLoadingMore,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return PointsLoaded(
      summary ?? this.summary,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [summary, isLoadingMore, hasReachedMax, currentPage];
}

class PointsError extends PointsState {
  final String message;
  const PointsError(this.message);
  @override
  List<Object?> get props => [message];
}
