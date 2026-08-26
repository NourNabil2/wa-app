// ============================================
// 📁 Domain Layer - Repository
// ============================================

// lib/features/product_details/domain/repositories/product_details_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product_details_entity.dart';

abstract class ProductDetailsRepository {
  Future<Either<Failure, ProductDetailsEntity>> getProductDetails(String productId, {double? lat, double? lng});
  Future<Either<Failure, bool>> toggleFavorite(String productId);
  Future<Either<Failure, String>> joinWaitlist(String productId);
  Future<Either<Failure, String>> notifyMe(String productId);
  Future<Either<Failure, List<ProductQuestion>>> fetchQuestions(String productId);
  Future<Either<Failure, String>> submitQuestion(String productId, String question);
  Future<Either<Failure, String>> submitReview(String productId, int rating, String? comment);
}