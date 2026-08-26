// lib/features/checkout/domain/entities/place_order_result.dart

class PlaceOrderResult {
  /// Numeric DB id — used to call POST /checkout/initiate-payment.
  final String orderId;

  /// Human-readable order number, e.g. "ORD-2026806670".
  final String orderNumber;

  final String status;
  final double total;

  /// Non-null when the gateway URL was already returned by place-order.
  final String? paymentUrl;
  final String? paymentReference;

  /// True = cash on delivery, no WebView needed.
  final bool isCod;

  /// Non-null when place-order succeeded but payment initiation failed
  /// server-side (e.g. Telr config error). We still have a valid order.
  final String? paymentError;

  /// Points earned from this order (API: data.order.points_earned).
  /// null = API did not return points info (e.g. guest order).
  final int? pointsEarned;

  /// Human-readable estimated delivery string (API: data.order.estimated_delivery).
  /// e.g. "2–4 business days"
  final String? estimatedDelivery;

  /// True = paid entirely from the customer's wallet, no gateway involved
  /// (O4b). Like COD, no WebView/redirect is needed — the order is already
  /// captured by the time this result comes back.
  final bool isWalletOnly;

  const PlaceOrderResult({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.total,
    this.paymentUrl,
    this.paymentReference,
    required this.isCod,
    this.paymentError,
    this.pointsEarned,
    this.estimatedDelivery,
    this.isWalletOnly = false,
  });
}