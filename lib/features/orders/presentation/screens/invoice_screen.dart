// lib/features/orders/presentation/screens/invoice_screen.dart
//
// Native ZATCA-style tax invoice, rendered from the OrderEntity already loaded
// by the order-details screen plus the store's seller block (AppSettingsService).
// No PDF, no HTML, no backend round-trip — the customer can screenshot / share.
//
// VAT uses the figures FROZEN on the order at checkout (order.vatAmount / vatRate)
// — never a live recomputation. Shipping and discount are shown EX-VAT so the
// rows foot exactly to the grand total. See fastway-vat-single-source-of-truth.

import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/services/app_settings_service.dart';
import 'package:fastway/core/widgets/sar_symbol.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/order_entity.dart';
import '../utils/invoice_pdf_generator.dart';
import 'invoice_webview_screen.dart';

class InvoiceScreen extends StatelessWidget {
  final OrderEntity order;

  const InvoiceScreen({super.key, required this.order});

  // ── ZATCA palette (matches the previous HTML invoice) ──────────────────────
  static const _navy = Color(0xFF272365);
  static const _green = Color(0xFF16C79A);
  static const _textDark = Color(0xFF1F2937);
  static const _textMid = Color(0xFF374151);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _headerBg = Color(0xFFF9FAFB);

  String _date(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  String _m(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final s = AppSettingsService.instance;
    final bool isArabic = context.locale.languageCode == 'ar';

    // ── VAT / money (frozen figures; shipping + discount shown ex-VAT) ─────────
    final double rate = order.vatRate > 0
        ? order.vatRate
        : (s.vatRate > 0 ? s.vatRate : 15.0);
    final bool showVat = order.vatAmount > 0 || (s.vatVisible && rate > 0);
    final double div = showVat && rate > 0 ? (1 + rate / 100) : 1.0;

    final double discountGross =
        order.couponDiscount + order.pointsDiscount + order.tierDiscount;
    final double subtotalNet = order.subtotal / div; // goods, pre-discount, ex-VAT
    final double discountNet = discountGross / div;
    final double shippingNet = order.shippingCost / div;
    final double grandTotal = order.grossTotal;
    final double vatAmount = order.vatAmount > 0
        ? order.vatAmount
        : (showVat ? grandTotal - (grandTotal / div) : 0.0);

    final String rateLabel = rate.toStringAsFixed(rate % 1 == 0 ? 0 : 2);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('orders.view_invoice'.tr(), style: const TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _textDark,
        iconTheme: const IconThemeData(color: _textDark),
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: _navy),
            tooltip: 'orders.download_invoice'.tr(),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('جاري تجهيز الفاتورة...')),
              );
              try {
                await InvoicePdfGenerator.generateAndSave(order, isArabic);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error generating PDF: $e')),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // ── Title ──────────────────────────────────────────────────────
            Center(
              child: Text(
                'invoice.title'.tr(),
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w700, color: _navy),
              ),
            ),
            const SizedBox(height: 14),
            const Divider(color: _border, height: 1),
            const SizedBox(height: 16),

            // ── Meta: dates | tax-invoice no + codes ───────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _metaLine('invoice.order_date'.tr(), _date(order.createdAt)),
                      _metaLine(
                          'invoice.invoice_date'.tr(), _date(order.createdAt)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${'invoice.tax_invoice_no'.tr()} ${order.orderNumber}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _textDark),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(height: 6),
                      _metaLine('invoice.invoice_code'.tr(),
                          order.id.padLeft(7, '0'),
                          end: true),
                      if (s.vatNumber.isNotEmpty)
                        _metaLine('invoice.tax_number'.tr(), s.vatNumber,
                            end: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: _border, height: 1),
            const SizedBox(height: 16),

            // ── Parties: issued to | issued from ───────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _party(
                    'invoice.issued_to'.tr(),
                    [
                      if (order.shippingAddress.trim().isNotEmpty)
                        order.shippingAddress.trim(),
                      if (order.phone.trim().isNotEmpty) order.phone.trim(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _party(
                    'invoice.issued_from'.tr(),
                    [
                      if (s.sellerName.isNotEmpty) s.sellerName,
                      if (s.sellerCity.isNotEmpty) s.sellerCity,
                      if (s.sellerAddress.isNotEmpty) s.sellerAddress,
                      if (s.sellerEmail.isNotEmpty) s.sellerEmail,
                      if (s.sellerPhone.isNotEmpty) s.sellerPhone,
                    ],
                    fallback: 'Fastway',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: _border, height: 1),
            const SizedBox(height: 16),

            // ── Details: shipping | payment ────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _detailCol('invoice.shipping_details'.tr(), [
                    if ((order.shipmentProvider ?? '').trim().isNotEmpty)
                      _kv('invoice.provider'.tr(), order.shipmentProvider!),
                    // tracking number isn't always on the entity; guard generically
                  ]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _detailCol('invoice.payment_details'.tr(), [
                    _kv('invoice.amount'.tr(), _m(grandTotal), money: true),
                    _kv('invoice.payment_method'.tr(), order.paymentMethod),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Items ──────────────────────────────────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth > 500 ? constraints.maxWidth : 500,
                    ),
                    child: IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _itemsHeader(),
                          const SizedBox(height: 2),
                          ...order.items.map((i) => _itemRow(i, isArabic, div, rateLabel)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // ── Totals ─────────────────────────────────────────────────────
            _totalRow('orders.summary.subtotal'.tr(),
                SarText(price: _m(subtotalNet))),
            if (discountGross > 0)
              _totalRow('invoice.discount'.tr(),
                  SarText(price: '−${_m(discountNet)}')),
            _totalRow(
              'orders.summary.shipping'.tr(),
              order.shippingCost == 0
                  ? Text('orders.summary.free_shipping'.tr(),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _green))
                  : SarText(price: _m(shippingNet)),
            ),
            if (showVat && vatAmount > 0)
              _totalRow(
                'checkout.vat'.tr(namedArgs: {'rate': rateLabel}),
                SarText(price: _m(vatAmount)),
              ),
            const SizedBox(height: 8),
            _grandTotalRow('invoice.grand_total'.tr(), grandTotal),
            const SizedBox(height: 24),

            // ── Contact footer ─────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Text('invoice.contact'.tr(),
                      style: const TextStyle(fontSize: 12, color: _muted)),
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (s.sellerName.isNotEmpty) s.sellerName,
                      if (s.sellerPhone.isNotEmpty) s.sellerPhone,
                      if (s.sellerEmail.isNotEmpty) s.sellerEmail,
                    ].join('\n'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12, color: _textMid, height: 1.7),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  Widget _metaLine(String k, String v, {bool end = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          '$k : $v',
          textAlign: end ? TextAlign.end : TextAlign.start,
          style: const TextStyle(fontSize: 12, color: _textMid),
        ),
      );

  Widget _party(String title, List<String> lines, {String? fallback}) {
    final shown = lines.isNotEmpty ? lines : (fallback != null ? [fallback] : <String>[]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: _navy)),
        Container(height: 2, width: 28, margin: const EdgeInsets.only(top: 3, bottom: 8), color: _green),
        ...shown.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(l,
                  style: const TextStyle(
                      fontSize: 12.5, color: _textMid, height: 1.5)),
            )),
      ],
    );
  }

  Widget _detailCol(String title, List<Widget> rows) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _navy)),
          Container(height: 2, width: 28, margin: const EdgeInsets.only(top: 3, bottom: 8), color: _green),
          ...rows,
        ],
      );

  Widget _kv(String k, String v, {bool money = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(k,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _textMid)),
            ),
            money
                ? SarText(price: v)
                : Flexible(
                    child: Text(v,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                            fontSize: 12.5, color: _textDark)),
                  ),
          ],
        ),
      );

  Widget _itemsHeader() => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: const BoxDecoration(
          color: _headerBg,
          border: Border(
              top: BorderSide(color: _border),
              bottom: BorderSide(color: _border)),
        ),
        child: Row(
          children: [
            Expanded(flex: 4, child: _th('invoice.product'.tr())),
            Expanded(flex: 1, child: _th('invoice.qty'.tr(), center: true)),
            Expanded(flex: 3, child: _th('invoice.unit_price'.tr(), center: true)),
            Expanded(flex: 3, child: _th('invoice.line_total'.tr(), end: true)),
          ],
        ),
      );

  Widget _th(String t, {bool center = false, bool end = false}) => Text(
        t,
        textAlign:
            center ? TextAlign.center : (end ? TextAlign.end : TextAlign.start),
        style: const TextStyle(
            fontSize: 11.5, fontWeight: FontWeight.w700, color: _textMid),
      );

  Widget _itemRow(
      OrderItemEntity item, bool isArabic, double div, String rateLabel) {
    final name = (isArabic && item.nameAr?.trim().isNotEmpty == true)
        ? item.nameAr!
        : item.name;
    final double lineGross = item.price * item.quantity;
    final double lineNet = lineGross / div;
    final double lineVat = lineGross - lineNet;
    final double unitNet = item.price / div;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(name,
                style: const TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: _textDark)),
          ),
          Expanded(
            flex: 1,
            child: Text('${item.quantity}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.0, color: _textMid)),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.topCenter,
              child: SarText(price: _fmt(unitNet), style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: SarText(price: _fmt(lineNet), style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(2);

  Widget _totalRow(String label, Widget value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
            value,
          ],
        ),
      );

  Widget _grandTotalRow(String label, double total) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: _headerBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: _textDark)),
            SarText(
              price: total.toStringAsFixed(2),
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _navy),
            ),
          ],
        ),
      );
}
