// lib/features/orders/presentation/screens/invoice_webview_screen.dart
//
// Renders the order invoice PDF inside an in-app viewer.
//
// The invoice PDF route (GET $orders/{id}/invoice-pdf) is protected by
// `auth:sanctum`, so we:
//   1. Fetch the raw PDF bytes via the authed Dio instance (Authorization
//      header is added automatically by DioApiService's interceptor).
//   2. Render the bytes with SfPdfViewer.memory (zoom + scroll built in),
//      so no network call leaves the viewer and there are no auth issues.
//
// The admin panel pulls this same PDF from Daftra (invoice_pdf_url) and stores
// it; this endpoint serves the stored copy (with a lazy fetch fallback).
//
// NOTE: class/file name kept as InvoiceWebViewScreen for call-site stability
// (order_details_screen.dart imports it); it is now a PDF viewer, not a WebView.

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/api/model/endpoints.dart';
import 'package:fastway/core/di/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class InvoiceWebViewScreen extends StatefulWidget {
  final String orderId;

  const InvoiceWebViewScreen({super.key, required this.orderId});

  @override
  State<InvoiceWebViewScreen> createState() => _InvoiceWebViewScreenState();
}

class _InvoiceWebViewScreenState extends State<InvoiceWebViewScreen> {
  Uint8List? _pdfBytes;

  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPdf();
  }

  // ── Fetch invoice PDF bytes via authed Dio ─────────────────────────────────

  Future<void> _fetchPdf() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final url =
          '${Endpoints.baseUrl}${Endpoints.orders}/${widget.orderId}/invoice-pdf';
      final response = await sl<Dio>().get<List<int>>(
        url,
        options: Options(
          headers: {'Accept': 'application/pdf'},
          responseType: ResponseType.bytes,
        ),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'orders.invoice_load_failed'.tr();
        });
        return;
      }

      setState(() => _pdfBytes = Uint8List.fromList(bytes));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      setState(() {
        _hasError = true;
        if (code == 403) {
          _errorMessage = 'orders.invoice_not_authorized'.tr();
        } else if (code == 404) {
          // PDF not yet generated/available (e.g. invoice not issued).
          _errorMessage = 'orders.invoice_pdf_unavailable'.tr();
        } else {
          _errorMessage = 'orders.invoice_load_failed'.tr();
        }
      });
    } catch (_) {
      setState(() {
        _hasError = true;
        _errorMessage = 'orders.invoice_load_failed'.tr();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Download / Share PDF ───────────────────────────────────────────────────

  Future<void> _downloadPdf() async {
    if (_pdfBytes == null) return;
    try {
      final xFile = XFile.fromData(
        _pdfBytes!,
        name: 'invoice_${widget.orderId}.pdf',
        mimeType: 'application/pdf',
      );
      await Share.shareXFiles([xFile]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('orders.view_invoice'.tr()),
        centerTitle: true,
        actions: [
          if (!_isLoading && _pdfBytes != null)
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'orders.download_invoice'.tr(),
              onPressed: _downloadPdf,
            ),
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'orders.reload_invoice'.tr(),
              onPressed: _fetchPdf,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError || _pdfBytes == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'orders.invoice_load_failed'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchPdf,
                icon: const Icon(Icons.refresh),
                label: Text('checkout.payment.retry'.tr()),
              ),
            ],
          ),
        ),
      );
    }
    return SfPdfViewer.memory(_pdfBytes!);
  }
}
