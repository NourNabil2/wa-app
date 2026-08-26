import 'package:fastway/core/api/base_api_services.dart';
import 'package:dio/dio.dart';
import 'package:fastway/core/api/model/endpoints.dart';
import 'package:fastway/core/api/model/http_method.dart';
import 'package:fastway/core/errors/exceptions.dart';
import 'package:fastway/core/api/api_error_handler.dart';
import 'package:fastway/features/checkout/data/models/checkout_model.dart'
    hide OrderModel;
import 'package:fastway/features/checkout/data/models/city_model.dart';
import 'package:fastway/features/checkout/data/models/place_order_result_model.dart';

abstract class CheckoutRemoteDataSource {
  Future<List<ShippingMethodModel>> getShippingMethods();
  Future<List<PaymentMethodModel>> getPaymentMethods();
  Future<List<CityModel>> getCities();
  Future<List<CountryModel>> getCountries();
  Future<Map<String, List<String>>> getDeliverySlots();

  /// GET /checkout/summary — returns split cart groups with group_id AND points info.
  Future<Map<String, dynamic>> getCheckoutSummary({double? lat, double? lng});

  /// Authoritative totals for the CHOSEN shipping method — computed server-side by
  /// the same code that will place the order, so the screen can never quote a
  /// different VAT or total than the customer is actually charged.
  Future<Map<String, dynamic>> getCheckoutQuote({
    required List<Map<String, dynamic>> groups,
    int? pointsToUse,
    double? walletAmount,
    bool? useWallet,
  });

  /// Authenticated user order — POST /checkout/place-order (Bearer).
  /// [groups] must match backend: [{group_id, shipping_method_id}].
  /// [paymentMethodId] is null for a pure wallet-only order (no gateway) —
  /// the backend re-verifies the wallet fully covers the total before
  /// allowing this; never trust it client-side alone.
  Future<PlaceOrderResultModel> placeOrder({
    required List<Map<String, dynamic>> groups,
    int? paymentMethodId,
    int? addressId,
    String? notes,
    int? pointsToUse,
    double? walletAmount,
    bool? useWallet,
    String? deliveryDate,
    String? deliverySlot,
  });

  /// Guest order — POST /checkout/guest-place-order (X-Session-ID).
  Future<PlaceOrderResultModel> placeGuestOrder({
    required List<Map<String, dynamic>> groups,
    required int paymentMethodId,
    required Map<String, dynamic> guestAddress,
    String? notes,
    int? pointsToUse,
    double? walletAmount,
    String? deliveryDate,
    String? deliverySlot,
  });

  /// Initiate Telr payment for an already-placed order.
  /// POST /checkout/initiate-payment (Bearer) → returns payment_url.
  Future<String> initiatePayment(String orderId);

  /// Cancel an unpaid BNPL order group and rebuild the cart from its items.
  /// POST /checkout/cancel-unpaid (Bearer).
  Future<void> cancelUnpaid(String orderId);

  /// Admin payment link → seed the logged-in customer's cart from the order
  /// (owner-only). POST /pay/{token}/load-to-cart (Bearer). Returns a prefill map:
  /// { wallet_to_apply, shipping_method_id, payment_method_id, coupon_code, address }.
  Future<Map<String, dynamic>> loadPayLinkToCart(String token);

  /// Apple Pay (Telr SDK) — step 1: create the Telr order.
  /// POST /payments/telr/sdk/order → { ap_ref, token_url, order_url }.
  /// The token_url/order_url are handed to TelrSdk.payWithApplePay.
  Future<SdkOrderInitModel> createSdkOrder({
    required int paymentMethodId,
    required List<Map<String, dynamic>> groups,
    int? addressId,
    Map<String, dynamic>? guestAddress,
    String? notes,
    int? pointsToUse,
    String? deliveryDate,
    String? deliverySlot,
  });

  /// Apple Pay (Telr SDK) — step 2: confirm the charge server-side after the sheet closes.
  /// POST /payments/telr/sdk/confirm { ap_ref } → returns the created order_number.
  Future<String> confirmSdkPayment(String apRef);
}

class CheckoutRemoteDataSourceImpl implements CheckoutRemoteDataSource {
  /// Returns the backend's human-readable message from a DioException.
  /// Priority: JSON `message` → JSON `error` → status-code fallback.
  static String _dioMsg(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'] ?? data['error'];
      if (msg != null && msg.toString().trim().isNotEmpty) return msg.toString().trim();
      // Laravel validation: {"errors":{"field":["msg"]}}
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
    }
    switch (e.response?.statusCode) {
      case 400: return 'طلب غير صحيح';
      case 401: return 'يرجى تسجيل الدخول أولاً';
      case 403: return 'غير مسموح بهذا الإجراء';
      case 404: return 'البيانات غير موجودة';
      case 422: return 'البيانات المدخلة غير صحيحة';
      case 429: return 'طلبات كثيرة، يرجى الانتظار';
      case 500: return 'خطأ في الخادم، حاول لاحقاً';
      default:
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout) {
          return 'تحقق من اتصالك بالإنترنت';
        }
        return 'حدث خطأ غير متوقع';
    }
  }

  /// Maps a thrown error to a ServerException, tagging a gateway PAYMENT REJECTION
  /// (e.g. Tabby "order amount too high") with the PAYMENT_REJECTED code so the UI
  /// can prompt the customer to pick another method instead of a generic snackbar.
  static ServerException _placeOrderError(Object e, String fallbackCode) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['payment_rejected'] == true) {
        return ServerException(_dioMsg(e), 'PAYMENT_REJECTED');
      }
    }
    return ServerException(ApiErrorHandler.getMessage(e), fallbackCode);
  }

  final BaseApiServices _api;

  CheckoutRemoteDataSourceImpl(this._api);

  List<T> _parseList<T>(
      dynamic res, T Function(Map<String, dynamic>) fromJson) {
    final list = (res['data'] ?? res) as List;
    return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<ShippingMethodModel>> getShippingMethods() async {
    try {
      final res = await _api.request(
          method: HttpMethod.get, url: Endpoints.shippingMethods);
      return _parseList(res, ShippingMethodModel.fromJson);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'SHIPPING_FETCH_ERROR');
    }
  }

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    try {
      final res = await _api.request(
          method: HttpMethod.get, url: Endpoints.paymentMethods);
      return _parseList(res, PaymentMethodModel.fromJson);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'PAYMENT_FETCH_ERROR');
    }
  }

  @override
  Future<List<CityModel>> getCities() async {
    try {
      final res =
      await _api.request(method: HttpMethod.get, url: Endpoints.cities);
      return _parseList(res, CityModel.fromJson);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'CITIES_FETCH_ERROR');
    }
  }

  @override
  Future<List<CountryModel>> getCountries() async {
    try {
      final res =
      await _api.request(method: HttpMethod.get, url: Endpoints.countries);
      return _parseList(res, CountryModel.fromJson);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'COUNTRIES_FETCH_ERROR');
    }
  }

  @override
  Future<Map<String, List<String>>> getDeliverySlots() async {
    try {
      final res = await _api.request(method: HttpMethod.get, url: Endpoints.deliverySlots);
      final data = res['data'] ?? res;
      final map = <String, List<String>>{};
      // data may be an empty map {} when no slots are configured (local/mock env)
      if (data is Map<String, dynamic>) {
        data.forEach((key, value) {
          if (value is List) {
            map[key] = value.map((e) => e.toString()).toList();
          }
        });
      }
      return map;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'DELIVERY_SLOTS_FETCH_ERROR');
    }
  }

  @override
  Future<Map<String, dynamic>> getCheckoutSummary({double? lat, double? lng}) async {
    try {
      final res = await _api.request(
        method: HttpMethod.post,
        url: Endpoints.checkoutPrepare,
        body: {
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        },
      );
      final data = res['data'] ?? res;
      return data as Map<String, dynamic>;
    } catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'CHECKOUT_SUMMARY_ERROR');
    }
  }

  @override
  Future<Map<String, dynamic>> getCheckoutQuote({
    required List<Map<String, dynamic>> groups,
    int? pointsToUse,
    double? walletAmount,
    bool? useWallet,
  }) async {
    try {
      final res = await _api.request(
        method: HttpMethod.post,
        url: Endpoints.checkoutQuote,
        body: {
          'groups': groups,
          if (pointsToUse != null) 'points_to_use': pointsToUse,
          if (walletAmount != null) 'wallet_amount': walletAmount,
          if (useWallet != null) 'use_wallet': useWallet,
        },
      );
      final data = res['data'] ?? res;
      return data as Map<String, dynamic>;
    } catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'CHECKOUT_QUOTE_ERROR');
    }
  }

  @override
  Future<PlaceOrderResultModel> placeOrder({
    required List<Map<String, dynamic>> groups,
    int? paymentMethodId,
    int? addressId,
    String? notes,
    int? pointsToUse,
    double? walletAmount,
    bool? useWallet,
    String? deliveryDate,
    String? deliverySlot,
  }) async {
    try {
      final res = await _api.request(
        method: HttpMethod.post,
        url: Endpoints.placeOrder,
        body: {
          'groups': groups,
          // Omitted (not sent as null) when wallet fully covers the order —
          // the backend requires the key to simply be absent, not null, to
          // route into the wallet-only branch.
          if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
          if (addressId != null) 'address_id': addressId,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (pointsToUse != null && pointsToUse > 0) 'points_to_use': pointsToUse,
          if (walletAmount != null && walletAmount > 0) 'wallet_amount': walletAmount,
          if (useWallet == true) 'use_wallet': true,
          if (deliveryDate != null) 'delivery_date': deliveryDate,
          if (deliverySlot != null) 'delivery_slot': deliverySlot,
        },
      );
      return PlaceOrderResultModel.fromJson(res);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw _placeOrderError(e, 'PLACE_ORDER_ERROR');
    }
  }

  @override
  Future<PlaceOrderResultModel> placeGuestOrder({
    required List<Map<String, dynamic>> groups,
    required int paymentMethodId,
    required Map<String, dynamic> guestAddress,
    String? notes,
    int? pointsToUse,
    double? walletAmount,
    String? deliveryDate,
    String? deliverySlot,
  }) async {
    try {
      final res = await _api.request(
        method: HttpMethod.post,
        url: Endpoints.placeGuestOrder,
        body: {
          'groups': groups,
          'payment_method_id': paymentMethodId,
          'guest_address': guestAddress,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (pointsToUse != null && pointsToUse > 0) 'points_to_use': pointsToUse,
          if (walletAmount != null && walletAmount > 0) 'wallet_amount': walletAmount,
          if (deliveryDate != null) 'delivery_date': deliveryDate,
          if (deliverySlot != null) 'delivery_slot': deliverySlot,
        },
      );
      return PlaceOrderResultModel.fromJson(res);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw _placeOrderError(e, 'GUEST_PLACE_ORDER_ERROR');
    }
  }

  @override
  Future<String> initiatePayment(String orderId) async {
    try {
      final res = await _api.request(
        method: HttpMethod.post,
        url: Endpoints.initiatePayment,
        body: {'order_id': orderId},
      );
      final data = res['data'] ?? res;
      final url = data['payment_url'] as String?;
      if (url == null || url.isEmpty) {
        throw ServerException('No payment URL returned', 'NO_PAYMENT_URL');
      }
      return url;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'INITIATE_PAYMENT_ERROR');
    }
  }

  @override
  Future<void> cancelUnpaid(String orderId) async {
    try {
      await _api.request(
        method: HttpMethod.post,
        url: Endpoints.cancelUnpaid,
        body: {'order_id': orderId},
      );
    } catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'CANCEL_UNPAID_ERROR');
    }
  }

  @override
  Future<Map<String, dynamic>> loadPayLinkToCart(String token) async {
    try {
      final res = await _api.request(
        method: HttpMethod.post,
        url: Endpoints.payLinkLoadToCart(token),
      );
      final data = (res is Map && res['data'] is Map) ? res['data'] : res;
      return Map<String, dynamic>.from(data as Map);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'PAY_LINK_LOAD_ERROR');
    }
  }

  @override
  Future<SdkOrderInitModel> createSdkOrder({
    required int paymentMethodId,
    required List<Map<String, dynamic>> groups,
    int? addressId,
    Map<String, dynamic>? guestAddress,
    String? notes,
    int? pointsToUse,
    String? deliveryDate,
    String? deliverySlot,
  }) async {
    try {
      final body = <String, dynamic>{
        'payment_method_id': paymentMethodId,
        'groups': groups,
        if (addressId != null)    'address_id': addressId,
        if (guestAddress != null) 'guest_address': guestAddress,
        if (notes != null)        'notes': notes,
        if (pointsToUse != null)  'points_to_use': pointsToUse,
        if (deliveryDate != null) 'delivery_date': deliveryDate,
        if (deliverySlot != null) 'delivery_slot': deliverySlot,
      };
      final res = await _api.request(
        method: HttpMethod.post,
        url: Endpoints.telrSdkOrder,
        body: body,
      );
      final model = SdkOrderInitModel.fromJson(Map<String, dynamic>.from(res));
      if (model.apRef.isEmpty || model.tokenUrl.isEmpty || model.orderUrl.isEmpty) {
        throw ServerException('Could not start Apple Pay: incomplete order response', 'AP_SDK_ORDER');
      }
      return model;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'AP_SDK_ORDER_ERROR');
    }
  }

  @override
  Future<String> confirmSdkPayment(String apRef) async {
    try {
      final res = await _api.request(
        method: HttpMethod.post,
        url: Endpoints.telrSdkConfirm,
        body: {'ap_ref': apRef},
      );
      final data = res['data'] ?? res;
      final orderNumber = data['order_number'] as String?;
      if (orderNumber == null || orderNumber.isEmpty) {
        throw ServerException('Apple Pay confirmation failed: no order number returned', 'AP_NO_ORDER');
      }
      return orderNumber;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'AP_SDK_CONFIRM_ERROR');
    }
  }
}