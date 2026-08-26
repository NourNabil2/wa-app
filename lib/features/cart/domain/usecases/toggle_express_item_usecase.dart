import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/cart_entity.dart';
import '../repositories/cart_repository.dart';

class ToggleExpressItemUseCase {
  final CartRepository repository;
  ToggleExpressItemUseCase(this.repository);
  Future<Either<Failure, CartEntity>> call(String itemId, {double? lat, double? lng, String? addressId}) {
    return repository.toggleExpressItem(itemId, lat: lat, lng: lng, addressId: addressId);
  }
}
