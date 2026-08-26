// lib/features/checkout/domain/usecases/get_delivery_slots_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/checkout_repository.dart';

class GetDeliverySlotsUseCase {
  final CheckoutRepository _repository;

  GetDeliverySlotsUseCase(this._repository);

  Future<Either<Failure, Map<String, List<String>>>> call() {
    return _repository.getDeliverySlots();
  }
}
