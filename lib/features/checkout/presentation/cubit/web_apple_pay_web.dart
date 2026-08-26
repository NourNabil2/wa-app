// Web implementation of the Apple Pay bridge — thin js_interop over the
// window.fastwayApplePay module defined in web/apple_pay.js.
//
// startWebApplePay MUST be invoked synchronously from the tap handler: it calls
// fastwayApplePay.start(...) without awaiting first, so the ApplePaySession is
// created inside the user gesture (a Safari requirement). The returned Future
// resolves later with the JSON result string.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Master switch for Apple Pay on the WEB checkout. OFF until the remaining
/// Apple-side setup is done — Apple Pay on the web additionally requires a
/// **Merchant Identity Certificate** (a different certificate from the Payment
/// Processing one Telr holds for the app) and each website domain to be
/// registered + verified in the Apple Developer account. Without those, Safari
/// fails merchant validation and the button can only ever error out, so we do
/// not show it at all.
///
/// The app (iOS) Apple Pay flow is unaffected — it goes through the Telr SDK
/// and never touches this file. Flip to `true` once the cert + domain
/// verification are in place; all the web plumbing below is already built.
const bool kWebApplePayEnabled = false;

@JS('fastwayApplePay')
external JSObject get _fastwayApplePay;

bool _hasBridge() {
  try {
    return globalContext.has('fastwayApplePay');
  } catch (_) {
    return false;
  }
}

bool webApplePayAvailable() {
  if (!kWebApplePayEnabled) return false;
  if (!_hasBridge()) return false;
  try {
    final result = _fastwayApplePay.callMethod('available'.toJS);
    return (result as JSBoolean?)?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

/// Non-async on purpose: `.start(...)` runs synchronously (creating the
/// ApplePaySession in the gesture) and returns a Promise we adapt to a Future.
Future<String> startWebApplePay(String configJson) {
  if (!_hasBridge()) {
    return Future.value(
        '{"status":"error","message":"Apple Pay script not loaded."}');
  }
  final JSPromise<JSString> promise =
      _fastwayApplePay.callMethod('start'.toJS, configJson.toJS)
          as JSPromise<JSString>;
  return promise.toDart.then((JSString v) => v.toDart);
}
