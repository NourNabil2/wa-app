import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/orders_repository.dart';

class CancelOrderUseCase {
  final OrdersRepository repository;

  CancelOrderUseCase(this.repository);

  Future<Either<Failure, void>> call(String orderId) async {
    return await repository.cancelOrder(orderId);
  }
}
