// URL Scheme for Fastway Mobile Web
//
// RULE: Every constant must have a UNIQUE value.
// Dynamic routes (with :id) share a base prefix used for navigation ONLY —
// the actual matching is done via startsWith() in onGenerateRoute, not the switch.
//
// Mobile (iOS/Android): unaffected — paths are just route name strings.
// Web: these become real browser URLs that survive refresh and are shareable.

abstract class Routes {
  // ── Core ──────────────────────────────────────────────────────────────────
  static const String onboarding  = '/onboarding';
  static const String dashBoard   = '/dashboard';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String auth         = '/auth';
  static const String login        = '/login';
  static const String passwordLogin = '/login/password';
  static const String signup       = '/signup';
  // Legacy: email passed as Navigator argument. On web: use /verify/:email prefix
  static const String verification = '/verify';

  // ── Products ──────────────────────────────────────────────────────────────
  // /products          → all products list
  // /p/:id             → single product detail  (e.g. /p/123)
  static const String products      = '/products';
  static const String productDetails = '/p';       // navigate as: '${Routes.productDetails}/$id'

  // ── Brands ────────────────────────────────────────────────────
  // /brands/:id  → brand page  (e.g. /brands/1)
  static const String brand = '/brands'; // navigate as: '${Routes.brand}/$id'

  // ── Categories ────────────────────────────────────────────────────────────
  // /categories        → all categories list
  // /categories/:id    → products in category   (e.g. /categories/3)
  // /categories/:id/sub → sub-categories        (e.g. /categories/3/sub)
  static const String categories       = '/categories';
  // These are PREFIX constants used in navigation calls only — NOT switch cases:
  static const String categoryProducts = '/categories'; // nav: '${Routes.categoryProducts}/$id'
  static const String subCategories    = '/categories'; // nav: '${Routes.subCategories}/$id/sub'

  // ── Cart & Checkout ───────────────────────────────────────────────────────
  static const String cart          = '/cart';
  static const String checkout      = '/checkout';
  static const String orderSuccess  = '/order-success';

  // ── Orders ────────────────────────────────────────────────────────────────
  // /orders            → orders list
  // /orders/:id        → order detail   (e.g. /orders/ORD-001)
  // /orders/:id/track  → live tracking
  // /orders/:id/return → return status
  static const String orders        = '/orders';
  // Prefix constants for navigation — NOT switch cases:
  static const String orderDetails  = '/orders'; // nav: '${Routes.orderDetails}/$id'
  static const String orderTracking = '/orders'; // nav: '${Routes.orderTracking}/$id/track'
  static const String returnStatus  = '/orders'; // nav: '${Routes.returnStatus}/$id/return'

  // ── Profile & Account ─────────────────────────────────────────────────────
  static const String profile       = '/profile';
  static const String points        = '/profile/points';
  static const String wallet        = '/profile/wallet';
  static const String notifications = '/notifications';
  static const String wishlist      = '/wishlist';
  static const String helpCenter    = '/help';

  // ── Addresses ─────────────────────────────────────────────────────────────
  // /profile/addresses          → list
  // /profile/addresses/add      → new address
  // /profile/addresses/:id/edit → edit (handled by startsWith in router)
  static const String addresses   = '/profile/addresses';
  static const String addAddress  = '/profile/addresses/add';
  static const String editAddress = '/profile/addresses'; // nav: '${Routes.editAddress}/$id/edit'

  // ── Blog ──────────────────────────────────────────────────────────────────
  // /blog        → blog list
  // /blog/:slug  → single article  (e.g. /blog/protein-guide)
  static const String blog       = '/blog';
  static const String blogDetail = '/blog'; // nav: '${Routes.blogDetail}/$slug'

  // ── Misc ──────────────────────────────────────────────────────────────────
  static const String search      = '/search';
  static const String locationMap = '/location-map';
  static const String tracking    = '/tracking';
  // ── Legal & Static Pages ──────────────────────────────────────────────────
  static const String terms         = '/terms';
  static const String privacy       = '/privacy';
  static const String returnPolicy  = '/returns';
  static const String shipping      = '/shipping';
  static const String contact       = '/contact';
}
