// lib/features/product_details/domain/usecases/submit_question_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/product_details_repository.dart';

class SubmitQuestionUseCase {
  final ProductDetailsRepository repository;
  SubmitQuestionUseCase(this.repository);

  Future<Either<Failure, String>> call(String productId, String question) =>
      repository.submitQuestion(productId, question);
}
