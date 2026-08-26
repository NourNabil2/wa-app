import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wishlist_entity.dart';

abstract class WishlistRepository {
  Future<Either<Failure, WishlistEntity>> getWishlist();
  Future<Either<Failure, ({bool isWishlisted, int count})>> toggleWishlist(String productId);
  Future<Either<Failure, int>> removeItem(String wishlistItemId);
  Future<Either<Failure, void>> clearWishlist();
}
