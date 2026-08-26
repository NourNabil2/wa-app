// lib/features/orders/domain/usecases/get_orders_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:fastway/features/auth/domain/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../entities/order_entity.dart';
import '../repositories/orders_repository.dart';

class GetOrdersUseCase implements UseCase<List<OrderEntity>, NoParams> {
  final OrdersRepository _repository;

  GetOrdersUseCase(this._repository);

  @override
  Future<Either<Failure, List<OrderEntity>>> call(NoParams params) {
    return _repository.getOrders();
  }
}
