import 'dart:convert';
import 'package:dio/dio.dart';
import 'mock_data.dart';
import 'model/endpoints.dart';
import 'local_database.dart';

class MockApiInterceptor extends Interceptor {
  final LocalDatabase db;
  MockApiInterceptor(this.db);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;

    // Home & Categories
    if (path.contains(Endpoints.home)) {
      return _resolve(handler, options, jsonDecode(MockData.homeJson));
    }

    if (path.contains(Endpoints.banners) || path.contains(Endpoints.mobileBanners)) {
      return _resolve(handler, options, {
        "data": jsonDecode(MockData.homeJson)['data']['banners'],
        "message": "Success"
      });
    }

    if (path == Endpoints.categories) {
      return _resolve(handler, options, {
        "data": jsonDecode(MockData.homeJson)['data']['categories']
      });
    }

    if (path == Endpoints.products || path.contains('/products')) {
      final parts = path.split(Endpoints.products);
      if (parts.length > 1 && parts.last.isNotEmpty && !parts.last.startsWith('?')) {
        // It's a specific product, e.g. /products/101
        final idStr = parts.last.replaceAll('/', '').split('?').first;
        final productId = int.tryParse(idStr);
        final product = db.mockProducts[productId] ?? jsonDecode(MockData.homeJson)['data']['new_arrivals'][0];
        return _resolve(handler, options, {
          "data": product
        });
      }
      // Return list of products with pagination format
      return _resolve(handler, options, {
        "data": {
          "products": jsonDecode(MockData.homeJson)['data']['new_arrivals'],
          "total": jsonDecode(MockData.homeJson)['data']['new_arrivals'].length,
          "current_page": 1,
          "last_page": 1
        }
      });
    }

    // Brands — /brands/{id}
    if (path.contains('/brands')) {
      final allProducts = jsonDecode(MockData.homeJson)['data']['new_arrivals'] as List<dynamic>;
      // Try to find the brand id from the path
      final brandId = path.split('/brands/').last.split('?').first;
      return _resolve(handler, options, {
        "data": {
          "brand": {
            "id": brandId.isEmpty ? "1" : brandId,
            "name": "كهرمان أصلي",
            "name_ar": "كهرمان أصلي",
            "logo_url": "assets/images/rosary_amber_1786203630351.jpg",
            "description": "مسابح وإكسسوارات راقية",
            "country": "SA"
          },
          "products": allProducts,
          "total": allProducts.length,
          "current_page": 1,
          "last_page": 1
        }
      });
    }
    
    // Cart
    if (path.contains(Endpoints.cartAdd)) {
      final productId = options.data['product_id'] ?? options.data['id']; // handle different formats
      final quantity = options.data['quantity'] ?? 1;
      return _resolve(handler, options, db.addToCart(productId, quantity));
    }

    // Cart merge (after login) - must come before generic cartItems check
    if (path.contains(Endpoints.cartMergeGuest)) {
      return _resolve(handler, options, db.getCartResponse());
    }

    if (path.contains(Endpoints.cartItems)) {
      final parts = path.split('/');
      final itemId = int.tryParse(parts.last);
      
      if (itemId != null) {
        if (options.method == 'PUT' || options.method == 'PATCH') {
          final quantity = options.data['quantity'] ?? 1;
          return _resolve(handler, options, db.updateCartItem(itemId, quantity));
        } else if (options.method == 'DELETE') {
          return _resolve(handler, options, db.removeCartItem(itemId));
        }
      }
    }

    if (path == Endpoints.cart) {
      return _resolve(handler, options, db.getCartResponse());
    }

    if (path.contains(Endpoints.applyCoupon)) {
      final code = options.data['code']?.toString() ?? options.data['coupon_code']?.toString();
      if (code?.toUpperCase() == 'FAST50') {
        final cart = db.getCartResponse()['data'];
        if ((cart['subtotal'] as num) >= 200) {
          db.applyCouponCode('FAST50');
          return _resolve(handler, options, db.getCartResponse());
        } else {
          handler.reject(DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 400,
              data: {"message": "يجب ان تتجاوز قيمة الطلب 200 ر.س لتطبيق الكوبون"}
            )
          ));
          return;
        }
      } else {
        handler.reject(DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 400,
            data: {"message": "كوبون غير صالح"}
          )
        ));
        return;
      }
    }

    if (path.contains(Endpoints.removeCoupon)) {
      db.removeCouponCode();
      return _resolve(handler, options, db.getCartResponse());
    }

    // Wallet
    if (path.contains(Endpoints.wallet)) {
      return _resolve(handler, options, {
        "data": {
          "balance": db.walletBalance,
          "history": []
        }
      });
    }

    // Points
    if (path.contains(Endpoints.points)) {
      return _resolve(handler, options, {
        "data": {
          "balance": db.pointsBalance,
          "history": []
        }
      });
    }

    // Checkout
    if (path.contains(Endpoints.placeOrder) || path.contains(Endpoints.placeGuestOrder)) {
      return _resolve(handler, options, db.placeOrder(options.data ?? {}));
    }

    if (path.contains(Endpoints.addresses)) {
      return _resolve(handler, options, {
        "data": [
          {
            "id": 1,
            "is_default": true,
            "label": "المنزل",
            "full_address": "طريق الملك فهد، الرياض",
            "city": "الرياض",
            "phone": "0500000000",
            "lat": 24.7136,
            "lng": 46.6753,
            "building": "123",
            "street": "طريق الملك فهد",
            "district": "حي العليا"
          }
        ]
      });
    }

    if (path.contains(Endpoints.checkoutPrepare) || path.contains(Endpoints.checkoutQuote)) {
      final cartData = db.getCartResponse()['data'];
      return _resolve(handler, options, {
        "data": {
          "cart": cartData,
          "groups": [
            {
              "group_id": "1",
              "type": "standard",
              "label": "Standard Delivery",
              "label_ar": "توصيل عادي",
              "available_shipping_methods": [
                {
                  "id": "1",
                  "name": "Standard Delivery",
                  "name_ar": "توصيل عادي",
                  "cost": 15.0,
                  "is_free": false,
                  "estimated_time": "2-3 Days",
                  "estimated_time_ar": "2-3 أيام",
                  "is_cod_supported": true,
                  "is_selected": true
                }
              ],
              "items": cartData['items'] ?? []
            }
          ],
          "wallet_balance": db.walletBalance,
          "wallet": {
            "max_usable": db.walletBalance
          },
          "points": null,
          "national_address_mandatory": false
        }
      });
    }

    if (path.contains(Endpoints.deliverySlots)) {
      return _resolve(handler, options, {
        "data": {}
      });
    }

    if (path.contains(Endpoints.initiatePayment)) {
      return _resolve(handler, options, {
        "data": {
          "redirect_url": "https://example.com/payment"
        }
      });
    }

    if (path.contains(Endpoints.orders)) {
      // Return specific order or list of orders
      final parts = path.split(Endpoints.orders);
      if (parts.length > 1 && parts.last.isNotEmpty && !parts.last.startsWith('?')) {
        final idStr = parts.last.replaceAll('/', '').split('?').first;
        return _resolve(handler, options, {
          "data": db.getOrder(idStr)
        });
      }
      return _resolve(handler, options, {
        "data": {
          "orders": db.getOrders(),
          "total": db.getOrders().length,
          "current_page": 1,
          "last_page": 1
        }
      });
    }

    if (path.contains(Endpoints.shippingMethods)) {
      return _resolve(handler, options, {
        "data": [
          {"id": 1, "name": "توصيل سريع", "cost": 0, "estimated_days": "1-2 days"}
        ]
      });
    }

    if (path.contains(Endpoints.paymentMethods)) {
      return _resolve(handler, options, {
        "data": [
          {"id": 1, "name": "الدفع عند الاستلام", "code": "cod"},
          {"id": 10, "name": "المحفظة", "code": "wallet"}
        ]
      });
    }

    // Profile
    if (path == Endpoints.profile || path.endsWith(Endpoints.profile)) {
      return _resolve(handler, options, {
        "data": {
          "id": "1",
          "name": "User",
          "email": "user@example.com",
          "phone": "0500000000"
        }
      });
    }

    // Auth (Login / Register)
    if (path.contains(Endpoints.login) || 
        path.contains(Endpoints.loginPassword) || 
        path.contains(Endpoints.register) || 
        path.contains(Endpoints.verifyOTP)) {
      return _resolve(handler, options, {
        "data": {
          "token": "mock_token_123456",
          "user": {
            "id": "1",
            "name": "Test User",
            "email": "test@example.com",
            "phone": "0500000000"
          }
        },
        "message": "Success"
      });
    }

    if (path.contains(Endpoints.cities) || path.contains(Endpoints.countries)) {
      return _resolve(handler, options, {
        "data": [
          {"id": 1, "name": "Riyadh", "name_ar": "الرياض"},
          {"id": 2, "name": "Jeddah", "name_ar": "جدة"}
        ]
      });
    }
    
    // Fallback for others
    return _resolve(handler, options, {"data": [], "message": "Mock success fallback"});
  }

  void _resolve(RequestInterceptorHandler handler, RequestOptions options, Map<String, dynamic> data) {
    handler.resolve(Response(
      requestOptions: options,
      data: data,
      statusCode: 200,
    ));
  }
}

