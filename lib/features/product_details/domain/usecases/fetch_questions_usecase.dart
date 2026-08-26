// lib/features/product_details/domain/usecases/fetch_questions_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product_details_entity.dart';
import '../repositories/product_details_repository.dart';

class FetchQuestionsUseCase {
  final ProductDetailsRepository repository;
  FetchQuestionsUseCase(this.repository);

  Future<Either<Failure, List<ProductQuestion>>> call(String productId) =>
      repository.fetchQuestions(productId);
}
