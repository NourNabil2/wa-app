import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/cart_entity.dart';
import '../repositories/cart_repository.dart';

/// Merges a guest session cart into the authenticated user's cart.
/// Call this immediately after login, passing the local session UUID.
class MergeGuestCartUseCase {
  final CartRepository _repository;
  MergeGuestCartUseCase(this._repository);

  Future<Either<Failure, CartEntity>> call(String sessionId, {double? lat, double? lng}) =>
      _repository.mergeGuestCart(sessionId, lat: lat, lng: lng);
}
