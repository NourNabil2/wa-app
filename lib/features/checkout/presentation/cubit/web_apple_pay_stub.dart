// Mobile / non-web stub for the web Apple Pay bridge. The native app uses the
// Telr SDK (TelrSdk.payWithApplePay); this path is never reached off-web.

bool webApplePayAvailable() => false;

Future<String> startWebApplePay(String configJson) async =>
    '{"status":"error","message":"Apple Pay web is not supported on this platform."}';
