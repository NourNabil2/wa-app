import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wishlist_entity.dart';
import '../repositories/wishlist_repository.dart';

class GetWishlistUseCase {
  final WishlistRepository repository;

  GetWishlistUseCase(this.repository);

  Future<Either<Failure, WishlistEntity>> call() async {
    return await repository.getWishlist();
  }
}
