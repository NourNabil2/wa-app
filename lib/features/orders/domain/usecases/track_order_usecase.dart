// lib/features/orders/domain/usecases/track_order_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:fastway/features/auth/domain/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../entities/order_entity.dart';
import '../repositories/orders_repository.dart';

class TrackOrderUseCase implements UseCase<OrderEntity, String> {
  final OrdersRepository _repository;

  TrackOrderUseCase(this._repository);

  @override
  Future<Either<Failure, OrderEntity>> call(String orderId) {
    return _repository.trackOrder(orderId);
  }
}
