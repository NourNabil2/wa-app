// lib/features/checkout/domain/repositories/checkout_repository.dart

import 'package:dartz/dartz.dart';
import 'package:fastway/features/checkout/domain/entities/city_entity.dart';
import 'package:fastway/features/checkout/domain/entities/payment_method_entity.dart';
import 'package:fastway/features/checkout/domain/entities/place_order_result.dart';
import 'package:fastway/features/checkout/domain/entities/sdk_order_init.dart';
import 'package:fastway/features/checkout/domain/entities/shipping_method_entity.dart';
import '../../../../core/errors/failures.dart';

abstract class CheckoutRepository {
  Future<Either<Failure, List<ShippingMethodEntity>>> getShippingMethods();
  Future<Either<Failure, List<PaymentMethodEntity>>> getPaymentMethods();
  Future<Either<Failure, List<CityEntity>>> getCities();
  Future<Either<Failure, List<CountryEntity>>> getCountries();
  Future<Either<Failure, Map<String, List<String>>>> getDeliverySlots();

  Future<Either<Failure, Map<String, dynamic>>> getCheckoutSummary({double? lat, double? lng});

  /// Server-authoritative totals for the chosen shipping method (incl. the VAT
  /// that sits inside the delivery fee).
  Future<Either<Failure, Map<String, dynamic>>> getCheckoutQuote({
    required List<Map<String, dynamic>> groups,
    int? pointsToUse,
    double? walletAmount,
    bool? useWallet,
  });

  // Authenticated — uses saved address_id. paymentMethodId is null for a
  // pure wallet-only order (backend re-verifies wallet covers the total).
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
  });

  // Guest — uses inline guestAddress map + X-Session-ID header
  Future<Either<Failure, PlaceOrderResult>> placeGuestOrder({
    required List<Map<String, dynamic>> groups,
    required int paymentMethodId,
    required Map<String, dynamic> guestAddress,
    String? notes,
    int? pointsToUse,
    double? walletAmount,
    String? deliveryDate,
    String? deliverySlot,
  });

  Future<Either<Failure, String>> initiatePayment(String orderId);

  /// Cancel an unpaid BNPL order group and rebuild the cart from its items.
  Future<Either<Failure, void>> cancelUnpaid(String orderId);

  /// Seed the cart from an admin payment link (owner-only) → prefill map
  /// { wallet_to_apply, shipping_method_id, payment_method_id, coupon_code, address }.
  Future<Either<Failure, Map<String, dynamic>>> loadPayLinkToCart(String token);

  /// Apple Pay (Telr SDK) — create the Telr order; returns the SDK's tokenUrl/orderUrl + apRef.
  Future<Either<Failure, SdkOrderInit>> createSdkOrder({
    required int paymentMethodId,
    required List<Map<String, dynamic>> groups,
    int? addressId,
    Map<String, dynamic>? guestAddress,
    String? notes,
    int? pointsToUse,
    String? deliveryDate,
    String? deliverySlot,
  });

  /// Apple Pay (Telr SDK) — confirm the charge server-side; returns the created order number.
  Future<Either<Failure, String>> confirmSdkPayment(String apRef);
}