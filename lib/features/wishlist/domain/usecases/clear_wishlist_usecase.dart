import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/wishlist_repository.dart';

class ClearWishlistUseCase {
  final WishlistRepository repository;

  ClearWishlistUseCase(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.clearWishlist();
  }
}
