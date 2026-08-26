import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../domain/entities/order_entity.dart';
import '../../../../core/services/app_settings_service.dart';

class InvoicePdfGenerator {
  static const PdfColor _navy = PdfColor.fromInt(0xFF272365);
  static const PdfColor _green = PdfColor.fromInt(0xFF16C79A);
  static const PdfColor _textDark = PdfColor.fromInt(0xFF1F2937);
  static const PdfColor _textMid = PdfColor.fromInt(0xFF374151);
  static const PdfColor _border = PdfColor.fromInt(0xFFE5E7EB);
  static const PdfColor _headerBg = PdfColor.fromInt(0xFFF9FAFB);

  static Future<void> generateAndSave(OrderEntity order, bool isArabic) async {
    final pdf = pw.Document();

    // Load fonts
    final regularData = await rootBundle.load('assets/font/Tajawal-Regular.ttf');
    final boldData = await rootBundle.load('assets/font/Tajawal-Bold.ttf');
    final regularFont = pw.Font.ttf(regularData);
    final boldFont = pw.Font.ttf(boldData);

    final s = AppSettingsService.instance;
    final double rate = order.vatRate > 0 ? order.vatRate : (s.vatRate > 0 ? s.vatRate : 15.0);
    final bool showVat = order.vatAmount > 0 || (s.vatVisible && rate > 0);
    final double div = showVat && rate > 0 ? (1 + rate / 100) : 1.0;

    final double discountGross = order.couponDiscount + order.pointsDiscount;
    final double subtotalNet = order.subtotal / div;
    final double discountNet = discountGross / div;
    final double shippingNet = order.shippingCost / div;
    final double grandTotal = order.grossTotal;
    final double vatAmount = order.vatAmount > 0 ? order.vatAmount : (showVat ? grandTotal - (grandTotal / div) : 0.0);

    String date(DateTime d) => '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    String m(double v) => v.toStringAsFixed(2);
    
    final rateLabel = rate.toStringAsFixed(rate % 1 == 0 ? 0 : 2);

    pw.Widget metaLine(String k, String v) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(k, style: pw.TextStyle(font: regularFont, fontSize: 10, color: _textMid)),
          pw.Text(v, style: pw.TextStyle(font: regularFont, fontSize: 10, color: _textMid)),
        ],
      ),
    );

    pw.Widget party(String title, List<String> lines, {String? fallback}) {
      final shown = lines.isNotEmpty ? lines : (fallback != null ? [fallback] : <String>[]);
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 11, color: _navy)),
          pw.Container(height: 1.5, width: 28, margin: const pw.EdgeInsets.only(top: 3, bottom: 8), color: _green),
          ...shown.map((l) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(l, style: pw.TextStyle(font: regularFont, fontSize: 10, color: _textMid)),
              )),
        ],
      );
    }

    pw.Widget kv(String k, String v, {bool money = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(k, style: pw.TextStyle(font: boldFont, fontSize: 10, color: _textMid)),
          ),
          pw.Text(money ? '$v SAR' : v, style: pw.TextStyle(font: regularFont, fontSize: 10, color: _textDark)),
        ],
      ),
    );

    pw.Widget th(String t, {bool center = false, bool end = false}) => pw.Text(
      t,
      textAlign: center ? pw.TextAlign.center : (end ? pw.TextAlign.right : pw.TextAlign.left),
      style: pw.TextStyle(font: boldFont, fontSize: 9, color: _textMid),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        build: (context) => [
          // Title
          pw.Center(
            child: pw.Text('invoice.title'.tr(), style: pw.TextStyle(font: boldFont, fontSize: 20, color: _navy)),
          ),
          pw.SizedBox(height: 14),
          pw.Divider(color: _border, thickness: 1),
          pw.SizedBox(height: 16),

          // Meta
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    metaLine('invoice.order_date'.tr(), date(order.createdAt)),
                    metaLine('invoice.invoice_date'.tr(), date(order.createdAt)),
                  ],
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${'invoice.tax_invoice_no'.tr()} ${order.orderNumber}',
                        style: pw.TextStyle(font: boldFont, fontSize: 12, color: _textDark)),
                    pw.SizedBox(height: 6),
                    metaLine('invoice.invoice_code'.tr(), order.id.padLeft(7, '0')),
                    if (s.vatNumber.isNotEmpty)
                      metaLine('invoice.tax_number'.tr(), s.vatNumber),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: _border, thickness: 1),
          pw.SizedBox(height: 16),

          // Parties
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: party('invoice.issued_to'.tr(), [
                  if (order.shippingAddress.trim().isNotEmpty) order.shippingAddress.trim(),
                  if (order.phone.trim().isNotEmpty) order.phone.trim(),
                ]),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: party('invoice.issued_from'.tr(), [
                  if (s.sellerName.isNotEmpty) s.sellerName,
                  if (s.sellerCity.isNotEmpty) s.sellerCity,
                  if (s.sellerAddress.isNotEmpty) s.sellerAddress,
                  if (s.sellerEmail.isNotEmpty) s.sellerEmail,
                  if (s.sellerPhone.isNotEmpty) s.sellerPhone,
                ], fallback: 'Fastway'),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: _border, thickness: 1),
          pw.SizedBox(height: 16),

          // Details
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('invoice.shipping_details'.tr(), style: pw.TextStyle(font: boldFont, fontSize: 11, color: _navy)),
                    pw.Container(height: 1.5, width: 28, margin: const pw.EdgeInsets.only(top: 3, bottom: 8), color: _green),
                    if ((order.shipmentProvider ?? '').trim().isNotEmpty)
                      kv('invoice.provider'.tr(), order.shipmentProvider!),
                  ],
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('invoice.payment_details'.tr(), style: pw.TextStyle(font: boldFont, fontSize: 11, color: _navy)),
                    pw.Container(height: 1.5, width: 28, margin: const pw.EdgeInsets.only(top: 3, bottom: 8), color: _green),
                    kv('invoice.amount'.tr(), m(grandTotal), money: true),
                    kv('invoice.payment_method'.tr(), order.paymentMethod),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Items Table Header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: const pw.BoxDecoration(
              color: _headerBg,
              border: pw.Border(top: pw.BorderSide(color: _border), bottom: pw.BorderSide(color: _border)),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(flex: 4, child: th('invoice.product'.tr())),
                pw.Expanded(flex: 1, child: th('invoice.qty'.tr(), center: true)),
                pw.Expanded(flex: 3, child: th('invoice.unit_price'.tr(), center: true)),
                pw.Expanded(flex: 3, child: th('invoice.line_total'.tr(), end: true)),
              ],
            ),
          ),
          pw.SizedBox(height: 2),

          // Items Table Body
          ...order.items.map((item) {
            final name = (isArabic && item.nameAr?.trim().isNotEmpty == true) ? item.nameAr! : item.name;
            final double lineGross = item.price * item.quantity;
            final double lineNet = lineGross / div;
            final double unitNet = item.price / div;

            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(flex: 4, child: pw.Text(name, style: pw.TextStyle(font: boldFont, fontSize: 9, color: _textDark))),
                  pw.Expanded(flex: 1, child: pw.Text('${item.quantity}', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: regularFont, fontSize: 9, color: _textMid))),
                  pw.Expanded(flex: 3, child: pw.Text('${m(unitNet)} SAR', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: boldFont, fontSize: 9))),
                  pw.Expanded(flex: 3, child: pw.Text('${m(lineNet)} SAR', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: boldFont, fontSize: 9))),
                ],
              ),
            );
          }),
          pw.SizedBox(height: 16),

          // Totals
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('orders.summary.subtotal'.tr(), style: pw.TextStyle(font: boldFont, fontSize: 10, color: _textDark)),
                pw.Text('${m(subtotalNet)} SAR', style: pw.TextStyle(font: regularFont, fontSize: 10, color: _textDark)),
              ],
            ),
          ),
          if (discountGross > 0)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('invoice.discount'.tr(), style: pw.TextStyle(font: boldFont, fontSize: 10, color: _textDark)),
                  pw.Text('-${m(discountNet)} SAR', style: pw.TextStyle(font: regularFont, fontSize: 10, color: _textDark)),
                ],
              ),
            ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('orders.summary.shipping'.tr(), style: pw.TextStyle(font: boldFont, fontSize: 10, color: _textDark)),
                order.shippingCost == 0
                    ? pw.Text('orders.summary.free_shipping'.tr(), style: pw.TextStyle(font: boldFont, fontSize: 10, color: _green))
                    : pw.Text('${m(shippingNet)} SAR', style: pw.TextStyle(font: regularFont, fontSize: 10, color: _textDark)),
              ],
            ),
          ),
          if (showVat && vatAmount > 0)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('checkout.vat'.tr(namedArgs: {'rate': rateLabel}), style: pw.TextStyle(font: boldFont, fontSize: 10, color: _textDark)),
                  pw.Text('${m(vatAmount)} SAR', style: pw.TextStyle(font: regularFont, fontSize: 10, color: _textDark)),
                ],
              ),
            ),
          pw.SizedBox(height: 8),

          // Grand Total
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: pw.BoxDecoration(
              color: _headerBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('invoice.grand_total'.tr(), style: pw.TextStyle(font: boldFont, fontSize: 12, color: _textDark)),
                pw.Text('${m(grandTotal)} SAR', style: pw.TextStyle(font: boldFont, fontSize: 13, color: _navy)),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Footer
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text('invoice.contact'.tr(), style: pw.TextStyle(font: regularFont, fontSize: 9, color: _textMid)),
                pw.SizedBox(height: 6),
                pw.Text(
                  [
                    if (s.sellerName.isNotEmpty) s.sellerName,
                    if (s.sellerPhone.isNotEmpty) s.sellerPhone,
                    if (s.sellerEmail.isNotEmpty) s.sellerEmail,
                  ].join('\n'),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: regularFont, fontSize: 9, color: _textMid, lineSpacing: 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Save and prompt download/share
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'invoice_${order.orderNumber}.pdf',
    );
  }
}
