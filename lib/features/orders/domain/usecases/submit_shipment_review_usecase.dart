import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/orders_repository.dart';

class SubmitShipmentReviewUseCase {
  final OrdersRepository _repository;

  SubmitShipmentReviewUseCase(this._repository);

  Future<Either<Failure, void>> call(String orderId, int rating, String? comment) {
    return _repository.submitShipmentReview(orderId, rating, comment);
  }
}
