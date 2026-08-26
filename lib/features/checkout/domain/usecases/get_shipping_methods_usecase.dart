import 'package:dartz/dartz.dart';
import 'package:fastway/features/checkout/domain/entities/shipping_method_entity.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/checkout_repository.dart';

class GetShippingMethodsUseCase {
  final CheckoutRepository _repository;

  GetShippingMethodsUseCase(this._repository);

  Future<Either<Failure, List<ShippingMethodEntity>>> call() {
    return _repository.getShippingMethods();
  }
}
