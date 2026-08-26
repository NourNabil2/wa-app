import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/cart_entity.dart';

abstract class CartRepository {
  Future<Either<Failure, CartEntity>> getCart({double? lat, double? lng, String? addressId});

  Future<Either<Failure, CartEntity>> addToCart({
    required String productId,
    required int quantity,
    double? lat,
    double? lng,
    String? addressId,
  });

  Future<Either<Failure, CartEntity>> updateQuantity({
    required String itemId,
    required int quantity,
    double? lat,
    double? lng,
    String? addressId,
  });

  Future<Either<Failure, CartEntity>> removeItem(String itemId, {double? lat, double? lng, String? addressId});

  Future<Either<Failure, CartEntity>> clearCart();

  Future<Either<Failure, CartEntity>> applyCoupon(String couponCode, {double? lat, double? lng, String? addressId});

  Future<Either<Failure, CartEntity>> removeCoupon({double? lat, double? lng, String? addressId});

  Future<Either<Failure, CartEntity>> toggleExpressItem(String itemId, {double? lat, double? lng, String? addressId});

  /// Merge guest session cart into the user's cart after login.
  Future<Either<Failure, CartEntity>> mergeGuestCart(String sessionId, {double? lat, double? lng});
}
