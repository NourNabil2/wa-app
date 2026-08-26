// lib/features/checkout/presentation/view/web_payment_iframe_stub.dart
//
// Mobile/desktop stub for WebPaymentIframe — dart:html is unavailable on mobile.

import 'package:flutter/material.dart';

class WebPaymentIframe extends StatelessWidget {
  final String paymentUrl;
  final String viewId;

  const WebPaymentIframe({
    super.key,
    required this.paymentUrl,
    required this.viewId,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
