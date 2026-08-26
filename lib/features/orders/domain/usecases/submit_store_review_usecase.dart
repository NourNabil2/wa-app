import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/orders_repository.dart';

class SubmitStoreReviewUseCase {
  final OrdersRepository _repository;

  SubmitStoreReviewUseCase(this._repository);

  Future<Either<Failure, void>> call(String orderId, int rating, String? comment) {
    return _repository.submitStoreReview(orderId, rating, comment);
  }
}
