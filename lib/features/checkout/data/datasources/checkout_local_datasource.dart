// lib/features/checkout/data/datasources/checkout_local_datasource.dart

import 'dart:convert';
import 'dart:math';
import 'package:fastway/features/checkout/domain/entities/payment_method_entity.dart';
import 'package:fastway/features/checkout/domain/entities/saved_address_entity.dart';
import 'package:fastway/features/checkout/domain/entities/shipping_method_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/checkout_entity.dart';
import '../models/checkout_model.dart';
import 'package:easy_localization/easy_localization.dart';

abstract class CheckoutLocalDataSource {
  Future<CheckoutModel> getCheckoutData();
  Future<List<ShippingMethodEntity>> getShippingMethods();
  Future<List<PaymentMethodEntity>> getPaymentMethods();
  Future<CheckoutModel> selectShippingMethod(String shippingId);
  Future<CheckoutModel> selectPaymentMethod(String paymentId);
  Future<CheckoutModel> selectAddress(String addressId);
  Future<Map<String, dynamic>> placeOrder();
}

class CheckoutLocalDataSourceImpl implements CheckoutLocalDataSource {
  final SharedPreferences _prefs;
  static const String _checkoutKey = 'checkout_data';
  static const String _cartKey = 'cart_data';

  CheckoutLocalDataSourceImpl(this._prefs);

  // ── Mock data ─────────────────────────────────────────────────────────────

  static const List<ShippingMethodEntity> _mockShipping = [
    ShippingMethodEntity(
      id: '1',
      name: 'أرامكس',
      description: 'توصيل خلال 2-3 أيام مع تتبع الشحنة',
      cost: 0, // مجاني
      estimatedTime: '2-3 أيام',
    ),
    ShippingMethodEntity(
      id: '2',
      name: 'سمسا',
      description: 'توصيل خلال 1-2 أيام مع تتبع الشحنة',
      cost: 15.0,
      estimatedTime: '1-2 أيام',

    ),
    ShippingMethodEntity(
      id: '3',
      name: 'توصيل سريع',
      description: 'توصيل خلال 4-6 ساعات داخل المدينة',
      cost: 30.0, // تكلفة أعلى للتوصيل السريع
      estimatedTime: '4-6 ساعات',

    ),
  ];

  static const List<PaymentMethodEntity> _mockPayment = [
    PaymentMethodEntity(
      id: '1',
      name: 'الدفع عند الاستلام',
      provider: PaymentProvider.cod,
    ),
    PaymentMethodEntity(
      id: '2',
      name: 'بطاقة ائتمان',
      provider: PaymentProvider.telr,
    ),
  ];

  static List<AddressEntity> get _mockAddresses => [
    AddressEntity(
      id: '1',
      label: 'address.home'.tr(),
      fullAddress: 'الرياض حي النرجس شارع الخصخصي',
      city: 'الرياض', // BUG-19 FIX: city now required
      phone: '0501234567',
      isDefault: true,
    ),
    AddressEntity(
      id: '2',
      label: 'address.work'.tr(),
      fullAddress: 'الرياض حي العليا طريق الملك فهد',
      city: 'الرياض', // BUG-19 FIX: city now required
      phone: '0501234567',
      isDefault: false,
    ),
  ];

  // ── Interface implementation ───────────────────────────────────────────────

  @override
  Future<CheckoutModel> getCheckoutData() async {
    await Future.delayed(const Duration(milliseconds: 400));

    final cartJson = _prefs.getString(_cartKey);

    List<CheckoutItemEntity> items = [];
    double subtotal = 0;
    double discount = 0;
    String? couponCode;
    double? couponDiscount;

    if (cartJson != null) {
      final cartData = jsonDecode(cartJson) as Map<String, dynamic>;
      items = (cartData['items'] as List<dynamic>?)
          ?.map((e) => CheckoutItemModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [];
      subtotal = (cartData['subtotal'] as num?)?.toDouble() ?? 0.0;
      discount = (cartData['discount'] as num?)?.toDouble() ?? 0.0;
      couponCode = cartData['coupon_code'] as String?;
      couponDiscount = (cartData['coupon_discount'] as num?)?.toDouble();
    }

    // Restore previously selected options
    ShippingMethodEntity? selectedShipping;
    PaymentMethodEntity? selectedPayment;
    AddressEntity? selectedAddress;

    final checkoutJson = _prefs.getString(_checkoutKey);
    if (checkoutJson != null) {
      final saved = jsonDecode(checkoutJson) as Map<String, dynamic>;
      if (saved['selected_shipping'] != null) {
        selectedShipping = ShippingMethodModel.fromJson(
            saved['selected_shipping'] as Map<String, dynamic>);
      }
      if (saved['selected_payment'] != null) {
        selectedPayment = PaymentMethodModel.fromJson(
            saved['selected_payment'] as Map<String, dynamic>);
      }
      if (saved['selected_address'] != null) {
        selectedAddress = AddressModel.fromJson(
            saved['selected_address'] as Map<String, dynamic>);
      }
    }

    // Defaults
    selectedShipping ??= _mockShipping.first;
    selectedPayment ??= _mockPayment.first;
    selectedAddress ??= _mockAddresses.firstWhere(
          (a) => a.isDefault,
      orElse: () => _mockAddresses.first,
    );

    final shippingCost = selectedShipping.cost;
    final total = subtotal + shippingCost - (couponDiscount ?? 0);

    return CheckoutModel(
      items: items,
      subtotal: subtotal,
      discount: discount,
      shippingCost: shippingCost,
      total: total,
      couponCode: couponCode,
      couponDiscount: couponDiscount,
      selectedShipping: selectedShipping,
      selectedPayment: selectedPayment,
      selectedAddress: selectedAddress,
    );
  }

  @override
  Future<List<ShippingMethodEntity>> getShippingMethods() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockShipping;
  }

  @override
  Future<List<PaymentMethodEntity>> getPaymentMethods() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockPayment;
  }

  @override
  Future<CheckoutModel> selectShippingMethod(String shippingId) async {
    final checkout = await getCheckoutData();
    final shipping = _mockShipping.firstWhere(
          (s) => s.id == shippingId,
      orElse: () => _mockShipping.first,
    );
    final updated = checkout.copyWithModel(
      selectedShipping: shipping,
      shippingCost: shipping.cost,
      total: checkout.subtotal + shipping.cost - (checkout.couponDiscount ?? 0),
    );
    await _save(updated);
    return updated;
  }

  @override
  Future<CheckoutModel> selectPaymentMethod(String paymentId) async {
    final checkout = await getCheckoutData();
    final payment = _mockPayment.firstWhere(
          (p) => p.id == paymentId,
      orElse: () => _mockPayment.first,
    );
    final updated = checkout.copyWithModel(selectedPayment: payment);
    await _save(updated);
    return updated;
  }

  @override
  Future<CheckoutModel> selectAddress(String addressId) async {
    final checkout = await getCheckoutData();
    final address = _mockAddresses.firstWhere(
          (a) => a.id == addressId,
      orElse: () => _mockAddresses.first,
    );
    final updated = checkout.copyWithModel(selectedAddress: address);
    await _save(updated);
    return updated;
  }

  @override
  Future<Map<String, dynamic>> placeOrder() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final checkout = await getCheckoutData();
    final orderNumber =
        'ORD-${DateTime.now().year}${Random().nextInt(999999).toString().padLeft(6, '0')}';

    final order = <String, dynamic>{
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'order_number': orderNumber,
      'created_at': DateTime.now().toIso8601String(),
      'total': checkout.total,
      'status': 'pending',
      'items': checkout.items.map((e) => {
        'id': e.id,
        'name': e.name,
        'image_url': e.imageUrl,
        'price': e.price,
        'quantity': e.quantity,
      }).toList(),
    };

    // Clear cart + checkout state after order
    await _prefs.remove(_cartKey);
    await _prefs.remove(_checkoutKey);

    // Persist to order history
    final history = _prefs.getStringList('orders') ?? [];
    history.add(jsonEncode(order));
    await _prefs.setStringList('orders', history);

    return order;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _save(CheckoutModel checkout) async {
    await _prefs.setString(_checkoutKey, jsonEncode(checkout.toJson()));
  }
}