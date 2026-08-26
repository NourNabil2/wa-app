import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/wishlist_entity.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../datasources/wishlist_remote_datasource.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final WishlistRemoteDataSource _remote;
  WishlistRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, WishlistEntity>> getWishlist() async {
    try {
      return Right(await _remote.getWishlist());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, ({bool isWishlisted, int count})>> toggleWishlist(String productId) async {
    try {
      final data = await _remote.toggleWishlist(productId);
      return Right((
        isWishlisted: data['is_wishlisted'] as bool,
        count: data['count'] as int,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, int>> removeItem(String wishlistItemId) async {
    try {
      return Right(await _remote.removeItem(wishlistItemId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> clearWishlist() async {
    try {
      await _remote.clearWishlist();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
