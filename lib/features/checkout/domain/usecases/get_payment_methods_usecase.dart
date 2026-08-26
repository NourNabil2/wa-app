import 'package:dartz/dartz.dart';
import 'package:fastway/features/checkout/domain/entities/payment_method_entity.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/checkout_repository.dart';

class GetPaymentMethodsUseCase {
  final CheckoutRepository _repository;

  GetPaymentMethodsUseCase(this._repository);

  Future<Either<Failure, List<PaymentMethodEntity>>> call() {
    return _repository.getPaymentMethods();
  }
}
