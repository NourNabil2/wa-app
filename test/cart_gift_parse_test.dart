// A granted cart line must survive the trip through the production model.
//
// The server prices a gift at 0 and flags it; the app only has to carry that
// through faithfully. Parsing it wrong would either charge the customer for a
// freebie or show a paid line as free — both worse than not having the offer.
import 'package:flutter_test/flutter_test.dart';
import 'package:fastway/features/cart/data/models/cart_model.dart';

void main() {
  Map<String, dynamic> line({
    bool? isGift,
    double price = 40.0,
    String? label,
    String? labelAr,
  }) => {
        'id': '11',
        'product_id': '99',
        'name': 'Protein Bar',
        'price': price,
        'original_price': 40.0,
        'quantity': 2,
        if (isGift != null) 'is_gift': isGift,
        if (label != null) 'gift_label': label,
        if (labelAr != null) 'gift_label_ar': labelAr,
      };

  test('a granted line parses as a gift priced at zero', () {
    final item = CartItemModel.fromJson(
      line(isGift: true, price: 0.0, label: 'Buy 1 Get 1', labelAr: 'اشترِ 1 واحصل على 1'),
    );

    expect(item.isGift, isTrue);
    expect(item.price, 0.0);
    expect(item.totalPrice, 0.0, reason: 'a gift adds nothing to the cart total');
    expect(item.originalPrice, 40.0, reason: 'retail value survives, to strike through');
  });

  test('an ordinary line is not a gift', () {
    final item = CartItemModel.fromJson(line());

    expect(item.isGift, isFalse);
    expect(item.totalPrice, 80.0);
  });

  test('the gift label is localised, falling back to English', () {
    final both = CartItemModel.fromJson(
      line(isGift: true, label: 'Buy 1 Get 1', labelAr: 'اشترِ 1 واحصل على 1'),
    );
    expect(both.localizedGiftLabel('ar'), 'اشترِ 1 واحصل على 1');
    expect(both.localizedGiftLabel('en'), 'Buy 1 Get 1');

    final englishOnly = CartItemModel.fromJson(line(isGift: true, label: 'Buy 1 Get 1'));
    expect(englishOnly.localizedGiftLabel('ar'), 'Buy 1 Get 1',
        reason: 'an untranslated campaign name is better than a blank badge');
  });

  /// A backend that predates the feature must not turn every line into a gift.
  test('a payload without the flag degrades to a normal line', () {
    final item = CartItemModel.fromJson(line());

    expect(item.isGift, isFalse);
    expect(item.giftLabel, isNull);
  });

  test('copyWith preserves the gift flags', () {
    final item = CartItemModel.fromJson(line(isGift: true, price: 0.0, label: 'Gift'))
        .copyWith(quantity: 3);

    expect(item.isGift, isTrue);
    expect(item.giftLabel, 'Gift');
    expect(item.quantity, 3);
  });
}
