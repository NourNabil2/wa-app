// lib/features/checkout/presentation/view/external_payment_page_web_stub.dart
//
// Web stub for MobilePaymentWebView — compiled only on Flutter Web.
// webview_flutter is NOT available on web; this prevents import errors.

import 'package:flutter/material.dart';

/// No-op stub used on Flutter Web. ExternalPaymentPage never instantiates
/// this on web (it uses url_launcher + polling instead).
class MobilePaymentWebView extends StatelessWidget {
  final String paymentUrl;
  final String orderNumber;
  final String returnPath;
  // Ignored on web — included so the shared call-site in
  // external_payment_page.dart compiles on all platforms.
  final VoidCallback? onReturnUrlDetected;

  const MobilePaymentWebView({
    super.key,
    required this.paymentUrl,
    required this.orderNumber,
    required this.returnPath,
    this.onReturnUrlDetected,
  });

  @override
  Widget build(BuildContext context) {
    // This widget is never shown on web — ExternalPaymentPage checks kIsWeb
    // before rendering MobilePaymentWebView.
    return const SizedBox.shrink();
  }
}
