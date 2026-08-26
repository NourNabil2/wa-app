import 'package:fastway/features/checkout/domain/entities/place_order_result.dart';

class PlaceOrderResultModel extends PlaceOrderResult {
  const PlaceOrderResultModel({
    required super.orderNumber,
    required super.status,
    required super.total,
    super.paymentUrl,
    super.paymentReference,
    required super.isCod,
    required super.orderId,
    super.pointsEarned,
    super.estimatedDelivery,
    super.isWalletOnly,
  });

  /// Parses both API response shapes:
  ///
  ///  Shape A — COD / old flow:
  ///    { data: { orders: [{order_number, ...}], payment_initiation: {is_cod: true} } }
  ///
  ///  Shape B — Non-COD deferred checkout (Telr intent):
  ///    { data: { intent_id: "CI-xxx", payment_initiation: {payment_url, is_cod: false} } }
  factory PlaceOrderResultModel.fromJson(Map<String, dynamic> json) {
    final data    = (json['data'] as Map<String, dynamic>?) ?? json;
    final payment = (data['payment_initiation'] as Map<String, dynamic>?) ?? {};

    // ── Shape B: deferred checkout intent (non-COD Telr) ──────────────────
    final intentId = data['intent_id']?.toString();
    if (intentId != null && intentId.isNotEmpty) {
      return PlaceOrderResultModel(
        orderNumber:      intentId,  // intent_id used as placeholder until real order created
        orderId:          intentId,
        status:           'pending',
        total:            0.0,
        paymentUrl:       payment['payment_url']?.toString(),
        paymentReference: payment['reference']?.toString(),
        isCod:            false,
      );
    }

    // ── Shape A: order already created (COD or legacy online) ──────────────
    final orderRaw = data['orders'] is List && (data['orders'] as List).isNotEmpty
        ? (data['orders'] as List).first as Map<String, dynamic>
        : data['order'] as Map<String, dynamic>? ?? {};

    return PlaceOrderResultModel(
      orderNumber:       orderRaw['order_number']?.toString() ?? '',
      orderId:           (orderRaw['id'] ?? '').toString(),
      status:            orderRaw['status']?.toString() ?? 'pending',
      total:             (orderRaw['total'] as num?)?.toDouble() ?? 0.0,
      paymentUrl:        payment['payment_url']?.toString(),
      paymentReference:  payment['reference']?.toString(),
      isCod:             payment['is_cod'] as bool? ?? true,
      pointsEarned:      (orderRaw['points_earned'] as num?)?.toInt(),
      estimatedDelivery: orderRaw['estimated_delivery']?.toString(),
      isWalletOnly:      payment['is_wallet_only'] as bool? ?? false,
    );
  }
}