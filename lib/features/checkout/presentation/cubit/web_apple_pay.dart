// Web Apple Pay bridge — chooses the real js_interop implementation on web and a
// no-op stub everywhere else (mobile), so the app compiles on all platforms.
//
//  webApplePayAvailable() -> true only in a browser where ApplePaySession can pay.
//  startWebApplePay(cfg)  -> drives window.fastwayApplePay.start; returns a JSON
//                            result string (see web/apple_pay.js).
export 'web_apple_pay_stub.dart'
    if (dart.library.html) 'web_apple_pay_web.dart';
