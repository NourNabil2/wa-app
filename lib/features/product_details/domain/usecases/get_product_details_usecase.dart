// ============================================
// 📁 Domain Layer - Use Cases
// ============================================

// lib/features/product_details/domain/usecases/get_product_details_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product_details_entity.dart';
import '../repositories/product_details_repository.dart';

class GetProductDetailsUseCase {
  final ProductDetailsRepository repository;

  GetProductDetailsUseCase(this.repository);

  Future<Either<Failure, ProductDetailsEntity>> call(String productId, {double? lat, double? lng}) async {
    return await repository.getProductDetails(productId, lat: lat, lng: lng);
  }
}
