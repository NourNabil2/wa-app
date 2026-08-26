// lib/features/home/data/repositories/products_repository_impl.dart
// Updated to use remote datasource
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/products_repository.dart';
import '../datasources/products_remote_datasource.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  final ProductsRemoteDataSource _remote;

  ProductsRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final products = await _remote.getProducts(page: page, perPage: perPage);
      return Right(products.cast<ProductEntity>());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}