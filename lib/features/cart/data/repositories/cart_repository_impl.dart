import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/cart_entity.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_remote_datasource.dart';

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource _remote;

  CartRepositoryImpl(this._remote);

  Future<Either<Failure, CartEntity>> _wrap(
      Future<CartEntity> Function() call,
      ) async {
    try {
      return Right(await call());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartEntity>> getCart({double? lat, double? lng, String? addressId}) =>
      _wrap(() => _remote.getCart(lat: lat, lng: lng, addressId: addressId));

  @override
  Future<Either<Failure, CartEntity>> addToCart({
    required String productId,
    required int quantity,
    double? lat,
    double? lng,
    String? addressId,
  }) =>
      _wrap(() => _remote.addItem(productId, quantity, lat: lat, lng: lng, addressId: addressId));

  @override
  Future<Either<Failure, CartEntity>> updateQuantity({
    required String itemId,
    required int quantity,
    double? lat,
    double? lng,
    String? addressId,
  }) =>
      _wrap(() => _remote.updateItem(itemId, quantity, lat: lat, lng: lng, addressId: addressId));

  @override
  Future<Either<Failure, CartEntity>> removeItem(String itemId, {double? lat, double? lng, String? addressId}) =>
      _wrap(() => _remote.removeItem(itemId, lat: lat, lng: lng, addressId: addressId));

  @override
  Future<Either<Failure, CartEntity>> clearCart() =>
      _wrap(() => _remote.clearCart());

  @override
  Future<Either<Failure, CartEntity>> applyCoupon(String couponCode, {double? lat, double? lng, String? addressId}) =>
      _wrap(() => _remote.applyCoupon(couponCode, lat: lat, lng: lng, addressId: addressId));

  @override
  Future<Either<Failure, CartEntity>> removeCoupon({double? lat, double? lng, String? addressId}) =>
      _wrap(() => _remote.removeCoupon(lat: lat, lng: lng, addressId: addressId));

  @override
  Future<Either<Failure, CartEntity>> toggleExpressItem(String itemId, {double? lat, double? lng, String? addressId}) =>
      _wrap(() => _remote.toggleExpressItem(itemId, lat: lat, lng: lng, addressId: addressId));

  @override
  Future<Either<Failure, CartEntity>> mergeGuestCart(String sessionId, {double? lat, double? lng}) =>
      _wrap(() => _remote.mergeGuestCart(sessionId, lat: lat, lng: lng));
}