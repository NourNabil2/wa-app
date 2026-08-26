// lib/features/checkout/presentation/cubit/checkout_state.dart

import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/checkout_entity.dart';
import '../../domain/entities/city_entity.dart';
import '../../domain/entities/payment_method_entity.dart';
import '../../domain/entities/place_order_result.dart';
import '../../domain/entities/saved_address_entity.dart';
import '../../domain/entities/shipping_method_entity.dart';

abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => [];
}

// ─── Loading / Initial ────────────────────────────────────────────────────────

class CheckoutInitial extends CheckoutState {}

class CheckoutLoading extends CheckoutState {}

// ─── Loaded ───────────────────────────────────────────────────────────────────

/// Server-authoritative checkout totals for the CHOSEN shipping method.
///
/// The app used to add the delivery fee onto the total itself and recompute the
/// VAT locally from the goods — which silently understated VAT once the delivery
/// fee became taxable (the fee is VAT-INCLUSIVE, like every price here: a 25 SAR
/// delivery is 21.74 + 3.26 VAT). These figures come from POST /checkout/quote,
/// computed by the same server code that places the order, so the screen and the
/// invoice can never disagree. Never recompute any of this on the client.
class CheckoutQuote extends Equatable {
  final double subtotal;        // goods, VAT-inclusive
  final double couponDiscount;
  final double pointsDiscount;
  final double shippingCost;    // VAT-inclusive, as quoted to the customer
  final double grossTotal;      // (goods − discounts) + delivery
  final double total;           // net of any wallet tender — what is charged
  final double vatAmount;       // VAT inside goods AND delivery
  final double vatRate;
  final bool   vatEnabled;

  const CheckoutQuote({
    required this.subtotal,
    required this.couponDiscount,
    required this.pointsDiscount,
    required this.shippingCost,
    required this.grossTotal,
    required this.total,
    required this.vatAmount,
    required this.vatRate,
    required this.vatEnabled,
  });

  factory CheckoutQuote.fromJson(Map<String, dynamic> j) {
    double d(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
    final vat = (j['vat'] as Map<String, dynamic>?) ?? const {};

    return CheckoutQuote(
      subtotal:       d(j['subtotal']),
      couponDiscount: d(j['coupon_discount']),
      pointsDiscount: d(j['points_discount']),
      shippingCost:   d(j['shipping_cost']),
      grossTotal:     d(j['gross_total']),
      total:          d(j['total']),
      vatAmount:      d(vat['amount']),
      vatRate:        d(vat['rate']),
      vatEnabled:     (vat['enabled'] as bool?) ?? false,
    );
  }

  /// The delivery fee with its own VAT taken out, so the summary rows still add
  /// up to the total once the VAT line covers goods + delivery.
  double get shippingExclVat =>
      vatRate > 0 ? shippingCost / (1 + vatRate / 100) : shippingCost;

  @override
  List<Object?> get props => [subtotal, couponDiscount, pointsDiscount,
      shippingCost, grossTotal, total, vatAmount, vatRate, vatEnabled];
}

class CheckoutLoaded extends CheckoutState {
  final CheckoutEntity checkout;
  final List<ShippingMethodEntity> shippingMethods;
  final List<PaymentMethodEntity> paymentMethods;
  final List<CityEntity> cities;
  final List<CountryEntity> countries;
  final List<AddressEntity> addresses;
  final ShippingMethodEntity? selectedShipping;
  final PaymentMethodEntity? selectedPayment;
  final AddressEntity? selectedAddress;
  final Map<String, dynamic>? guestAddress;
  /// Raw groups from /checkout/summary — contains group_id needed by place-order.
  final List<Map<String, dynamic>> rawGroups;
  /// Per-group shipping selections: { groupId → ShippingMethodEntity }
  /// Used when cart splits into multiple groups (multi-vendor/multi-warehouse).
  final Map<String, ShippingMethodEntity> groupShippingSelections;
  /// Points currently selected by the user to redeem
  final int pointsToUse;
  /// Wallet amount the user chose to apply (SAR). 0 = wallet not used.
  final double walletAmount;
  /// Available delivery slots
  final Map<String, List<String>> deliverySlots;
  final String? selectedDeliveryDate;
  final String? selectedDeliverySlot;

  /// Whether the Saudi National Address (short_address) is required.
  final bool nationalAddressMandatory;
  
  /// The name of the item that caused a stock/warehouse error, to highlight it in the UI.
  final String? errorItemName;

  /// GAP-3: Customer delivery notes (optional, sent with place-order).
  final String? deliveryNotes;

  /// Server-authoritative totals for the current selection. Null until a shipping
  /// method is picked (before that there is nothing to quote). When present it is
  /// the ONLY source of truth for shipping, VAT and total.
  final CheckoutQuote? quote;

  const CheckoutLoaded({
    required this.checkout,
    required this.shippingMethods,
    required this.paymentMethods,
    required this.cities,
    required this.countries,
    required this.addresses,
    this.rawGroups = const [],
    this.groupShippingSelections = const {},
    this.selectedShipping,
    this.selectedPayment,
    this.selectedAddress,
    this.guestAddress,
    this.pointsToUse = 0,
    this.walletAmount = 0.0,
    this.deliverySlots = const {},
    this.selectedDeliveryDate,
    this.selectedDeliverySlot,
    this.nationalAddressMandatory = false,
    this.errorItemName,
    this.deliveryNotes,
    this.quote,
  });

  CheckoutLoaded copyWith({
    CheckoutEntity? checkout,
    List<ShippingMethodEntity>? shippingMethods,
    List<PaymentMethodEntity>? paymentMethods,
    List<CityEntity>? cities,
    List<CountryEntity>? countries,
    List<AddressEntity>? addresses,
    List<Map<String, dynamic>>? rawGroups,
    Map<String, ShippingMethodEntity>? groupShippingSelections,
    ShippingMethodEntity? selectedShipping,
    PaymentMethodEntity? selectedPayment,
    AddressEntity? selectedAddress,
    Map<String, dynamic>? guestAddress,
    int? pointsToUse,
    double? walletAmount,
    Map<String, List<String>>? deliverySlots,
    String? selectedDeliveryDate,
    String? selectedDeliverySlot,
    bool? nationalAddressMandatory,
    String? errorItemName,
    String? deliveryNotes,
    CheckoutQuote? quote,
  }) {
    return CheckoutLoaded(
      checkout:        checkout        ?? this.checkout,
      shippingMethods: shippingMethods ?? this.shippingMethods,
      paymentMethods:  paymentMethods  ?? this.paymentMethods,
      cities:          cities          ?? this.cities,
      countries:       countries       ?? this.countries,
      addresses:       addresses       ?? this.addresses,
      rawGroups:       rawGroups       ?? this.rawGroups,
      groupShippingSelections: groupShippingSelections ?? this.groupShippingSelections,
      selectedShipping: selectedShipping ?? this.selectedShipping,
      selectedPayment:  selectedPayment  ?? this.selectedPayment,
      selectedAddress:  selectedAddress  ?? this.selectedAddress,
      guestAddress:     guestAddress     ?? this.guestAddress,
      pointsToUse:      pointsToUse      ?? this.pointsToUse,
      walletAmount:     walletAmount     ?? this.walletAmount,
      deliverySlots:    deliverySlots    ?? this.deliverySlots,
      selectedDeliveryDate: selectedDeliveryDate ?? this.selectedDeliveryDate,
      selectedDeliverySlot: selectedDeliverySlot ?? this.selectedDeliverySlot,
      nationalAddressMandatory: nationalAddressMandatory ?? this.nationalAddressMandatory,
      errorItemName: errorItemName ?? this.errorItemName,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      quote:         quote         ?? this.quote,
    );
  }

  /// Gross payable total BEFORE the wallet tender is applied — subtotal minus
  /// coupon/points discounts, plus shipping. Mirrors the summary card math
  /// (checkout_screen.dart) and OrderService's per-group $grossTotal.
  double get preWalletGrossTotal {
    // The server already worked this out for the current selection — use it, and
    // only fall back to the local sum before the first quote arrives.
    if (quote != null) return quote!.grossTotal;

    final shipping = selectedShipping ?? groupShippingSelections.values.firstOrNull;
    final isFree = shipping?.isFree ?? false;
    final effectiveShipping = isFree ? 0.0 : (shipping?.cost ?? checkout.shippingCost);
    final rate = (checkout.pointsInfo?['rate'] as num? ?? 100);
    final pointsDiscount = pointsToUse > 0 ? pointsToUse / rate : 0.0;
    return (checkout.subtotal - checkout.discount - pointsDiscount + effectiveShipping)
        .clamp(0.0, double.infinity);
  }

  /// O4b: true when the wallet toggle is on and covers the ENTIRE order — no
  /// payment method/gateway is needed in that case.
  bool get isWalletFullyCovering => walletAmount > 0 && walletAmount >= preWalletGrossTotal - 0.01;

  @override
  List<Object?> get props => [
    checkout, shippingMethods, paymentMethods, cities, countries,
    addresses, rawGroups, groupShippingSelections, selectedShipping,
    selectedPayment, selectedAddress, guestAddress, pointsToUse, walletAmount,
    deliverySlots, selectedDeliveryDate, selectedDeliverySlot,
    nationalAddressMandatory, errorItemName,
    // Must be listed: without it Equatable treats an arriving quote as "no
    // change" and the summary keeps showing the stale, pre-shipping VAT/total.
    quote,
  ];
}

// ─── Checkout-level error ─────────────────────────────────────────────────────

class CheckoutError extends CheckoutState {
  final Failure failure;
  const CheckoutError(this.failure);

  @override
  List<Object?> get props => [failure];
}

// ─── Place Order ──────────────────────────────────────────────────────────────

/// Spinner while place-order API is in flight.
class PlacingOrder extends CheckoutState {}

/// COD order placed — navigate to success screen.
class OrderPlaced extends CheckoutState {
  final PlaceOrderResult result;
  const OrderPlaced(this.result);

  @override
  List<Object?> get props => [result];
}

/// Validation error before calling the API.
class OrderError extends CheckoutState {
  final String message;
  
  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}

/// A payment gateway (e.g. Tabby) DELIBERATELY declined the order — typically the
/// amount is outside its limit. The order was NOT created (or was rolled back) and
/// the cart is preserved. Prompt the customer to choose another payment method.
class PaymentRejected extends CheckoutState {
  final String message;
  const PaymentRejected(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Payment Initiation ───────────────────────────────────────────────────────

/// POST /checkout/initiate-payment in progress — show spinner.
class InitiatingPayment extends CheckoutState {
  final String orderNumber;
  const InitiatingPayment(this.orderNumber);

  @override
  List<Object?> get props => [orderNumber];
}

/// Got a payment_url — screen opens ExternalPaymentPage.
class PaymentInitiated extends CheckoutState {
  final String paymentUrl;
  final String orderNumber;
  final PaymentProvider provider;

  const PaymentInitiated({
    required this.paymentUrl,
    required this.orderNumber,
    required this.provider,
  });

  @override
  List<Object?> get props => [paymentUrl, orderNumber, provider];
}

/// initiate-payment call failed. Carries [orderId] so the screen can retry
/// without re-placing the order.
class PaymentInitiationFailed extends CheckoutState {
  final String message;
  final String orderNumber;
  final String? orderId;

  const PaymentInitiationFailed({
    required this.message,
    required this.orderNumber,
    this.orderId,
  });

  @override
  List<Object?> get props => [message, orderNumber, orderId];
}

// ─── External WebView result ──────────────────────────────────────────────────────

/// Payment gateway returned success status.
class PaymentConfirmed extends CheckoutState {
  final String orderNumber;
  /// Amount the customer paid (group total). Null if the gateway return did
  /// not include it; the success screen then falls back to 0/refetch.
  final double? total;
  const PaymentConfirmed(this.orderNumber, {this.total});

  @override
  List<Object?> get props => [orderNumber, total];
}

/// Telr returned declined / cancelled.
class PaymentFailed extends CheckoutState {
  final String message;
  final String orderNumber;

  const PaymentFailed({required this.message, required this.orderNumber});

  @override
  List<Object?> get props => [message, orderNumber];
}