// lib/features/checkout/presentation/view/web_payment_listener_stub.dart
//
// Mobile/desktop stub for WebPaymentListener.
// dart:html is NOT available on mobile — this file is compiled instead.

import 'dart:async';

class WebPaymentListener {
  /// On non-web platforms, window.postMessage doesn't exist.
  /// Return an empty stream that never emits — the mobile path uses
  /// WebView URL interception instead.
  static Stream<Map<String, dynamic>> get onMessage =>
      const Stream.empty();
}
