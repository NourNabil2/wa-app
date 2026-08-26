// lib/features/checkout/presentation/view/external_payment_page.dart
//
// Platform-aware payment page:
//   • Telr on Web     → <iframe> embedding (HtmlElementView) + window.postMessage listener
//   • Telr on Mobile  → webview_flutter URL-intercept
//   • Tabby/Tamara    → external browser on ALL platforms + polling
//                       (their checkout pages block iframe/WebView embedding)

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/di/injection_container.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';
import '../../domain/entities/payment_method_entity.dart';
import '../../domain/entities/place_order_result.dart';
import '../../../../core/api/model/endpoints.dart';
import '../../../../core/routes/routes.dart';

// Conditional imports — only the correct file is compiled per platform
import 'web_payment_listener.dart'
    if (dart.library.io) 'web_payment_listener_stub.dart';

import 'web_payment_iframe.dart'
    if (dart.library.io) 'web_payment_iframe_stub.dart';

import 'external_payment_page_mobile.dart'
    if (dart.library.html) 'external_payment_page_web_stub.dart';

class ExternalPaymentPage extends StatefulWidget {
  final String paymentUrl;
  final String orderNumber;
  final PaymentProvider provider;

  const ExternalPaymentPage({
    super.key,
    required this.paymentUrl,
    required this.orderNumber,
    required this.provider,
  });

  @override
  State<ExternalPaymentPage> createState() => _ExternalPaymentPageState();
}

class _ExternalPaymentPageState extends State<ExternalPaymentPage> {
  /// Tabby and Tamara block iframe/WebView embedding — must use external browser.
  bool get _isBnpl =>
      widget.provider == PaymentProvider.tabby ||
      widget.provider == PaymentProvider.tamara;

  /// Set to true only when an ACTUAL payment result arrives. Drives the confirmed overlay.
  bool _paymentCaptured = false;

  /// Set as soon as Telr redirects to our return URL (mobile/web). Locks the X button.
  bool _xLocked = false;

  /// Set to true once we've dispatched the result to the cubit (avoid double-fire).
  bool _handled = false;

  /// Set to true when the user explicitly cancels a BNPL payment.
  /// Switches the waiting screen to an inline cancelled view (no navigation needed on web).
  bool _bnplCancelled = false;

  StreamSubscription<Map<String, dynamic>>? _messageSub;

  // BNPL polling
  Timer? _pollTimer;
  int    _pollSeconds = 0;
  static const int _kPollIntervalSec = 5;
  static const int _kMaxPollSeconds  = 300;

  // Unique ID for the HtmlElementView platform view factory
  late final String _iframeViewId =
      'telr-payment-iframe-${widget.orderNumber}';

  @override
  void initState() {
    super.initState();
    if (_isBnpl) {
      // Open in external browser — Tabby/Tamara block iframe/WebView embedding.
      _openExternalBrowser();
      _startBnplPolling();
    } else if (kIsWeb) {
      _messageSub = WebPaymentListener.onMessage.listen(_onMessage);
    }
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  // ─── BNPL: external browser + polling ────────────────────────────────────

  Future<void> _openExternalBrowser() async {
    final uri = Uri.tryParse(widget.paymentUrl);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Browser could not be opened — user will see the "Re-open" button.
    }
  }

  void _startBnplPolling() {
    _pollTimer = Timer.periodic(
      const Duration(seconds: _kPollIntervalSec),
      (_) async {
        if (!mounted || _handled) { _pollTimer?.cancel(); return; }
        _pollSeconds += _kPollIntervalSec;
        if (_pollSeconds >= _kMaxPollSeconds) { _pollTimer?.cancel(); return; }

        if (widget.orderNumber.isEmpty || widget.orderNumber.startsWith('CI-')) return;

        try {
          final url = '${Endpoints.baseUrl}${Endpoints.paymentStatus}/${widget.orderNumber}';
          final response = await sl<Dio>().get(
            url,
            options: Options(headers: {'Accept': 'application/json'}),
          );
          final data = (response.data?['data'] as Map<String, dynamic>?) ?? {};
          final paymentStatus = (data['payment_status'] ?? '').toString();

          if (paymentStatus == 'pending' || paymentStatus == 'pending_payment') return;

          if (paymentStatus == 'authorised' || paymentStatus == 'declined' ||
              paymentStatus == 'cancelled'  || paymentStatus == 'failed') {
            _pollTimer?.cancel();
            if (!mounted || _handled) return;
            _handled = true;
            context.read<CheckoutCubit>().handlePaymentReturn(
              Uri.parse(
                '${Endpoints.baseUrl}$_returnPath'
                '?status=$paymentStatus&order_id=${widget.orderNumber}&cartid=${widget.orderNumber}',
              ),
            );
          }
        } catch (_) {
          // Network error during poll — keep retrying.
        }
      },
    );
  }

  // ─── postMessage handler ──────────────────────────────────────────────────

  void _onMessage(Map<String, dynamic> data) {
    if (_handled) return;
    if (data['type'] != 'telr_payment_result') return;

    // For CI- deferred intents the server creates the order and posts back
    // the REAL ORD-xxx order number — widget.orderNumber is still CI-xxx at
    // this point, so we must NOT filter by equality.
    // The 'type' guard above is sufficient to avoid cross-page interference.
    final isIntent = widget.orderNumber.startsWith('CI-');
    if (!isIntent && data['order_number'] != widget.orderNumber) return;

    // ① Disable the X button immediately — before cubit processes the result.
    //    Prevents the user from pressing cancel during the brief navigation delay.
    if (mounted) setState(() => _paymentCaptured = true);

    _handled = true;
    _messageSub?.cancel();

    final paymentStatus = (data['payment_status'] ?? '').toString();
    final orderNumber   = (data['order_number'] ?? widget.orderNumber).toString();
    final total         = (data['total'] ?? '').toString();

    if (!mounted) return;

    if (isIntent) {
      // Server already processed the intent and created the real order.
      // Use handleDeepLinkPaymentResult so the cubit receives ORD-xxx.
      final resultUri = Uri(
        scheme: 'fastway',
        host:   'payment-result',
        queryParameters: {
          'success':      data['success'] == true ? 'true' : 'false',
          'order_number': orderNumber,
          'status':       paymentStatus,
          'total':        total,
        },
      );
      context.read<CheckoutCubit>().handleDeepLinkPaymentResult(resultUri);
    } else {
      // Legacy flow: order existed before payment — call the return URL handler.
      final returnUri = Uri.parse(
        '${Endpoints.baseUrl.replaceAll('/api/v1', '')}'
        '/api/v1$_returnPath'
        '?status=$paymentStatus&cartid=$orderNumber&total=$total',
      );
      context.read<CheckoutCubit>().handlePaymentReturn(returnUri);
    }
  }

  // Only fires when user explicitly presses X or dismisses the BottomSheet before any payment result arrives.
  void _onUserCancel({bool didPop = false}) {
    if (_handled || _paymentCaptured || _xLocked) return;
    if (_isBnpl) {
      // On web, navigation is unreliable for BNPL. Show the cancelled state inline instead.
      _abandonBnpl();
      return;
    }
    _handled = true;
    _pollTimer?.cancel();
    _messageSub?.cancel();
    if (!mounted) return;
    
    if (!didPop) {
      Navigator.of(context).maybePop();
    }
    
    context.read<CheckoutCubit>().handlePaymentReturn(
      Uri.parse(
        '${Endpoints.baseUrl.replaceAll('/api/v1', '')}'
        '/api/v1$_returnPath'
        '?status=cancelled&cartid=${widget.orderNumber}',
      ),
    );
  }

  String get _returnPath {
    switch (widget.provider) {
      case PaymentProvider.telr:   return '/payments/telr/return';
      case PaymentProvider.tabby:  return '/payments/tabby/return';
      case PaymentProvider.tamara: return '/payments/tamara/return';
      default: return '/payments/return';
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckoutCubit, CheckoutState>(
      listener: (context, state) {
        if (state is PaymentConfirmed) {
          _messageSub?.cancel();
          // Payment is now actually verified — show the confirmation overlay
          // for the brief moment before navigation completes.
          if (mounted && !_paymentCaptured) {
            setState(() => _paymentCaptured = true);
          }
          // Navigate directly from HERE — robust even if CheckoutScreen
          // is no longer active in the widget tree (e.g. web SPA navigation).
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.orderSuccess,
            arguments: PlaceOrderResult(
              orderId:     '',
              orderNumber: state.orderNumber,
              status:      'processing',
              total:       state.total ?? 0,
              isCod:       false,
            ),
            (_) => false,
          );
        } else if (state is PaymentFailed) {
          _messageSub?.cancel();
          _pollTimer?.cancel();
          if (_isBnpl) {
            // BNPL cancellation is shown inline via _bnplCancelled — no navigation.
            if (mounted && !_bnplCancelled) setState(() => _bnplCancelled = true);
          } else {
            Navigator.of(context).maybePop();
          }
        }
      },
      child: PopScope(
        canPop: !(_paymentCaptured || _xLocked),
        onPopInvoked: (didPop) {
          if (didPop) {
            _onUserCancel(didPop: true);
          }
        },
        child: Scaffold(
          appBar: AppBar(
          title:       Text(
            'checkout.payment.webviewTitle'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
          // Once payment is captured, hide the X button entirely.
          // User cannot cancel a payment that has already been deducted.
          leading: (_paymentCaptured || _xLocked)
              ? const SizedBox.shrink()
              : IconButton(
                  icon:      const Icon(Icons.close),
                  tooltip:   'checkout.payment.cancel'.tr(),
                  onPressed: () => _onUserCancel(didPop: false),
                ),
          automaticallyImplyLeading: false,
        ),
        body: Stack(
          children: [
            // ── Payment content ────────────────────────────────────────────
            if (_isBnpl)
              // Tabby / Tamara: browser opened externally, show waiting screen.
              _buildBnplWaitingScreen()
            else if (kIsWeb)
              _buildWebIframe()
            else
              MobilePaymentWebView(
                paymentUrl:  widget.paymentUrl,
                orderNumber: widget.orderNumber,
                returnPath:  _returnPath,
                // Lock the X button the moment Telr redirects to our return URL.
                // At that point the payment is already captured — sending
                // status=cancelled would create a false cancellation record.
                onReturnUrlDetected: () {
                  // Telr captured the payment but our server hasn't verified it
                  // yet. Only lock the X button — do NOT show the confirmation
                  // overlay (that would cover the WebView while the server still
                  // needs to process the return → looks like a blank/stuck page).
                  if (mounted) setState(() => _xLocked = true);
                  _handled = true;
                },
              ),

            // ── Payment captured overlay ───────────────────────────────────
            // Shows immediately when the postMessage / redirect arrives so the
            // user gets visual confirmation without waiting for navigation.
            if (_paymentCaptured)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF22c55e), size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'checkout.payment.confirmed'.tr(),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'checkout.payment.redirecting'.tr(),
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          const CircularProgressIndicator(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  /// Shown while the user completes a BNPL payment in their external browser.
  Widget _buildBnplWaitingScreen() {
    if (_bnplCancelled) return _buildBnplCancelledScreen();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_browser, size: 64, color: Color(0xFF6366f1)),
            const SizedBox(height: 20),
            Text(
              'checkout.payment.browserOpened'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'checkout.payment.browserOpened_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _openExternalBrowser,
              icon:  const Icon(Icons.open_in_new),
              label: Text('checkout.payment.reopen'.tr()),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _abandonBnpl,
              child: Text(
                'checkout.payment.didNotComplete'.tr(),
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shown inline after the user cancels — replaces the waiting screen without any navigation.
  Widget _buildBnplCancelledScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              'checkout.payment.cancelled'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'checkout.payment.didNotComplete'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() { _bnplCancelled = false; _handled = false; });
                  _startBnplPolling();
                  _openExternalBrowser();
                },
                icon:  const Icon(Icons.refresh_rounded),
                label: Text('checkout.payment.retry'.tr()),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon:  const Icon(Icons.arrow_back),
                label: Text('checkout.payment.backToCart'.tr()),
                style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// User says they didn't finish the BNPL payment. Stop polling and show the
  /// cancelled state inline — no navigation needed (works reliably on web too).
  void _abandonBnpl() {
    if (_handled) return;
    _handled = true;
    _pollTimer?.cancel();
    _messageSub?.cancel();
    if (!mounted) return;
    setState(() => _bnplCancelled = true);
    // Notify the cubit so it restores the loaded state (re-enables retry/back-to-cart).
    context.read<CheckoutCubit>().handlePaymentReturn(
      Uri.parse(
        '${Endpoints.baseUrl}$_returnPath'
        '?status=cancelled&order_id=${widget.orderNumber}&cartid=${widget.orderNumber}',
      ),
    );
  }

  /// Embeds the Telr payment form in an inline <iframe>.
  Widget _buildWebIframe() {
    return WebPaymentIframe(
      paymentUrl: widget.paymentUrl,
      viewId:     _iframeViewId,
    );
  }
}