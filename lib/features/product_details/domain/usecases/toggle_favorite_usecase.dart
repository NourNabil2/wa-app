// lib/features/product_details/domain/usecases/toggle_favorite_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/product_details_repository.dart';

class ToggleFavoriteProductUseCase {
  final ProductDetailsRepository repository;

  ToggleFavoriteProductUseCase(this.repository);

  Future<Either<Failure, bool>> call(String productId) async {
    return await repository.toggleFavorite(productId);
  }
}
