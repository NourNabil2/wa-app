// lib/features/orders/domain/repositories/orders_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/order_entity.dart';

abstract class OrdersRepository {
  Future<Either<Failure, List<OrderEntity>>> getOrders();
  Future<Either<Failure, OrderEntity?>> getOrderById(String orderId);
  Future<Either<Failure, OrderEntity>> trackOrder(String orderId);
  Future<Either<Failure, void>> cancelOrder(String orderId);
  Future<Either<Failure, void>> requestCancellation(String orderId, String reason);
  Future<Either<Failure, void>> confirmDelivery(String orderId);
  Future<Either<Failure, void>> submitStoreReview(String orderId, int rating, String? comment);
  Future<Either<Failure, void>> submitShipmentReview(String orderId, int rating, String? comment);
  Future<Either<Failure, String>> reorder(String orderId);
  Future<Either<Failure, void>> submitReturn({
    required String orderNumber,
    required String orderId,
    required List<Map<String, dynamic>> items,
    required String reason,
    String? notes,
    List<String> imagePaths = const [],
  });
}
