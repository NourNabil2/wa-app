import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/orders_repository.dart';

class ReorderUseCase {
  final OrdersRepository _repository;

  ReorderUseCase(this._repository);

  Future<Either<Failure, String>> call(String orderId) {
    return _repository.reorder(orderId);
  }
}
