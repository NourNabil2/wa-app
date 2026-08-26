import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/wishlist_repository.dart';

class RemoveWishlistItemUseCase {
  final WishlistRepository repository;

  RemoveWishlistItemUseCase(this.repository);

  Future<Either<Failure, int>> call(String wishlistItemId) async {
    return await repository.removeItem(wishlistItemId);
  }
}
