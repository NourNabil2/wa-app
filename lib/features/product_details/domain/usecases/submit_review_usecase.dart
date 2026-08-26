// lib/features/product_details/domain/usecases/submit_review_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/product_details_repository.dart';

class SubmitReviewUseCase {
  final ProductDetailsRepository repository;
  SubmitReviewUseCase(this.repository);

  Future<Either<Failure, String>> call(String productId, int rating, String? comment) =>
      repository.submitReview(productId, rating, comment);
}
