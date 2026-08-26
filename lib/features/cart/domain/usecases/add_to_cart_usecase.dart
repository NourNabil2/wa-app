import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/cart_entity.dart';
import '../repositories/cart_repository.dart';

class AddToCartUseCase {
  final CartRepository _repository;
  AddToCartUseCase(this._repository);
  Future<Either<Failure, CartEntity>> call({
    required String productId,
    required int quantity,
    double? lat,
    double? lng,
    String? addressId,
  }) => _repository.addToCart(productId: productId, quantity: quantity, lat: lat, lng: lng, addressId: addressId);
}
