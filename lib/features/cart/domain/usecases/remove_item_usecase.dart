import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/cart_entity.dart';
import '../repositories/cart_repository.dart';

class RemoveItemUseCase {
  final CartRepository _repository;
  RemoveItemUseCase(this._repository);
  Future<Either<Failure, CartEntity>> call(String itemId, {double? lat, double? lng, String? addressId}) =>
      _repository.removeItem(itemId, lat: lat, lng: lng, addressId: addressId);
}
