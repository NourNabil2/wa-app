import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('fastway/native');

/// Dismisses any native view controller left presented above the Flutter view.
///
/// Works around a bug in telr_mobile_payment_sdk 4.4.0 (latest at time of
/// writing): its iOS `payWithApplePay` never dismisses the view controller the
/// native SDK presented, while every other method in that same plugin does:
///
///   presentPayment / payWithCard / payWithSavedCard:
///     onFinish: { topVC.dismiss(animated: true) { flutterResult(payload) } }
///   payWithApplePay:
///     onFinish: { flutterResult(payload) }        // ← no dismiss
///
/// The result is that after a successful Apple Pay charge the sheet stays on
/// screen with a dead close button and the customer has to kill the app. Calling
/// this once the SDK returns performs the dismissal the plugin skipped.
///
/// Safe to call unconditionally: it is a no-op off iOS, and on iOS it does
/// nothing when no view controller is presented.
Future<void> dismissStrandedNativeSheet() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
  try {
    await _channel.invokeMethod<bool>('dismissPresented');
  } catch (_) {
    // Channel not registered (e.g. an older build) — nothing to dismiss.
  }
}
