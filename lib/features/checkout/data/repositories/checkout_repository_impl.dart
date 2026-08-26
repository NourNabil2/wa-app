// lib/features/checkout/data/repositories/checkout_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:fastway/features/checkout/domain/entities/city_entity.dart';
import 'package:fastway/features/checkout/domain/entities/payment_method_entity.dart';
import 'package:fastway/features/checkout/domain/entities/place_order_result.dart';
import 'package:fastway/features/checkout/domain/entities/sdk_order_init.dart';
import 'package:fastway/features/checkout/domain/entities/shipping_method_entity.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result_handler.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../datasources/checkout_remote_datasource.dart';

class CheckoutRepositoryImpl implements CheckoutRepository {
  final CheckoutRemoteDataSource _remoteDataSource;

  CheckoutRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<ShippingMethodEntity>>> getShippingMethods() {
    return ResultHandler.handle(() => _remoteDataSource.getShippingMethods());
  }

  @override
  Future<Either<Failure, List<PaymentMethodEntity>>> getPaymentMethods() {
    return ResultHandler.handle(() => _remoteDataSource.getPaymentMethods());
  }

  @override
  Future<Either<Failure, List<CityEntity>>> getCities() {
    return ResultHandler.handle(() => _remoteDataSource.getCities());
  }

  @override
  Future<Either<Failure, List<CountryEntity>>> getCountries() {
    return ResultHandler.handle(() => _remoteDataSource.getCountries());
  }

  @override
  Future<Either<Failure, Map<String, List<String>>>> getDeliverySlots() {
    return ResultHandler.handle(() => _remoteDataSource.getDeliverySlots());
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getCheckoutSummary({double? lat, double? lng}) {
    return ResultHandler.handle(() => _remoteDataSource.getCheckoutSummary(lat: lat, lng: lng));
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getCheckoutQuote({
    required List<Map<String, dynamic>> groups,
    int? pointsToUse,
    double? walletAmount,
    bool? useWallet,
  }) {
    return ResultHandler.handle(() => _remoteDataSource.getCheckoutQuote(
          groups: groups,
          pointsToUse: pointsToUse,
          walletAmount: walletAmount,
          useWallet: useWallet,
        ));
  }

  @override
  Future<Either<Failure, PlaceOrderResult>> placeOrder({
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
    return ResultHandler.handle(
          () => _remoteDataSource.placeOrder(
        groups: groups,
        paymentMethodId: paymentMethodId,
        addressId: addressId,
        notes: notes,
        pointsToUse: pointsToUse,
        walletAmount: walletAmount,
        useWallet: useWallet,
        deliveryDate: deliveryDate,
        deliverySlot: deliverySlot,
      ),
    );
  }

  // Guest order — X-Session-ID sent automatically by DioApiService
  @override
  Future<Either<Failure, PlaceOrderResult>> placeGuestOrder({
    required List<Map<String, dynamic>> groups,
    required int paymentMethodId,
    required Map<String, dynamic> guestAddress,
    String? notes,
    int? pointsToUse,
    double? walletAmount,
    String? deliveryDate,
    String? deliverySlot,
  }) {
    return ResultHandler.handle(
          () => _remoteDataSource.placeGuestOrder(
        groups: groups,
        paymentMethodId: paymentMethodId,
        guestAddress: guestAddress,
        notes: notes,
        pointsToUse: pointsToUse,
        walletAmount: walletAmount,
        deliveryDate: deliveryDate,
        deliverySlot: deliverySlot,
      ),
    );
  }

  @override
  Future<Either<Failure, String>> initiatePayment(String orderId) {
    return ResultHandler.handle(
            () => _remoteDataSource.initiatePayment(orderId));
  }

  @override
  Future<Either<Failure, void>> cancelUnpaid(String orderId) {
    return ResultHandler.handle(
            () => _remoteDataSource.cancelUnpaid(orderId));
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> loadPayLinkToCart(String token) {
    return ResultHandler.handle(
            () => _remoteDataSource.loadPayLinkToCart(token));
  }

  @override
  Future<Either<Failure, SdkOrderInit>> createSdkOrder({
    required int paymentMethodId,
    required List<Map<String, dynamic>> groups,
    int? addressId,
    Map<String, dynamic>? guestAddress,
    String? notes,
    int? pointsToUse,
    String? deliveryDate,
    String? deliverySlot,
  }) {
    return ResultHandler.handle(
      () => _remoteDataSource.createSdkOrder(
        paymentMethodId: paymentMethodId,
        groups:          groups,
        addressId:       addressId,
        guestAddress:    guestAddress,
        notes:           notes,
        pointsToUse:     pointsToUse,
        deliveryDate:    deliveryDate,
        deliverySlot:    deliverySlot,
      ),
    );
  }

  @override
  Future<Either<Failure, String>> confirmSdkPayment(String apRef) {
    return ResultHandler.handle(() => _remoteDataSource.confirmSdkPayment(apRef));
  }
}