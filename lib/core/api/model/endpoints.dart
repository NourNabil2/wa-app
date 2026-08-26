// ==================== endpoints.dart ====================
// BUG-54 FIX: baseUrl corrected to fastway.atwdemo.com (was clinical.khorogat.com)
// BUG-55 FIX: All 25+ missing endpoints declared
abstract class Endpoints {
  // ── Base URL: switch between local dev and production ─────
  //
  // Environments:
  //   Local (dev):  flutter run --dart-define=USE_LOCAL=true
  //   Main branch:  --dart-define=BASE_URL=https://fastway.atwdemo.com/api/v1
  //   AWS branch:   --dart-define=BASE_URL=https://admin.fastwayprotein.com/api/v1
  //
  // If neither USE_LOCAL nor BASE_URL is set, falls back to the main (atwdemo) endpoint.
  static const bool   _useLocal = bool.fromEnvironment('USE_LOCAL', defaultValue: false);
  static const String _baseUrlOverride = String.fromEnvironment('BASE_URL', defaultValue: '');

  static const String baseUrl = _useLocal
      ? 'http://localhost:8000/api/v1'
      : (_baseUrlOverride != '' ? _baseUrlOverride : 'https://admin.fastwayprotein.com/api/v1');

  // ── Auth ──────────────────────────────────────────────────
  static const String register      = '/auth/register';
  static const String login         = '/auth/login';
  static const String loginPassword = '/auth/login-password';
  static const String logout        = '/auth/logout';
  static const String verifyOTP     = '/auth/verify-otp';
  static const String resendOTP     = '/auth/resend-otp';

  // ── Home ──────────────────────────────────────────────────
  static const String home          = '/home';
  static const String search        = '/search'; // FIX: was '/products/search' — 404

  // ── Products ─────────────────────────────────────────────
  static const String products      = '/products';
  static const String featured      = '/products/featured';
  static const String newArrivals   = '/products/new-arrivals';
  static const String buyAgain      = '/products/buy-again';
  static const String recentlyViewed= '/products/recently-viewed';
  static const String wishlist      = '/wishlist';
  static const String wishlistToggle= '/wishlist/toggle';
  // Product detail:  GET $products/{id}
  // Product reviews: GET/POST $products/{id}/reviews

  // ── Categories ───────────────────────────────────────────
  static const String categories    = '/categories';
  static const String campaignProducts = '/campaign-categories';
  // Category products: GET $categories/{id}/products

  // ── Cart ─────────────────────────────────────────────────
  static const String cart           = '/cart';
  static const String cartAdd        = '/cart/add';
  static const String cartItems      = '/cart/items';    // + /{id} for update/remove
  static const String applyCoupon    = '/cart/apply-coupon';
  static const String removeCoupon   = '/cart/remove-coupon';
  static const String cartMergeGuest = '/cart/merge-guest'; // call after login to transfer guest items

  // ── Checkout ─────────────────────────────────────────────
  static const String addresses          = '/profile/addresses'; // + /{id}, PATCH /{id}/default
  static const String nearestAddress     = '/profile/addresses/nearest';
  static const String addressLookup      = '/address/lookup';
  static const String checkoutPrepare   = '/checkout/prepare';
  /// Re-quote once a shipping method is chosen. `prepare` runs before one exists,
  /// so its VAT covers goods only — the delivery fee is VAT-inclusive too and
  /// joins the taxable base, which moves the VAT line.
  static const String checkoutQuote     = '/checkout/quote';
  static const String shippingMethods   = '/checkout/shipping-methods';
  static const String paymentMethods    = '/checkout/payment-methods';
  static const String deliverySlots     = '/checkout/delivery-slots';
  static const String placeOrder        = '/checkout/place-order';
  static const String placeGuestOrder        = '/checkout/guest-place-order';
  static const String stockNotifications = '/stock-notifications';
  static const String cities            = '/cities';
  static const String countries            = '/countries';
  static const String initiatePayment            = '/checkout/initiate-payment';
  // Back out of an unpaid BNPL order → cancel the group + rebuild the cart
  static const String cancelUnpaid               = '/checkout/cancel-unpaid';
  // Admin payment link → seed the customer's cart from the order (owner-only).
  static String payLinkLoadToCart(String token) => '/pay/$token/load-to-cart';
  // Payment return check — used by web to poll after opening Telr in a new tab
  static const String telrCheckReturn           = '/payments/telr/return'; // GET ?status=&cartid=

  // ── Apple Pay via the Telr Flutter SDK (iOS app) ─────────────────────────
  // The SDK (TelrSdk.payWithApplePay) drives the native Apple Pay sheet using
  // tokenURL + orderURL, then the app confirms server-side. See checkout_cubit.applePayPlaceOrder.
  static const String telrSdkToken   = '/payments/telr/sdk/token';   // GET  (SDK tokenURL)
  static const String telrSdkOrder   = '/payments/telr/sdk/order';   // POST → { ap_ref, order }
  static const String telrSdkConfirm = '/payments/telr/sdk/confirm'; // POST { ap_ref } → order_number

  // ── Apple Pay on the Web (Telr Configuration 1 / Apple Pay JS) ────────────
  // Used by web/apple_pay.js via the checkout cubit's webApplePayPlaceOrder.
  static const String telrValidateMerchant = '/payments/telr/applepay/validate-merchant'; // POST { validation_url } → { merchant_session }
  static const String telrWebApplePay      = '/payments/telr/applepay';                   // POST { ...checkout, apple_pay_token } → { order_number }

  // ── Orders ───────────────────────────────────────────────
  static const String orders        = '/orders';
  // Order detail:    GET  $orders/{id}
  // Order tracking:  GET  $orders/{id}/track
  // Order invoice:   GET  $orders/{id}/invoice      (T8.1)
  // Order cancel:    POST $orders/{id}/cancel
  static const String reorder       = '/orders'; // + '/{id}/reorder'
  static const String returns       = '/returns';

  // ── Payment Polling ──────────────────────────────────────
  // T7.4: GET $paymentStatus/{orderNumber} → { data: { payment_status, is_paid } }
  static const String paymentStatus = '/payments/status'; // + '/{orderNumber}'

  // ── Profile ──────────────────────────────────────────────
  static const String profile       = '/profile';
  static const String profileAvatar = '/profile/avatar';
  static const String deleteAccount = '/account/delete';
  static const String notifications            = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsMarkRead    = '/notifications/mark-read';
  static const String notificationSettings  = '/notifications/settings';

  // ── Points ───────────────────────────────────────────────
  static const String points        = '/points';
  static const String pointsHistory = '/points/history';

  // ── Wallet ───────────────────────────────────────────────
  static const String wallet        = '/wallet';
  static const String walletHistory = '/wallet/history';

  // ── Banners ──────────────────────────────────────────────
  static const String banners       = '/banners';
  static const String mobileBanners = '/mobile-banners';
  static const String announcements = '/announcements';
  static const String popupBanner   = '/popup-banner';

  // ── Device Tokens (FCM) ───────────────────────────────────
  static const String deviceTokens  = '/device-tokens';

  // ── Blog ──────────────────────────────────────────────────
  static const String blog           = '/blog';
  static const String blogCategories = '/blog/categories';
  // Blog detail:  GET $blog/{slug}
  // ── Brands ────────────────────────────────────────────────
  static const String brands         = '/brands';
  // Product filters (brands/genders that have products in a given category)
  static const String productFilters = '/products/filters';
  // ── Warehouses (Contact Us) ───────────────────────────────
  static const String warehouses     = '/warehouses';
}
