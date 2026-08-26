/// Web stub for telr_mobile_payment_sdk.
/// The real SDK is mobile-only (iOS/Android platform channels).
/// On web we stub out the classes so dart2js can compile without errors.
/// The actual Telr payment flow is never triggered on web.

// ignore_for_file: avoid_classes_with_only_static_members

enum TelrPaymentStatus { success, failure, cancelled }

class PaymentResponse {
  final bool success;
  final TelrPaymentStatus status;
  final String message;
  final String? errorCode;
  final String? orderRef;
  final String? transactionRef;
  const PaymentResponse({
    required this.success, 
    required this.status, 
    required this.message,
    this.errorCode,
    this.orderRef,
    this.transactionRef,
  });
}

class TelrSdk {
  static Future<void> init({
    String? applePayMerchantIdentifier,
    String? preferredLanguageCode,
  }) async {
    throw UnsupportedError('Telr SDK is not supported on web.');
  }

  static Future<PaymentResponse> presentPayment(
    String tokenUrl,
    String orderUrl,
  ) async {
    throw UnsupportedError('Telr SDK is not supported on web.');
  }

  /// Native-sheet Apple Pay (merchant-owned button). Never reached on web —
  /// the button is gated behind !kIsWeb — but the symbol must exist so
  /// dart2js can compile the cubit's TelrSdk.payWithApplePay(...) call.
  static Future<PaymentResponse> payWithApplePay(
    String tokenUrl,
    String orderUrl,
  ) async {
    throw UnsupportedError('Telr SDK is not supported on web.');
  }
}
