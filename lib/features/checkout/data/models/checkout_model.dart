// lib/features/checkout/data/models/checkout_model.dart

import 'package:fastway/features/checkout/domain/entities/payment_method_entity.dart';
import 'package:fastway/features/checkout/domain/entities/saved_address_entity.dart';
import 'package:fastway/features/checkout/domain/entities/sdk_order_init.dart';
import 'package:fastway/features/checkout/domain/entities/shipping_method_entity.dart';
import '../../domain/entities/checkout_entity.dart';

/// Safely coerces a JSON value to String.
/// Handles localised Map values like {"en": "...", "ar": "..."} gracefully.
String _s(dynamic v, [String fallback = '']) {
  if (v == null) return fallback;
  if (v is String) return v;
  if (v is Map) return v['en']?.toString() ?? v.values.firstOrNull?.toString() ?? fallback;
  return v.toString();
}

String? _sOpt(dynamic v) {
  if (v == null) return null;
  if (v is String) return v.isEmpty ? null : v;
  if (v is Map) return v['en']?.toString() ?? v.values.firstOrNull?.toString();
  return v.toString();
}

class CheckoutModel extends CheckoutEntity {
  const CheckoutModel({
    required super.items,
    required super.subtotal,
    required super.discount,
    required super.shippingCost,
    required super.total,
    super.vatAmount,
    super.couponCode,
    super.couponDiscount,
    super.tierDiscount,
    super.selectedShipping,
    super.selectedPayment,
    super.selectedAddress,
    super.pointsToEarn,
    super.pointsInfo,
    super.walletBalance,
    super.groups,
  });

  factory CheckoutModel.fromJson(Map<String, dynamic> json) {
    // VAT: API returns { vat: { inclusive: true, rate: 15, amount: X } }
    final vatMap = json['vat'] is Map ? json['vat'] as Map<String, dynamic> : null;

    // Safe string extraction — guards against Map values returned for String fields
    String? safeString(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      if (v is Map) return v['en']?.toString() ?? v.values.firstOrNull?.toString();
      return v.toString();
    }

    return CheckoutModel(
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => CheckoutItemModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      shippingCost: (json['shipping_cost'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      vatAmount: (vatMap?['amount'] as num?)?.toDouble(),
      couponCode: safeString(json['coupon_code']),
      couponDiscount: (json['coupon_discount'] as num?)?.toDouble(),
      tierDiscount: (json['tier_discount'] as num?)?.toDouble(),
      selectedShipping: json['selected_shipping'] != null
          ? ShippingMethodModel.fromJson(
          json['selected_shipping'] as Map<String, dynamic>)
          : null,
      selectedPayment: json['selected_payment'] != null
          ? PaymentMethodModel.fromJson(
          json['selected_payment'] as Map<String, dynamic>)
          : null,
      selectedAddress: json['selected_address'] != null
          ? AddressModel.fromJson(
          json['selected_address'] as Map<String, dynamic>)
          : null,
      pointsToEarn: (json['points'] != null && json['points'] is Map)
          ? (json['points']['points_to_earn'] as int? ?? 0)
          : 0,
      pointsInfo: json['points'] is Map ? json['points'] as Map<String, dynamic> : null,
      walletBalance: (json['wallet_balance'] as num?)?.toDouble(),
      groups: (json['groups'] as List<dynamic>?)
          ?.map((e) => CheckoutGroupModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'items': items
        .map((e) => e is CheckoutItemModel
        ? e.toJson()
        : CheckoutItemModel(
      id: e.id,
      name: e.name,
      imageUrl: e.imageUrl,
      price: e.price,
      quantity: e.quantity,
    ).toJson())
        .toList(),
    'subtotal': subtotal,
    'discount': discount,
    'shipping_cost': shippingCost,
    'total': total,
    if (vatAmount != null) 'vat': {'amount': vatAmount, 'inclusive': true, 'rate': 15},
    'coupon_code': couponCode,
    'coupon_discount': couponDiscount,
    'tier_discount': tierDiscount,
    // ✅ fromEntity بدل الـ unsafe cast
    'selected_shipping': selectedShipping != null
        ? ShippingMethodModel.fromEntity(selectedShipping!).toJson()
        : null,
    'selected_payment': selectedPayment != null
        ? PaymentMethodModel.fromEntity(selectedPayment!).toJson()
        : null,
    'selected_address': selectedAddress != null
        ? AddressModel.fromEntity(selectedAddress!).toJson()
        : null,
    'points_to_earn': pointsToEarn,
    'points': pointsInfo,
    'groups': groups
        ?.map((e) => e is CheckoutGroupModel
            ? e.toJson()
            : CheckoutGroupModel.fromEntity(e).toJson())
        .toList(),
  };

  factory CheckoutModel.fromEntity(CheckoutEntity entity) {
    return CheckoutModel(
      items: entity.items,
      subtotal: entity.subtotal,
      discount: entity.discount,
      shippingCost: entity.shippingCost,
      total: entity.total,
      vatAmount: entity.vatAmount,
      couponCode: entity.couponCode,
      couponDiscount: entity.couponDiscount,
      tierDiscount: entity.tierDiscount,
      selectedShipping: entity.selectedShipping != null
          ? ShippingMethodModel.fromEntity(entity.selectedShipping!)
          : null,
      selectedPayment: entity.selectedPayment != null
          ? PaymentMethodModel.fromEntity(entity.selectedPayment!)
          : null,
      selectedAddress: entity.selectedAddress != null
          ? AddressModel.fromEntity(entity.selectedAddress!)
          : null,
      pointsToEarn: entity.pointsToEarn,
      pointsInfo: entity.pointsInfo,
      walletBalance: entity.walletBalance,
      groups: entity.groups?.map((e) => CheckoutGroupModel.fromEntity(e)).toList(),
    );
  }
  CheckoutModel copyWithModel({
    List<CheckoutItemEntity>? items,
    double? subtotal,
    double? discount,
    double? shippingCost,
    double? total,
    double? vatAmount,
    String? couponCode,
    double? couponDiscount,
    double? tierDiscount,
    ShippingMethodEntity? selectedShipping,
    PaymentMethodEntity? selectedPayment,
    AddressEntity? selectedAddress,
    int? pointsToEarn,
    Map<String, dynamic>? pointsInfo,
    double? walletBalance,
    List<CheckoutGroupEntity>? groups,
  }) {
    return CheckoutModel(
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      shippingCost: shippingCost ?? this.shippingCost,
      total: total ?? this.total,
      vatAmount: vatAmount ?? this.vatAmount,
      couponCode: couponCode ?? this.couponCode,
      couponDiscount: couponDiscount ?? this.couponDiscount,
      tierDiscount: tierDiscount ?? this.tierDiscount,
      selectedShipping: selectedShipping ?? this.selectedShipping,
      selectedPayment: selectedPayment ?? this.selectedPayment,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      pointsToEarn: pointsToEarn ?? this.pointsToEarn,
      pointsInfo: pointsInfo ?? this.pointsInfo,
      walletBalance: walletBalance ?? this.walletBalance,
      groups: groups ?? this.groups,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class CheckoutGroupModel extends CheckoutGroupEntity {
  const CheckoutGroupModel({
    required super.id,
    required super.storeId,
    required super.storeName,
    super.label,
    super.labelAr,
    required super.items,
    super.selectedShipping,
    super.availableShippingMethods,
    super.isExpressGroup,
    super.hasColdItems,
  });

  factory CheckoutGroupModel.fromJson(Map<String, dynamic> json) {
    // API sends group_id (not id) and type (not is_express_group)
    final typeStr = _s(json['type']);
    final isExpress = typeStr == 'express' ||
        (json['is_express_group'] as bool?) == true;
    return CheckoutGroupModel(
      id: (json['group_id'] ?? json['id'])?.toString() ?? '',
      storeId: json['store_id']?.toString() ?? '',
      storeName: _s(json['store_name']),
      label: _s(json['label']),
      labelAr: _s(json['label_ar']),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CheckoutItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      selectedShipping: json['selected_shipping'] != null
          ? ShippingMethodModel.fromJson(
              json['selected_shipping'] as Map<String, dynamic>)
          : null,
      availableShippingMethods: (json['available_shipping_methods'] as List<dynamic>?)
          ?.map((e) => ShippingMethodModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isExpressGroup: isExpress,
      hasColdItems: json['has_cold_items'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'group_id': id,
        'store_id': storeId,
        'store_name': storeName,
        'label': label,
        'label_ar': labelAr,
        'items': items
            .map((e) => e is CheckoutItemModel
                ? e.toJson()
                : CheckoutItemModel.fromEntity(e).toJson())
            .toList(),
        'selected_shipping': selectedShipping != null
            ? ShippingMethodModel.fromEntity(selectedShipping!).toJson()
            : null,
        'available_shipping_methods': availableShippingMethods
            ?.map((e) => ShippingMethodModel.fromEntity(e).toJson())
            .toList(),
        'is_express_group': isExpressGroup,
        'has_cold_items': hasColdItems,
      };

  factory CheckoutGroupModel.fromEntity(CheckoutGroupEntity entity) {
    return CheckoutGroupModel(
      id: entity.id,
      storeId: entity.storeId,
      storeName: entity.storeName,
      label: entity.label,
      labelAr: entity.labelAr,
      items: entity.items,
      selectedShipping: entity.selectedShipping,
      availableShippingMethods: entity.availableShippingMethods,
      isExpressGroup: entity.isExpressGroup,
      hasColdItems: entity.hasColdItems,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class CheckoutItemModel extends CheckoutItemEntity {
  const CheckoutItemModel({
    required super.id,
    super.productId,
    required super.name,
    required super.imageUrl,
    required super.price,
    required super.quantity,
    super.stockWarning,
    super.isExpress,
    super.isExpressEligible,
  });

  factory CheckoutItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return CheckoutItemModel(
      id: json['id']?.toString() ?? '',
      productId: (json['product_id'] ?? product?['id'])?.toString(),
      name: _s(json['name'] ?? product?['name']),
      imageUrl: _sOpt(json['image_url'] ?? product?['image_url'] ?? product?['primary_image_url']) ?? '',
      price: (json['price'] as num?)?.toDouble()
          ?? (product?['price'] as num?)?.toDouble()
          ?? 0.0,
      quantity: json['quantity'] as int? ?? 1,
      stockWarning: _sOpt(json['stock_warning']),
      isExpress: json['is_express'] as bool? ?? false,
      isExpressEligible: product?['is_express_eligible'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (productId != null) 'product_id': productId,
    'name': name,
    'image_url': imageUrl,
    'price': price,
    'quantity': quantity,
    'is_express': isExpress,
    'is_express_eligible': isExpressEligible,
  };

  factory CheckoutItemModel.fromEntity(CheckoutItemEntity entity) {
    return CheckoutItemModel(
      id: entity.id,
      productId: entity.productId,
      name: entity.name,
      imageUrl: entity.imageUrl,
      price: entity.price,
      quantity: entity.quantity,
      isExpress: entity.isExpress,
      isExpressEligible: entity.isExpressEligible,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class ShippingMethodModel extends ShippingMethodEntity {
  const ShippingMethodModel({
    required super.id,
    required super.name,
    super.nameAr,
    required super.description,
    required super.cost,
    required super.estimatedTime,
    super.estimatedTimeAr,
    super.isFree,
    super.provider,
    super.type,
    super.isCodSupported,
    super.iconUrl,
    super.supportsColdChain,
    super.isDisabled,
    super.isSelected,
  });

  factory ShippingMethodModel.fromEntity(ShippingMethodEntity e) {
    return ShippingMethodModel(
      id: e.id,
      name: e.name,
      nameAr: e.nameAr,
      description: e.description,
      cost: e.cost,
      estimatedTime: e.estimatedTime,
      estimatedTimeAr: e.estimatedTimeAr,
      isFree: e.isFree,
      provider: e.provider,
      type: e.type,
      isCodSupported: e.isCodSupported,
      iconUrl: e.iconUrl,
      supportsColdChain: e.supportsColdChain,
      isDisabled: e.isDisabled,
      isSelected: e.isSelected,
    );
  }

  factory ShippingMethodModel.fromJson(Map<String, dynamic> json) {
    final cost = (json['cost'] as num?)?.toDouble() ?? 0.0;
    final isDisabled = json['is_disabled'] as bool? ?? false;
    return ShippingMethodModel(
      id: json['id'].toString(),
      name: _s(json['name']),
      nameAr: _s(json['name_ar']),
      description: _s(json['description']),
      cost: cost,
      estimatedTime: _s(json['estimated_time']),
      estimatedTimeAr: _s(json['estimated_time_ar']),
      isFree: json['is_free'] as bool? ?? cost == 0,
      provider: _s(json['provider'], 'manual'),
      type: _s(json['type'], 'standard'),
      isCodSupported: json['is_cod_supported'] as bool? ?? false,
      iconUrl: _sOpt(json['icon_url']),
      supportsColdChain: json['supports_cold_chain'] as bool? ?? true,
      isDisabled: isDisabled,
      isSelected: json['is_selected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'name_ar': nameAr,
    'description': description,
    'cost': cost,
    'estimated_time': estimatedTime,
    'estimated_time_ar': estimatedTimeAr,
    'is_free': isFree,
    'provider': provider,
    'type': type,
    'is_cod_supported': isCodSupported,
    'icon_url': iconUrl,
    'is_disabled': isDisabled,
    'is_selected': isSelected,
  };
}

// ─────────────────────────────────────────────────────────────────────────────

class PaymentMethodModel extends PaymentMethodEntity {
  const PaymentMethodModel({
    required super.id,
    required super.name,
    required super.provider,
    super.iconUrl,
    super.isCod = false,
    super.applePayEnabled = false,
    super.appleMerchantId,
  });

  // ✅ تحويل آمن من entity لـ model
  factory PaymentMethodModel.fromEntity(PaymentMethodEntity e) {
    return PaymentMethodModel(
      id: e.id,
      name: e.name,
      provider: e.provider,
      iconUrl: e.iconUrl,
      isCod: e.isCod,
      applePayEnabled: e.applePayEnabled,
      appleMerchantId: e.appleMerchantId,
    );
  }

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'].toString(),
      name: _s(json['name']),
      provider: _parseProvider(
          _s(json['type']) .isNotEmpty ? _s(json['type']) : _s(json['name'])),
      iconUrl: _sOpt(json['icon_url']),
      isCod: json['is_cod'] as bool? ?? false,
      // S4 — Apple Pay gate fields from API (safe defaults if absent)
      applePayEnabled: json['apple_pay_enabled'] as bool? ?? false,
      appleMerchantId: _sOpt(json['apple_merchant_id']),
    );
  }

  static PaymentProvider _parseProvider(String raw) {
    final lower = raw.toLowerCase();
    if (lower == 'cod' || lower.contains('cash') || lower.contains('استلام')) return PaymentProvider.cod;
    if (lower == 'telr' || lower.contains('credit') || lower.contains('بطاقة')) return PaymentProvider.telr;
    if (lower == 'tamara' || lower.contains('تمارا')) return PaymentProvider.tamara;
    if (lower == 'tabby' || lower.contains('تابي')) return PaymentProvider.tabby;
    return PaymentProvider.unknown;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': provider.name,
    'icon_url': iconUrl,
    'is_cod': isCod,
    'apple_pay_enabled': applePayEnabled,
    'apple_merchant_id': appleMerchantId,
  };
}

// ─────────────────────────────────────────────────────────────────────────────

class AddressModel extends AddressEntity {
  const AddressModel({
    required super.id,
    required super.label,
    required super.fullAddress,
    required super.city, // BUG-19 FIX: city now in entity
    required super.phone,
    required super.isDefault,
    super.building,
    super.street,
    super.district,
    super.shortAddress,
    super.postalCode,
    super.additionalNumber,
    super.lat,
    super.lng,
  });

  factory AddressModel.fromEntity(AddressEntity e) {
    return AddressModel(
      id: e.id,
      label: e.label,
      fullAddress: e.fullAddress,
      city: e.city, // BUG-19 FIX: pass city
      phone: e.phone,
      isDefault: e.isDefault,
      building: e.building,
      street: e.street,
      district: e.district,
      shortAddress: e.shortAddress,
      postalCode: e.postalCode,
      additionalNumber: e.additionalNumber,
      lat: e.lat,
      lng: e.lng,
    );
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    // Guards against fields that might be Maps instead of plain strings
    String safeStr(dynamic v, [String fallback = '']) {
      if (v == null) return fallback;
      if (v is String) return v;
      if (v is Map) return v['en']?.toString() ?? v.values.firstOrNull?.toString() ?? fallback;
      return v.toString();
    }
    String? safeStrOpt(dynamic v) {
      if (v == null) return null;
      if (v is String) return v.isEmpty ? null : v;
      if (v is Map) return v['en']?.toString() ?? v.values.firstOrNull?.toString();
      return v.toString();
    }

    return AddressModel(
      id: json['id'].toString(),
      label: safeStr(json['label'] ?? json['title']),
      fullAddress: safeStr(json['full_address']),
      city: safeStr(json['city']),
      phone: safeStr(json['phone']),
      isDefault: json['is_default'] as bool? ?? false,
      building: safeStrOpt(json['building']),
      street: safeStrOpt(json['street']),
      district: safeStrOpt(json['district']),
      shortAddress: safeStrOpt(json['short_address']),
      postalCode: safeStrOpt(json['postal_code']),
      additionalNumber: safeStrOpt(json['additional_number']),
      lat: (json['lat'] as num?)?.toDouble()
          ?? double.tryParse(json['latitude']?.toString() ?? ''),
      lng: (json['lng'] as num?)?.toDouble()
          ?? double.tryParse(json['longitude']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'full_address': fullAddress,
    'city': city,
    'phone': phone,
    'is_default': isDefault,
    if (building != null) 'building': building,
    if (street != null) 'street': street,
    if (district != null) 'district': district,
    if (shortAddress != null) 'short_address': shortAddress,
    if (postalCode != null) 'postal_code': postalCode,
    if (additionalNumber != null) 'additional_number': additionalNumber,
    if (lat != null) 'lat': lat,
    if (lng != null) 'lng': lng,
  };
}

// ─────────────────────────────────────────────────────────────────────────────

/// Result of POST /payments/telr/sdk/order — the two URLs the Telr Flutter SDK
/// needs (from Telr's _links) plus the ap_ref used to confirm the charge server-side.
class SdkOrderInitModel extends SdkOrderInit {
  const SdkOrderInitModel({
    required super.apRef,
    required super.tokenUrl,
    required super.orderUrl,
    super.amount,
  });

  factory SdkOrderInitModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    return SdkOrderInitModel(
      apRef:    (data['ap_ref'] ?? '') as String,
      tokenUrl: (data['token_url'] ?? '') as String,
      orderUrl: (data['order_url'] ?? '') as String,
      amount:   data['amount']?.toString(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
