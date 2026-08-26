import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/wishlist_repository.dart';

class ToggleWishlistUseCase {
  final WishlistRepository repository;

  ToggleWishlistUseCase(this.repository);

  Future<Either<Failure, ({bool isWishlisted, int count})>> call(String productId) async {
    return await repository.toggleWishlist(productId);
  }
}
