import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/cart_entity.dart';
import '../repositories/cart_repository.dart';

class RemoveCouponUseCase {
  final CartRepository _repository;
  RemoveCouponUseCase(this._repository);
  Future<Either<Failure, CartEntity>> call({double? lat, double? lng, String? addressId}) =>
      _repository.removeCoupon(lat: lat, lng: lng, addressId: addressId);
}
