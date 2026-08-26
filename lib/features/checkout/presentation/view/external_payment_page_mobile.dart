// lib/features/checkout/presentation/view/external_payment_page_mobile.dart
//
// Mobile WebView implementation for the payment page.
// This file is only compiled on Android/iOS (not web).
// The ExternalPaymentPage conditionally imports it.
//
// Telr   → in-app WebView (supports framed embedding)
// Tabby / Tamara → external browser (their checkout pages block WebView
//   embedding via X-Frame-Options / CSP). Flutter shows a waiting screen and
//   polls /payments/status until the server confirms the result.
//
// T7.5: Payment polling — polls GET /payments/status/{orderNumber}
//       every [_kPollIntervalSec] seconds for up to [_kMaxPollSeconds] seconds.
//
// T7.6: WebView timeout — if the page hasn't loaded within [_kLoadTimeoutSec]
//       seconds, we show a reload button so the user isn't stuck.

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/api/model/endpoints.dart';
import 'package:fastway/core/di/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../cubit/checkout_cubit.dart';
import '../../../../core/widgets/skeletons.dart';

/// Interval between polling attempts (seconds).
const int _kPollIntervalSec   = 5;
/// Total polling duration before giving up (seconds).
const int _kMaxPollSeconds    = 300; // 5 minutes
/// Show load-timeout UI after this many seconds of blank loading.
const int _kLoadTimeoutSec    = 30;

class MobilePaymentWebView extends StatefulWidget {
  final String paymentUrl;
  final String orderNumber;
  final String returnPath;

  /// Called as soon as the WebView detects the payment return URL for a
  /// deferred-checkout intent (CI- prefix). At this point Telr has already
  /// captured the payment, so the parent should disable the cancel button.
  final VoidCallback? onReturnUrlDetected;

  const MobilePaymentWebView({
    super.key,
    required this.paymentUrl,
    required this.orderNumber,
    required this.returnPath,
    this.onReturnUrlDetected,
  });

  /// Tabby and Tamara block in-app WebView embedding — must use external browser.
  bool get isBnpl =>
      returnPath.contains('tabby') || returnPath.contains('tamara');

  @override
  State<MobilePaymentWebView> createState() => _MobilePaymentWebViewState();
}

class _MobilePaymentWebViewState extends State<MobilePaymentWebView> {
  WebViewController? _controller; // null when using external browser (BNPL)

  bool _isLoading   = true;
  bool _hasError    = false;
  bool _intercepted = false;
  bool _timedOut    = false; // T7.6: load timeout

  // T7.5: Polling
  Timer? _pollTimer;
  Timer? _loadTimeoutTimer;
  int    _pollSeconds = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isBnpl) {
      // Open checkout in external browser — Tabby/Tamara block WebView embedding.
      // Polling (_startPolling) detects the result; WebView is not used.
      _isLoading = false;
      _launchExternalBrowser();
      _startPolling(); // T7.5
    } else {
      _buildController();
      _startLoadTimeout(); // T7.6
      _startPolling();     // T7.5
    }
  }

  Future<void> _launchExternalBrowser() async {
    final uri = Uri.tryParse(widget.paymentUrl);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _loadTimeoutTimer?.cancel();
    super.dispose();
  }

  // ── T7.6: Load timeout ────────────────────────────────────────────────────

  void _startLoadTimeout() {
    _loadTimeoutTimer = Timer(const Duration(seconds: _kLoadTimeoutSec), () {
      if (!mounted || !_isLoading || _intercepted) return;
      setState(() { _timedOut = true; _isLoading = false; });
    });
  }

  // ── T7.5: Polling ─────────────────────────────────────────────────────────

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: _kPollIntervalSec), (_) async {
      if (!mounted || _intercepted) {
        _pollTimer?.cancel();
        return;
      }
      _pollSeconds += _kPollIntervalSec;
      if (_pollSeconds >= _kMaxPollSeconds) {
        _pollTimer?.cancel();
        if (mounted && _isLoading) {
          setState(() { _timedOut = true; _isLoading = false; });
        }
        return;
      }

      // CI- prefix = deferred checkout intent; no order exists yet to poll.
      // The server will create the order on the return URL and redirect to fastway://.
      if (widget.orderNumber.startsWith('CI-') || widget.orderNumber.isEmpty) return;

      try {
        final url = '${Endpoints.baseUrl}${Endpoints.paymentStatus}/${widget.orderNumber}';
        final response = await sl<Dio>().get(
          url,
          options: Options(headers: {'Accept': 'application/json'}),
        );
        final data = (response.data?['data'] as Map<String, dynamic>?) ?? {};
        final paymentStatus = (data['payment_status'] ?? '').toString();

        // pending / pending_payment = still waiting for customer action — keep polling
        if (paymentStatus == 'pending' || paymentStatus == 'pending_payment') return;

        if (paymentStatus == 'authorised' || paymentStatus == 'declined' ||
            paymentStatus == 'cancelled'  || paymentStatus == 'failed') {
          _intercepted = true;
          _pollTimer?.cancel();
          _loadTimeoutTimer?.cancel();

          // Include both order_id (Tabby/Tamara) and cartid (Telr) so the
          // backend return handler can find the order regardless of gateway.
          final returnUri = Uri.parse(
            '${Endpoints.baseUrl}${widget.returnPath}'
            '?status=$paymentStatus&order_id=${widget.orderNumber}&cartid=${widget.orderNumber}',
          );
          if (mounted) {
            context.read<CheckoutCubit>().handlePaymentReturn(returnUri);
          }
        }
      } catch (_) {
        // Network error during poll — silently ignore, keep retrying
      }
    });
  }

  // ── WebView ───────────────────────────────────────────────────────────────

  /// Dispatches a confirmed payment result into the cubit. Shared by the
  /// JavaScript channel (primary, reliable) and the fastway:// URL interception
  /// (fallback). Idempotent via [_intercepted].
  void _dispatchDeepLinkResult(Uri uri) {
    if (_intercepted) return;
    _intercepted = true;
    _pollTimer?.cancel();
    _loadTimeoutTimer?.cancel();
    if (mounted) {
      context.read<CheckoutCubit>().handleDeepLinkPaymentResult(uri);
    }
  }

  void _buildController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Primary, scheme-independent callback channel. The server result page
      // calls window.FastwayPayment.postMessage(JSON) — this fires reliably even
      // when custom-scheme navigation (fastway://) is swallowed by the WebView.
      ..addJavaScriptChannel(
        'FastwayPayment',
        onMessageReceived: (message) {
          if (_intercepted) return;
          // Payload is a JSON string: {success, order_number, payment_status}.
          String success = 'false', orderNumber = '', status = '', total = '';
          try {
            final decoded = jsonDecode(message.message) as Map<String, dynamic>;
            success     = (decoded['success'] == true) ? 'true' : 'false';
            orderNumber = (decoded['order_number'] ?? '').toString();
            status      = (decoded['payment_status'] ?? decoded['status'] ?? '').toString();
            total       = (decoded['total'] ?? '').toString();
          } catch (_) {
            return; // malformed payload — ignore, fall back to URL interception
          }
          final uri = Uri(
            scheme: 'fastway',
            host:   'payment-result',
            queryParameters: {
              'success':      success,
              'order_number': orderNumber,
              'status':       status,
              'total':        total,
            },
          );
          _dispatchDeepLinkResult(uri);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            _loadTimeoutTimer?.cancel();
            if (mounted) setState(() { _isLoading = true; _timedOut = false; });
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() { _isLoading = false; _hasError = true; });
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null || _intercepted) return NavigationDecision.navigate;

            // ── Deep link from server result HTML ──────────────────────────────
            // After the server processes the intent and creates the order, the HTML
            // redirects to fastway://payment-result?success=...&order_number=ORD-xxx
            // This is how we get the REAL order number back into Flutter.
            if (uri.scheme == 'fastway' && uri.host == 'payment-result') {
              _dispatchDeepLinkResult(uri);
              return NavigationDecision.prevent;
            }

            // ── Return URL from payment gateway ───────────────────────────────
            if (uri.path.contains(widget.returnPath)) {
              final cartId = uri.queryParameters['cartid'] ?? '';

              // Tabby / Tamara return URLs must be loaded by the server so it can
              // verify + capture the payment and then return the HTML deep-link page.
              // The HTML fires FastwayPayment.postMessage() / fastway:// deep link
              // which we handle above. Never intercept these locally.
              if (widget.returnPath.contains('tabby') || widget.returnPath.contains('tamara')) {
                widget.onReturnUrlDetected?.call();
                return NavigationDecision.navigate;
              }

              // CI-xxx: Telr deferred checkout intent — server must process this to
              // create the order. Let the WebView navigate; server HTML redirects back.
              if (cartId.startsWith('CI-')) {
                widget.onReturnUrlDetected?.call();
                return NavigationDecision.navigate;
              }

              // ORD-xxx Telr legacy flow — order already exists, handle locally.
              _intercepted = true;
              _pollTimer?.cancel();
              _loadTimeoutTimer?.cancel();
              if (mounted) {
                context.read<CheckoutCubit>().handlePaymentReturn(uri);
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _reload() {
    if (widget.isBnpl) {
      // Re-open the browser tab for BNPL — no WebView to reload.
      _launchExternalBrowser();
      return;
    }
    setState(() {
      _hasError    = false;
      _timedOut    = false;
      _isLoading   = true;
      _intercepted = false;
      _pollSeconds = 0;
    });
    _startLoadTimeout();
    _controller?.reload();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // ── BNPL (Tabby / Tamara): browser is external, show waiting screen ───
    if (widget.isBnpl) {
      return _buildBnplWaitingScreen();
    }

    // ── Telr: in-app WebView ──────────────────────────────────────────────
    return Stack(
      children: [
        // ── WebView (always mounted so polling can intercept) ──────────────
        if (!_hasError && !_timedOut && _controller != null)
          WebViewWidget(controller: _controller!),

        // ── Network / resource error ──────────────────────────────────────
        if (_hasError)
          _buildInfoPanel(
            icon: Icons.wifi_off,
            title: 'checkout.payment.loadError'.tr(),
            subtitle: 'checkout.payment.error_subtitle'.tr(),
            onAction: _reload,
            actionLabel: 'checkout.payment.retry'.tr(),
          ),

        // ── T7.6: Load timeout ────────────────────────────────────────────
        if (_timedOut && !_hasError)
          _buildInfoPanel(
            icon: Icons.hourglass_bottom_rounded,
            title: 'checkout.payment.timeout'.tr(),
            subtitle: 'checkout.payment.timeout_subtitle'.tr(),
            onAction: _reload,
            actionLabel: 'checkout.payment.reload'.tr(),
          ),

        // ── Spinner ───────────────────────────────────────────────────────
        if (_isLoading && !_hasError && !_timedOut)
          const GenericPageSkeleton(),
      ],
    );
  }

  /// Shown for BNPL gateways while the user completes payment in their browser.
  Widget _buildBnplWaitingScreen() {
    if (_hasError) {
      return _buildInfoPanel(
        icon: Icons.open_in_browser,
        title: 'checkout.payment.browserOpenFailed'.tr(),
        subtitle: 'checkout.payment.browserOpenFailed_subtitle'.tr(),
        onAction: _reload,
        actionLabel: 'checkout.payment.retry'.tr(),
      );
    }
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
              onPressed: _launchExternalBrowser,
              icon:  const Icon(Icons.open_in_new),
              label: Text('checkout.payment.reopen'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPanel({
    required IconData icon,
    required String   title,
    required String   subtitle,
    required VoidCallback onAction,
    required String   actionLabel,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon:  const Icon(Icons.refresh),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
