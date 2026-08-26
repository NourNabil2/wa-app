// lib/features/checkout/presentation/view/web_payment_listener.dart
//
// Web-only implementation: exposes window.onMessage as a Dart Stream.
// Compiled ONLY on Flutter Web (dart.library.html is available).
// The stub (web_payment_listener_stub.dart) is used on mobile/desktop.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:convert';

class WebPaymentListener {
  /// Stream of parsed JSON messages from window.postMessage.
  /// Filters to objects only — ignores strings, numbers, etc.
  static Stream<Map<String, dynamic>> get onMessage {
    return html.window.onMessage
        .map((event) {
          final data = event.data;
          if (data is Map) {
            return Map<String, dynamic>.from(data);
          }
          // Some browsers pass a JSON string instead of an object
          if (data is String) {
            try {
              final decoded = json.decode(data);
              if (decoded is Map) return Map<String, dynamic>.from(decoded);
            } catch (_) {}
          }
          return null;
        })
        .where((e) => e != null)
        .cast<Map<String, dynamic>>();
  }
}
