// lib/features/orders/data/repositories/orders_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_remote_datasource.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersRemoteDataSource _remote;

  OrdersRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders() async {
    try {
      final orders = await _remote.getOrders();
      return Right(orders.cast<OrderEntity>());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderEntity?>> getOrderById(String orderId) async {
    try {
      final order = await _remote.getOrderDetails(orderId);
      return Right(order);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> trackOrder(String orderId) async {
    try {
      final order = await _remote.trackOrder(orderId);
      return Right(order);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelOrder(String orderId) async {
    try {
      await _remote.cancelOrder(orderId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> requestCancellation(String orderId, String reason) async {
    try {
      await _remote.requestCancellation(orderId, reason);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> confirmDelivery(String orderId) async {
    try {
      await _remote.confirmDelivery(orderId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitStoreReview(String orderId, int rating, String? comment) async {
    try {
      await _remote.submitStoreReview(orderId, rating, comment);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitShipmentReview(String orderId, int rating, String? comment) async {
    try {
      await _remote.submitShipmentReview(orderId, rating, comment);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> reorder(String orderId) async {
    try {
      final msg = await _remote.reorder(orderId);
      return Right(msg);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitReturn({
    required String orderNumber,
    required String orderId,
    required List<Map<String, dynamic>> items,
    required String reason,
    String? notes,
    List<String> imagePaths = const [],
  }) async {
    try {
      await _remote.submitReturn(
        orderNumber: orderNumber,
        orderId: orderId,
        items: items,
        reason: reason,
        notes: notes,
        imagePaths: imagePaths,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
