import 'package:equatable/equatable.dart';
import 'package:fastway/features/home/domain/entities/product_entity.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<ProductEntity> products;
  final int total;
  final int page;
  final bool hasMore;

  const SearchLoaded({
    required this.products,
    required this.total,
    required this.page,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [products, total, page, hasMore];
}

class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}
