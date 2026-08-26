import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/cart_entity.dart';
import '../repositories/cart_repository.dart';

class ApplyCouponUseCase {
  final CartRepository _repository;
  ApplyCouponUseCase(this._repository);
  Future<Either<Failure, CartEntity>> call(String couponCode, {double? lat, double? lng, String? addressId}) =>
      _repository.applyCoupon(couponCode, lat: lat, lng: lng, addressId: addressId);
}
