// lib/features/checkout/domain/usecases/place_order_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:fastway/features/checkout/domain/entities/place_order_result.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/checkout_repository.dart';

class PlaceOrderUseCase {
  final CheckoutRepository _repository;

  PlaceOrderUseCase(this._repository);

  // Authenticated user — POST /checkout/place-order. paymentMethodId is null
  // for a pure wallet-only order (backend re-verifies wallet covers the total).
  Future<Either<Failure, PlaceOrderResult>> call({
    required List<Map<String, dynamic>> groups,
    int? paymentMethodId,
    int? addressId,
    String? notes,
    int? pointsToUse,
    double? walletAmount,
    bool? useWallet,
    String? deliveryDate,
    String? deliverySlot,
  }) {
    return _repository.placeOrder(
      groups: groups,
      paymentMethodId: paymentMethodId,
      addressId: addressId,
      notes: notes,
      pointsToUse: pointsToUse,
      walletAmount: walletAmount,
      useWallet: useWallet,
      deliveryDate: deliveryDate,
      deliverySlot: deliverySlot,
    );
  }

  // Guest user — POST /checkout/guest-place-order
  Future<Either<Failure, PlaceOrderResult>> placeGuest({
    required List<Map<String, dynamic>> groups,
    required int paymentMethodId,
    required Map<String, dynamic> guestAddress,
    String? notes,
    int? pointsToUse,
    double? walletAmount,
    String? deliveryDate,
    String? deliverySlot,
  }) {
    return _repository.placeGuestOrder(
      groups: groups,
      paymentMethodId: paymentMethodId,
      guestAddress: guestAddress,
      notes: notes,
      pointsToUse: pointsToUse,
      walletAmount: walletAmount,
      deliveryDate: deliveryDate,
      deliverySlot: deliverySlot,
    );
  }
}