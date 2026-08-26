import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/product_details_repository.dart';

class NotifyMeUseCase {
  final ProductDetailsRepository repository;

  NotifyMeUseCase(this.repository);

  Future<Either<Failure, String>> call(String productId) async {
    return await repository.notifyMe(productId);
  }
}
