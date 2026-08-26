import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/product_details_repository.dart';

class JoinWaitlistUseCase {
  final ProductDetailsRepository repository;

  JoinWaitlistUseCase(this.repository);

  Future<Either<Failure, String>> call(String productId) {
    return repository.joinWaitlist(productId);
  }
}
