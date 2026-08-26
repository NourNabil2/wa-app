// lib/features/checkout/domain/entities/sdk_order_init.dart
//
// Result of starting an Apple Pay charge via the Telr Flutter SDK.
// The two URLs come from Telr's order _links and are passed to
// TelrSdk.payWithApplePay(tokenUrl, orderUrl). apRef is used to confirm
// the charge server-side after the sheet closes.

class SdkOrderInit {
  final String apRef;
  final String tokenUrl;
  final String orderUrl;
  final String? amount;

  const SdkOrderInit({
    required this.apRef,
    required this.tokenUrl,
    required this.orderUrl,
    this.amount,
  });
}
