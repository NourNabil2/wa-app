// lib/features/product_details/data/repositories/product_details_repository_impl.dart
// BUG-42 FIX: Rewired to use ProductDetailsRemoteDataSource — no more fake data
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/product_details_entity.dart';
import '../../domain/repositories/product_details_repository.dart';
import '../datasources/product_details_remote_datasource.dart';

class ProductDetailsRepositoryImpl implements ProductDetailsRepository {
  final ProductDetailsRemoteDataSource _remote;

  ProductDetailsRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, ProductDetailsEntity>> getProductDetails(
      String productId, {double? lat, double? lng}) async {
    try {
      final product = await _remote.getProductDetails(productId, lat: lat, lng: lng);
      return Right(product);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, bool>> addToCart(
      String productId, int quantity) async {
    // addToCart is delegated to CartRepository — this is a UI convenience method
    // Return true to let CartCubit handle the actual cart addition
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> toggleFavorite(String productId) async {
    // Wishlist feature — placeholder until wishlist endpoint is available
    return const Right(false); // Return false safely
  }

  @override
  Future<Either<Failure, String>> joinWaitlist(String productId) async {
    try {
      final message = await _remote.joinWaitlist(productId);
      return Right(message);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  @override
  Future<Either<Failure, String>> notifyMe(String productId) async {
    try {
      final message = await _remote.notifyMe(productId);
      return Right(message);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductQuestion>>> fetchQuestions(String productId) async {
    try {
      final raw = await _remote.fetchQuestions(productId);
      final questions = raw.map((q) => ProductQuestion(
        id: q['id'].toString(),
        question: q['question'] as String? ?? '',
        answer: q['answer'] as String?,
        userName: q['user_name'] as String? ?? 'Customer',
        answeredAt: q['answered_at'] != null ? DateTime.tryParse(q['answered_at'] as String) : null,
        askedAt: DateTime.tryParse(q['asked_at'] as String? ?? '') ?? DateTime.now(),
      )).toList();
      return Right(questions);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> submitQuestion(String productId, String question) async {
    try {
      final message = await _remote.submitQuestion(productId, question);
      return Right(message);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> submitReview(
      String productId, int rating, String? comment) async {
    try {
      final message = await _remote.submitReview(productId, rating, comment);
      return Right(message);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
