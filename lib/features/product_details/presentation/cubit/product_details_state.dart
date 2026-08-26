
// lib/features/product_details/presentation/cubit/product_details_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/product_details_entity.dart';

abstract class ProductDetailsState extends Equatable {
  const ProductDetailsState();

  @override
  List<Object?> get props => [];
}

class ProductDetailsInitial extends ProductDetailsState {}

class ProductDetailsLoading extends ProductDetailsState {}

class ProductDetailsLoaded extends ProductDetailsState {
  final ProductDetailsEntity product;
  final bool isFavorite;
  final int quantity;
  final List<ProductQuestion> questions;
  final bool questionsLoading;

  const ProductDetailsLoaded({
    required this.product,
    required this.isFavorite,
    required this.quantity,
    this.questions = const [],
    this.questionsLoading = false,
  });

  @override
  List<Object?> get props => [product, isFavorite, quantity, questions, questionsLoading];

  ProductDetailsLoaded copyWith({
    ProductDetailsEntity? product,
    bool? isFavorite,
    int? quantity,
    List<ProductQuestion>? questions,
    bool? questionsLoading,
  }) {
    return ProductDetailsLoaded(
      product: product ?? this.product,
      isFavorite: isFavorite ?? this.isFavorite,
      quantity: quantity ?? this.quantity,
      questions: questions ?? this.questions,
      questionsLoading: questionsLoading ?? this.questionsLoading,
    );
  }
}

class ProductDetailsError extends ProductDetailsState {
  final String message;

  const ProductDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProductDetailsNotifyMeSuccess extends ProductDetailsState {
  final String message;
  const ProductDetailsNotifyMeSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class ProductDetailsNotifyMeError extends ProductDetailsState {
  final String message;
  const ProductDetailsNotifyMeError(this.message);
  @override
  List<Object?> get props => [message];
}

class ProductDetailsWaitlistSuccess extends ProductDetailsState {
  final String message;
  const ProductDetailsWaitlistSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class ProductDetailsWaitlistError extends ProductDetailsState {
  final String message;
  const ProductDetailsWaitlistError(this.message);
  @override
  List<Object?> get props => [message];
}

// Q&A specific states for one-shot feedback (snackbar)
class QuestionSubmitSuccess extends ProductDetailsState {
  final String message;
  const QuestionSubmitSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class QuestionSubmitError extends ProductDetailsState {
  final String message;
  const QuestionSubmitError(this.message);
  @override
  List<Object?> get props => [message];
}