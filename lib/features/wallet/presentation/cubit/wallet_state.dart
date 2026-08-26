import 'package:equatable/equatable.dart';
import '../../domain/entities/wallet_entity.dart';

abstract class WalletState extends Equatable {
  const WalletState();
  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletLoaded extends WalletState {
  final WalletSummaryEntity summary;
  final bool isLoadingMore;
  final bool hasReachedMax;
  final int currentPage;

  const WalletLoaded(
    this.summary, {
    this.isLoadingMore = false,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  WalletLoaded copyWith({
    WalletSummaryEntity? summary,
    bool? isLoadingMore,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return WalletLoaded(
      summary ?? this.summary,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [summary, isLoadingMore, hasReachedMax, currentPage];
}

class WalletError extends WalletState {
  final String message;
  const WalletError(this.message);
  @override
  List<Object?> get props => [message];
}
