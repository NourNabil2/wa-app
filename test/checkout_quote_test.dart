import 'package:flutter_test/flutter_test.dart';
import 'package:fastway/features/checkout/presentation/cubit/checkout_state.dart';

/// The delivery fee is VAT-INCLUSIVE, like every price in this app: a 25 SAR
/// delivery is 21.74 + 3.26 VAT, not 25 + VAT.
///
/// The app used to recompute VAT locally from the goods alone, which silently
/// understated it once the fee became taxable. These figures now come from the
/// server (/checkout/quote) and must be used verbatim — the only arithmetic left
/// on the client is stripping the VAT back out of the fee so the summary rows
/// still add up to the total.
void main() {
  group('CheckoutQuote', () {
    Map<String, dynamic> json({
      double subtotal = 200,
      double shipping = 25,
      double grossTotal = 225,
      double total = 225,
      double vatAmount = 29.35,
      double vatRate = 15,
      bool vatEnabled = true,
    }) =>
        {
          'subtotal': subtotal,
          'coupon_discount': 0,
          'points_discount': 0,
          'shipping_cost': shipping,
          'gross_total': grossTotal,
          'total': total,
          'vat': {
            'amount': vatAmount,
            'rate': vatRate,
            'enabled': vatEnabled,
            'inclusive': true,
          },
        };

    test('parses the server payload, VAT block included', () {
      final q = CheckoutQuote.fromJson(json());

      expect(q.subtotal, 200);
      expect(q.shippingCost, 25);
      expect(q.grossTotal, 225);
      expect(q.total, 225);
      // 225 × 15/115 — goods AND delivery. The old local maths gave 26.09.
      expect(q.vatAmount, 29.35);
      expect(q.vatRate, 15);
      expect(q.vatEnabled, isTrue);
    });

    test('strips the VAT back out of the delivery fee', () {
      final q = CheckoutQuote.fromJson(json());

      // 25 / 1.15 = 21.739…
      expect(q.shippingExclVat, closeTo(21.74, 0.01));
    });

    test('the summary rows add up to the total', () {
      final q = CheckoutQuote.fromJson(json());

      // This is the invariant the card depends on:
      //   subtotal(excl VAT) + shipping(excl VAT) + VAT == total
      final subtotalExclVat = q.subtotal / (1 + q.vatRate / 100);
      final sum = subtotalExclVat + q.shippingExclVat + q.vatAmount;

      expect(sum, closeTo(q.total, 0.02));
    });

    test('free delivery leaves the fee at zero', () {
      final q = CheckoutQuote.fromJson(
        json(shipping: 0, grossTotal: 200, total: 200, vatAmount: 26.09),
      );

      expect(q.shippingCost, 0);
      expect(q.shippingExclVat, 0);
      expect(q.vatAmount, 26.09);
    });

    test('VAT disabled: nothing is stripped out of the fee', () {
      final q = CheckoutQuote.fromJson(
        json(vatAmount: 0, vatRate: 0, vatEnabled: false),
      );

      expect(q.vatAmount, 0);
      // rate 0 must not divide by 1.0 and lose the fee, nor blow up
      expect(q.shippingExclVat, 25);
    });

    test('missing or null fields degrade to zero rather than crashing', () {
      final q = CheckoutQuote.fromJson({'vat': <String, dynamic>{}});

      expect(q.subtotal, 0);
      expect(q.shippingCost, 0);
      expect(q.total, 0);
      expect(q.vatAmount, 0);
      expect(q.vatEnabled, isFalse);
    });
  });
}
