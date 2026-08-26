import 'package:dio/dio.dart';
import 'package:fastway/core/api/api_error_handler.dart';
import 'package:fastway/core/api/base_api_services.dart';
import 'package:fastway/core/api/model/endpoints.dart';
import 'package:fastway/core/api/model/http_method.dart';
import 'package:fastway/core/errors/exceptions.dart';
import 'package:fastway/features/cart/data/models/cart_model.dart';

abstract class CartRemoteDataSource {
  Future<CartModel> getCart({double? lat, double? lng, String? addressId});
  Future<CartModel> addItem(String productId, int quantity, {double? lat, double? lng, String? addressId});
  Future<CartModel> updateItem(String itemId, int quantity, {double? lat, double? lng, String? addressId});
  Future<CartModel> removeItem(String itemId, {double? lat, double? lng, String? addressId});
  Future<CartModel> clearCart();
  Future<CartModel> applyCoupon(String code, {double? lat, double? lng, String? addressId});
  Future<CartModel> removeCoupon({double? lat, double? lng, String? addressId});
  Future<CartModel> toggleExpressItem(String itemId, {double? lat, double? lng, String? addressId});
  /// Merge a guest session cart into the authenticated user's cart.
  Future<CartModel> mergeGuestCart(String sessionId, {double? lat, double? lng});
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final BaseApiServices _api;
  CartRemoteDataSourceImpl(this._api);

  CartModel _parseCart(dynamic response) {
    final data = response['data'] ?? response;
    return CartModel.fromJson(data as Map<String, dynamic>);
  }

  /// Extracts the backend's human-readable error message from a DioException.
  /// Priority: response `message` field → `error` field → fallback string.
  String _extractMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'] ?? data['error'];
      if (msg != null && msg.toString().isNotEmpty) return msg.toString();
    }
    return fallback;
  }

  /// Builds location params. address_id takes priority over lat/lng for logged-in users.
  Map<String, dynamic> _locationParams({double? lat, double? lng, String? addressId}) => {
    if (addressId != null) 'address_id': int.tryParse(addressId) ?? addressId,
    if (addressId == null && lat != null) 'lat': lat,
    if (addressId == null && lng != null) 'lng': lng,
  };

  @override
  Future<CartModel> getCart({double? lat, double? lng, String? addressId}) async {
    try {
      final res = await _api.request(
        method: HttpMethod.get,
        url: Endpoints.cart,
        queryParams: _locationParams(lat: lat, lng: lng, addressId: addressId),
      );
      return _parseCart(res);
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'CART_GET_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'CART_GET_ERROR');
    }
  }

  @override
  Future<CartModel> addItem(String productId, int quantity, {double? lat, double? lng, String? addressId}) async {
    try {
      final res = await _api.request(
        method: HttpMethod.post,
        url: Endpoints.cartAdd,
        body: {
          'product_id': int.parse(productId),
          'quantity': quantity,
          ..._locationParams(lat: lat, lng: lng, addressId: addressId),
        },
      );
      return _parseCart(res);
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'CART_ADD_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'CART_ADD_ERROR');
    }
  }

  @override
  Future<CartModel> updateItem(String itemId, int quantity, {double? lat, double? lng, String? addressId}) async {
    try {
      final res = await _api.request(
        method: HttpMethod.put,
        url: '${Endpoints.cartItems}/$itemId',
        body: {
          'quantity': quantity,
          ..._locationParams(lat: lat, lng: lng, addressId: addressId),
        },
      );
      return _parseCart(res);
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'CART_UPDATE_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'CART_UPDATE_ERROR');
    }
  }

  @override
  Future<CartModel> removeItem(String itemId, {double? lat, double? lng, String? addressId}) async {
    try {
      final res = await _api.request(
        method: HttpMethod.delete,
        url: '${Endpoints.cartItems}/$itemId',
        queryParams: _locationParams(lat: lat, lng: lng, addressId: addressId),
      );
      return _parseCart(res);
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'CART_REMOVE_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'CART_REMOVE_ERROR');
    }
  }

  @override
  Future<CartModel> clearCart() async {
    try {
      // DELETE /cart — clears entire cart, returns empty cart summary.
      final res = await _api.request(
        method: HttpMethod.delete,
        url: Endpoints.cart,
      );
      // Server returns { "status": true, "message": "Cart cleared.", "data": null }
      // Return an empty cart on success.
      if (res['data'] == null) {
        return const CartModel(
          items: [],
          subtotal: 0,
          discount: 0,
          shippingCost: 0,
          total: 0,
        );
      }
      return _parseCart(res);
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'CART_CLEAR_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'CART_CLEAR_ERROR');
    }
  }

  @override
  Future<CartModel> applyCoupon(String code, {double? lat, double? lng, String? addressId}) async {
    try {
      final res = await _api.request(
        method: HttpMethod.post,
        url: Endpoints.applyCoupon,
        body: {
          'code': code,
          ..._locationParams(lat: lat, lng: lng, addressId: addressId),
        },
      );
      return _parseCart(res);
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'COUPON_APPLY_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'COUPON_APPLY_ERROR');
    }
  }

  @override
  Future<CartModel> removeCoupon({double? lat, double? lng, String? addressId}) async {
    try {
      final res = await _api.request(
        method: HttpMethod.delete,
        url: Endpoints.removeCoupon,
        queryParams: _locationParams(lat: lat, lng: lng, addressId: addressId),
      );
      return _parseCart(res);
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'COUPON_REMOVE_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'COUPON_REMOVE_ERROR');
    }
  }

  @override
  Future<CartModel> toggleExpressItem(String itemId, {double? lat, double? lng, String? addressId}) async {
    try {
      final res = await _api.request(
        method: HttpMethod.patch,
        url: '${Endpoints.cartItems}/$itemId/express',
        queryParams: _locationParams(lat: lat, lng: lng, addressId: addressId),
      );
      return _parseCart(res);
    } on DioException catch (e) {
      // Surface the backend's exact message (e.g. "This product is not available for express delivery.")
      throw ServerException(
        _extractMessage(e, 'Express toggle failed.'),
        'CART_EXPRESS_TOGGLE_ERROR',
      );
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'CART_EXPRESS_TOGGLE_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'CART_EXPRESS_TOGGLE_ERROR');
    }
  }

  @override
  Future<CartModel> mergeGuestCart(String sessionId, {double? lat, double? lng}) async {
    try {
      final res = await _api.request(
        method: HttpMethod.post,
        url: Endpoints.cartMergeGuest,
        body: {
          'session_id': sessionId,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        },
      );
      return _parseCart(res);
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'CART_MERGE_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'CART_MERGE_ERROR');
    }
  }
}