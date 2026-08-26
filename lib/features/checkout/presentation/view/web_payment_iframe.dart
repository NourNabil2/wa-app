// lib/features/checkout/presentation/view/web_payment_iframe.dart
//
// Web-only: embeds the Telr payment page in an <iframe> using dart:html + HtmlElementView.
// This avoids popup blocker issues entirely — the payment form lives inside the Flutter app.
// Compiled only on Flutter Web (dart.library.html available).

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';


class WebPaymentIframe extends StatefulWidget {
  final String paymentUrl;
  final String viewId;

  const WebPaymentIframe({
    super.key,
    required this.paymentUrl,
    required this.viewId,
  });

  @override
  State<WebPaymentIframe> createState() => _WebPaymentIframeState();
}

class _WebPaymentIframeState extends State<WebPaymentIframe> {
  /// True until the Telr page inside the iframe finishes loading. Telr can take
  /// several seconds; without this the user stares at a blank white area and
  /// assumes the page is broken.
  bool _loading = true;

  StreamSubscription<html.Event>? _loadSub;
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();
    // Register the iframe factory — must happen before HtmlElementView is built
    ui_web.platformViewRegistry.registerViewFactory(
      widget.viewId,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = widget.paymentUrl
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.border = 'none'
          ..allow = 'payment'
          ..setAttribute('allowfullscreen', 'true');

        // Hide the spinner once the framed Telr page has loaded.
        _loadSub = iframe.onLoad.listen((_) {
          if (mounted) setState(() => _loading = false);
        });

        return iframe;
      },
    );

    // Safety net: some browsers don't fire onLoad reliably for cross-origin
    // iframes. Drop the overlay after a max wait so the form is never hidden.
    _safetyTimer = Timer(const Duration(seconds: 12), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _loadSub?.cancel();
    _safetyTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        HtmlElementView(viewType: widget.viewId),
        if (_loading)
          Positioned.fill(
            child: Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'checkout.payment.loadingGateway'.tr(),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
