import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/cart_entity.dart';
import '../repositories/cart_repository.dart';

class UpdateQuantityUseCase {
  final CartRepository _repository;
  UpdateQuantityUseCase(this._repository);
  Future<Either<Failure, CartEntity>> call({
    required String itemId,
    required int quantity,
    double? lat,
    double? lng,
    String? addressId,
  }) => _repository.updateQuantity(itemId: itemId, quantity: quantity, lat: lat, lng: lng, addressId: addressId);
}
