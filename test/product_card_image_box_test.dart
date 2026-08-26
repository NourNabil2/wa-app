// Verifies the product-image invariant on the NATIVE engine.
//
// These tests run on the Dart VM with the real Flutter layout engine — the same
// RenderObject code the iOS/Android app uses — so they prove the native app, not
// just the web build.
//
// What they assert:
//   1. The image box a ProductCard gives its image is SQUARE, at every card
//      width and in every host (grid cell, fixed-height rail).
//   2. The image is drawn with BoxFit.contain on a WHITE background, so a square
//      1000x1000 source can never be cropped, and its white padding is invisible.
//
// Together with the fact that no kIsWeb branch touches this geometry, this is
// what makes "it looks right on web" transfer to the native app.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/widgets/custom_network_image.dart';
import 'package:fastway/features/home/presentation/widget/card/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps [child] in the minimum ProductCard needs: localisation + ScreenUtil.
Widget _host(Widget child) {
  return EasyLocalization(
    supportedLocales: const [Locale('ar'), Locale('en')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    child: Builder(
      builder: (context) => ScreenUtilInit(
        // designSize MUST be const — deriving it from live view metrics causes
        // an infinite rebuild loop on web.
        designSize: const Size(390, 844),
        // ScreenUtil only initialises via `builder`; passing `child` leaves
        // .w/.sp uninitialised and the subtree never builds.
        //
        // NOTE: deliberately NOT wiring context.localizationDelegates here.
        // EasyLocalization's delegate resolves asynchronously, and Localizations
        // withholds its child until it does — which pumpAndSettle cannot await,
        // so the whole card silently never renders. The card only needs
        // context.locale (from the EasyLocalization provider above) for its RTL
        // check; .tr() falling back to the raw key is fine, we measure geometry.
        builder: (_, __) => MaterialApp(
          locale: const Locale('en'),
          home: Scaffold(body: Center(child: child)),
        ),
      ),
    ),
  );
}

ProductCard _card() => const ProductCard(
      productId: '1',
      name: 'Test Protein Powder 1kg Chocolate',
      imageUrl: 'https://example.test/p.webp',
      price: 199.0,
      originalPrice: 249.0,
      brandName: 'Fastway',
      // keeps CartCubit / WishlistCubit out of the tree
      hideCartButton: true,
      hideFavoriteButton: true,
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // EasyLocalization persists the chosen locale via SharedPreferences, whose
    // platform channel does not exist under flutter_test.
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('ProductCard image box', () {
    /// Renders the card in a box of [w] x [h] and returns the size of the box
    /// the image actually got.
    Future<Size> imageBox(WidgetTester tester, double w, double h) async {
      await tester.pumpWidget(_host(SizedBox(width: w, height: h, child: _card())));
      await tester.pump();
      return tester.getSize(find.byType(CustomNetworkImage).first);
    }

    testWidgets('is SQUARE in a grid cell at every realistic card width',
        (tester) async {
      // widths a real cell takes: phone 2-col, phone 3-col, tablet, desktop
      for (final w in <double>[120, 150, 180, 220, 260, 300]) {
        final h = w / kProductCardAspectRatio; // how every grid now sizes its cell
        tester.view.physicalSize = Size(w + 200, h + 200);
        tester.view.devicePixelRatio = 1.0;

        final box = await imageBox(tester, w, h);
        final ratio = box.width / box.height;

        expect(
          ratio,
          closeTo(1.0, 0.06),
          reason: 'card width $w: image box ${box.width}x${box.height} '
              '(ratio ${ratio.toStringAsFixed(3)}) is not square — a 1:1 image '
              'would be letterboxed or, with cover, cropped',
        );
      }
      tester.view.resetPhysicalSize();
    });

    testWidgets('is SQUARE in the fixed-height rails (cart, related products)',
        (tester) async {
      // the rails hardcode pixel sizes rather than a ratio
      const rails = <String, Size>{
        'cart / wishlist rail': Size(180, 319),
        'details rail (mobile)': Size(155, 274),
        'details rail (web tree)': Size(180, 319),
      };

      for (final entry in rails.entries) {
        final size = entry.value;
        tester.view.physicalSize = Size(size.width + 200, size.height + 200);
        tester.view.devicePixelRatio = 1.0;

        final box = await imageBox(tester, size.width, size.height);
        final ratio = box.width / box.height;

        expect(
          ratio,
          closeTo(1.0, 0.06),
          reason: '${entry.key} (${size.width}x${size.height}): image box '
              '${box.width}x${box.height} is not square',
        );
      }
      tester.view.resetPhysicalSize();
    });

    testWidgets('image uses BoxFit.contain on white — it can never be cropped',
        (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        _host(SizedBox(width: 180, height: 180 / kProductCardAspectRatio, child: _card())),
      );
      await tester.pump();

      final img = tester.widget<CustomNetworkImage>(find.byType(CustomNetworkImage).first);

      expect(img.fit, BoxFit.contain,
          reason: 'BoxFit.cover fills the box and slices off the overflow — it '
              'is what cropped the product images. Must be contain.');
      expect(img.backgroundColor, Colors.white,
          reason: 'the letterbox must be white so the padding baked into the '
              'image is invisible; the default grey[200] would show as bars');

      // and the widget that actually paints it inherits the same fit
      final net = tester.widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage));
      if (net.isNotEmpty) {
        expect(net.first.fit, BoxFit.contain);
      }

      tester.view.resetPhysicalSize();
    });
  });
}
