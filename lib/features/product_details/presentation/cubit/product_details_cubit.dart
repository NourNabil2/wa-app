// lib/features/product_details/presentation/cubit/product_details_cubit.dart

import 'package:fastway/core/services/location_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_product_details_usecase.dart';
import '../../domain/usecases/toggle_favorite_usecase.dart';
import '../../domain/usecases/join_waitlist_usecase.dart';
import '../../domain/usecases/notify_me_usecase.dart';
import '../../domain/usecases/fetch_questions_usecase.dart';
import '../../domain/usecases/submit_question_usecase.dart';
import 'product_details_state.dart';

class ProductDetailsCubit extends Cubit<ProductDetailsState> {
  final GetProductDetailsUseCase getProductDetailsUseCase;
  final ToggleFavoriteProductUseCase toggleFavoriteUseCase;
  final JoinWaitlistUseCase joinWaitlistUseCase;
  final NotifyMeUseCase notifyMeUseCase;
  final FetchQuestionsUseCase fetchQuestionsUseCase;
  final SubmitQuestionUseCase submitQuestionUseCase;

  ProductDetailsCubit({
    required this.getProductDetailsUseCase,
    required this.toggleFavoriteUseCase,
    required this.joinWaitlistUseCase,
    required this.notifyMeUseCase,
    required this.fetchQuestionsUseCase,
    required this.submitQuestionUseCase,
  }) : super(ProductDetailsInitial());

  Future<void> loadProductDetails(String productId) async {
    if (isClosed) return;
    emit(ProductDetailsLoading());
    final latLng = await LocationService.instance.getLatLng();
    if (isClosed) return;
    final result = await getProductDetailsUseCase(
      productId,
      lat: latLng['lat'],
      lng: latLng['lng'],
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(ProductDetailsError(failure.message)),
      (product) async {
        if (!isClosed) {
          emit(ProductDetailsLoaded(
            product: product,
            isFavorite: false,
            quantity: 1,
            questionsLoading: true,
          ));
        }
        await _loadQuestions(productId);
      },
    );
  }

  /// Internal helper — loads Q&A and patches the current loaded state.
  Future<void> _loadQuestions(String productId) async {
    final currentState = state;
    if (currentState is! ProductDetailsLoaded) return;
    if (isClosed) return;

    final result = await fetchQuestionsUseCase(productId);
    if (isClosed) return;
    result.fold(
      (_) => emit(currentState.copyWith(questionsLoading: false)),
      (questions) => emit(currentState.copyWith(
        questions: questions,
        questionsLoading: false,
      )),
    );
  }

  /// Called from the Q&A submit form.
  Future<void> submitQuestion(String productId, String question) async {
    final currentState = state;
    if (currentState is! ProductDetailsLoaded) return;
    if (isClosed) return;

    final result = await submitQuestionUseCase(productId, question);
    if (isClosed) return;
    result.fold(
      (failure) {
        emit(QuestionSubmitError(failure.message));
        emit(currentState);
      },
      (message) {
        emit(QuestionSubmitSuccess(message));
        emit(currentState);
      },
    );
  }

  void incrementQuantity() {
    final currentState = state;
    if (currentState is ProductDetailsLoaded) {
      // Stop at the ceiling the API gave us — min(stock, per-customer limit). Going
      // past it only earns a 422 from the cart, so the button is disabled there
      // instead (mirrors how the cart's own stepper already behaves).
      final max = currentState.product.maxPurchasable;
      if (currentState.quantity >= max) return;

      emit(currentState.copyWith(quantity: currentState.quantity + 1));
    }
  }

  void decrementQuantity() {
    final currentState = state;
    if (currentState is ProductDetailsLoaded && currentState.quantity > 1) {
      emit(currentState.copyWith(quantity: currentState.quantity - 1));
    }
  }

  Future<void> toggleFavorite() async {
    final currentState = state;
    if (currentState is! ProductDetailsLoaded) return;
    if (isClosed) return;
    emit(currentState.copyWith(isFavorite: !currentState.isFavorite));
    final result = await toggleFavoriteUseCase(currentState.product.id);
    if (isClosed) return;
    result.fold(
      (failure) => emit(currentState),
      (success) {},
    );
  }

  Future<void> joinWaitlist() async {
    final currentState = state;
    if (currentState is! ProductDetailsLoaded) return;
    if (isClosed) return;

    final result = await joinWaitlistUseCase(currentState.product.id);
    if (isClosed) return;
    result.fold(
      (failure) {
        emit(ProductDetailsWaitlistError(failure.message));
        emit(currentState);
      },
      (success) {
        emit(ProductDetailsWaitlistSuccess(success));
        emit(currentState);
      },
    );
  }

  Future<void> notifyMe() async {
    final currentState = state;
    if (currentState is! ProductDetailsLoaded) return;
    if (isClosed) return;

    final result = await notifyMeUseCase(currentState.product.id);
    if (isClosed) return;
    result.fold(
      (failure) {
        emit(ProductDetailsNotifyMeError(failure.message));
        emit(currentState);
      },
      (success) {
        emit(ProductDetailsNotifyMeSuccess(success));
        emit(currentState);
      },
    );
  }
}