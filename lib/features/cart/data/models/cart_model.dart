import '../../domain/entities/cart_entity.dart';
import '../../../home/data/model/product_model.dart';
import '../../../home/domain/entities/product_entity.dart';

/// Safely convert any JSON numeric-ish value to [int].
/// Handles: int → direct, double → truncate, String → parse, null → null.
int? _safeInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt();
  return null;
}

class CartModel extends CartEntity {
  const CartModel({
    required super.items,
    required super.subtotal,
    required super.discount,
    required super.shippingCost,
    required super.total,
    super.couponCode,
    super.couponDiscount,
    super.tierDiscount,
    super.tierBonusPercent,
    super.totalSavings = 0.0,
    super.savingsMessage,
    super.suggestions,
    super.pointsEarned = 0,
    super.pointsUsed,
    super.pointsDiscount,
    super.coldRecommendation = false,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    // Helper: safely extract a String from a field that might be a Map
    // (e.g. savings_message could be {"en":"...", "ar":"..."})
    String? safeString(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      if (v is Map) return v['en']?.toString() ?? v.values.firstOrNull?.toString();
      return v.toString();
    }

    return CartModel(
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      shippingCost: (json['shipping_cost'] as num?)?.toDouble() ??
          (json['shippingCost'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      couponCode: safeString(json['coupon_code']) ?? safeString(json['couponCode']),
      couponDiscount: (json['coupon_discount'] as num?)?.toDouble() ??
          (json['couponDiscount'] as num?)?.toDouble(),
      tierDiscount: (json['tier_discount'] as num?)?.toDouble(),
      tierBonusPercent: json['tier'] is Map
          ? ((json['tier']['bonus_points_percent'] as num?)?.toDouble())
          : null,
      totalSavings: (json['total_savings'] as num?)?.toDouble() ?? 0.0,
      savingsMessage: safeString(json['savings_message']),
      suggestions: (json['suggestions'] as List<dynamic>?)
          ?.map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pointsEarned: _safeInt(json['total_points_to_earn']) ?? 0,
      pointsUsed: _safeInt(json['points_used']),
      pointsDiscount: (json['points_discount'] as num?)?.toDouble(),
      coldRecommendation: json['cold_recommendation'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((e) => (e as CartItemModel).toJson()).toList(),
    'subtotal': subtotal,
    'discount': discount,
    'shipping_cost': shippingCost,
    'total': total,
    'coupon_code': couponCode,
    'coupon_discount': couponDiscount,
    'tier_discount': tierDiscount,
    'tier_bonus_percent': tierBonusPercent,
    'total_savings': totalSavings,
    'savings_message': savingsMessage,
    'suggestions': suggestions?.map((e) => (e as ProductModel).toJson()).toList(),
    'total_points_to_earn': pointsEarned,
    'points_used': pointsUsed,
    'points_discount': pointsDiscount,
    'cold_recommendation': coldRecommendation,
  };

  CartModel copyWithModel({
    List<CartItemEntity>? items,
    double? subtotal,
    double? discount,
    double? shippingCost,
    double? total,
    String? couponCode,
    double? couponDiscount,
    double? tierDiscount,
    double? tierBonusPercent,
    double? totalSavings,
    String? savingsMessage,
    List<ProductEntity>? suggestions,
    int? pointsEarned,
    int? pointsUsed,
    double? pointsDiscount,
    bool? coldRecommendation,
    bool clearCoupon = false,
  }) {
    return CartModel(
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      shippingCost: shippingCost ?? this.shippingCost,
      total: total ?? this.total,
      couponCode: clearCoupon ? null : (couponCode ?? this.couponCode),
      couponDiscount: clearCoupon ? null : (couponDiscount ?? this.couponDiscount),
      tierDiscount: tierDiscount ?? this.tierDiscount,
      tierBonusPercent: tierBonusPercent ?? this.tierBonusPercent,
      totalSavings: totalSavings ?? this.totalSavings,
      savingsMessage: savingsMessage ?? this.savingsMessage,
      suggestions: suggestions ?? this.suggestions,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      pointsUsed: pointsUsed ?? this.pointsUsed,
      pointsDiscount: pointsDiscount ?? this.pointsDiscount,
      coldRecommendation: coldRecommendation ?? this.coldRecommendation,
    );
  }

  factory CartModel.fromEntity(CartEntity entity) {
    return CartModel(
      items: entity.items,
      subtotal: entity.subtotal,
      discount: entity.discount,
      shippingCost: entity.shippingCost,
      total: entity.total,
      couponCode: entity.couponCode,
      couponDiscount: entity.couponDiscount,
      tierDiscount: entity.tierDiscount,
      tierBonusPercent: entity.tierBonusPercent,
      totalSavings: entity.totalSavings,
      savingsMessage: entity.savingsMessage,
      suggestions: entity.suggestions,
      pointsEarned: entity.pointsEarned,
      pointsUsed: entity.pointsUsed,
      pointsDiscount: entity.pointsDiscount,
      coldRecommendation: entity.coldRecommendation,
    );
  }
}

class CartItemModel extends CartItemEntity {
  const CartItemModel({
    required super.id,
    required super.productId,
    required super.name,
    required super.imageUrl,
    required super.price,
    super.originalPrice,
    required super.quantity,
    super.maxQuantity,
    super.isAvailable,
    super.stockWarning,
    super.isOnSale,
    super.savings,
    super.nameAr,
    super.brandName,
    super.brandNameAr,
    super.isExpress,
    super.isExpressEligible,
    super.requiresColdShipping, // GAP-41
    super.isGift,
    super.giftLabel,
    super.giftLabelAr,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // Safely coerce a JSON field to String — guards against localised Map values
    // like {"en": "...", "ar": "..."} that some API endpoints return.
    String ss(dynamic v, [String fallback = '']) {
      if (v == null) return fallback;
      if (v is String) return v;
      if (v is Map) return v['en']?.toString() ?? v.values.firstOrNull?.toString() ?? fallback;
      return v.toString();
    }
    String? ssOpt(dynamic v) {
      if (v == null) return null;
      if (v is String) return v.isEmpty ? null : v;
      if (v is Map) return v['en']?.toString() ?? v.values.firstOrNull?.toString();
      return v.toString();
    }

    // Nested product object (present in checkout/cart API responses)
    final p = json['product'] as Map<String, dynamic>?;

    return CartItemModel(
      // The backend returns numeric IDs — convert safely to String
      id: (json['id'] ?? '').toString(),

      // product_id comes back as int from the API
      productId: (json['product_id'] ?? json['productId'] ?? '').toString(),

      name: ss(json['name'] ?? p?['name'], 'Unknown'),

      imageUrl: ss(
        json['image_url'] ?? json['imageUrl'] ?? p?['image_url'] ?? p?['primary_image_url'],
      ),

      price: (json['price'] as num?)?.toDouble()
          ?? double.tryParse(p?['price']?.toString() ?? '') ?? 0.0,

      originalPrice: (json['original_price'] as num?)?.toDouble() ??
          (json['originalPrice'] as num?)?.toDouble(),

      quantity: _safeInt(json['quantity']) ?? 1,
      maxQuantity: _safeInt(json['max_quantity']) ?? _safeInt(json['maxQuantity']) ?? 10,
      isAvailable: (json['is_available'] as bool?) ?? (json['isAvailable'] as bool?) ?? true,
      stockWarning: ssOpt(json['stock_warning']),
      isOnSale: json['is_on_sale'] as bool? ?? false,
      savings: (json['savings'] as num?)?.toDouble() ?? 0.0,
      nameAr: ssOpt(json['name_ar'] ?? p?['name_ar']),
      brandName: ssOpt(json['brand_name'] ?? p?['brand_name'] ?? (p?['brand'] is Map ? p?['brand']?['name'] : p?['brand'])),
      brandNameAr: ssOpt(json['brand_name_ar'] ?? p?['brand_name_ar'] ?? (p?['brand'] is Map ? p?['brand']?['name_ar'] : p?['brand'])),
      isExpress: json['is_express'] as bool? ?? false,
      isExpressEligible: json['is_express_eligible'] as bool?
          ?? p?['is_express_eligible'] as bool? ?? false,
      // GAP-41: parse cold-chain flag from product data nested in the cart item
      requiresColdShipping: json['requires_cold_shipping'] as bool?
          ?? (p?['requires_cold_shipping'] as bool?)
          ?? false,
      // Granted by an automatic cart offer. The server already prices these at 0,
      // so `price` needs no special handling here — the flag exists so the UI can
      // badge the line and hide its quantity stepper.
      isGift: json['is_gift'] as bool? ?? false,
      giftLabel: ssOpt(json['gift_label']),
      giftLabelAr: ssOpt(json['gift_label_ar']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'name': name,
    'image_url': imageUrl,
    'price': price,
    'original_price': originalPrice,
    'quantity': quantity,
    'max_quantity': maxQuantity,
    'is_available': isAvailable,
    'stock_warning': stockWarning,
    'is_on_sale': isOnSale,
    'savings': savings,
    'name_ar': nameAr,
    'brand_name': brandName,
    'brand_name_ar': brandNameAr,
    'is_express': isExpress,
    'is_express_eligible': isExpressEligible,
  };

  factory CartItemModel.fromEntity(CartItemEntity entity) {
    return CartItemModel(
      id: entity.id,
      productId: entity.productId,
      name: entity.name,
      imageUrl: entity.imageUrl,
      price: entity.price,
      originalPrice: entity.originalPrice,
      quantity: entity.quantity,
      maxQuantity: entity.maxQuantity,
      isAvailable: entity.isAvailable,
      stockWarning: entity.stockWarning,
      isOnSale: entity.isOnSale,
      savings: entity.savings,
      nameAr: entity.nameAr,
      brandName: entity.brandName,
      brandNameAr: entity.brandNameAr,
      isExpress: entity.isExpress,
      isExpressEligible: entity.isExpressEligible,
      requiresColdShipping: entity.requiresColdShipping, // GAP-41
      isGift: entity.isGift,
      giftLabel: entity.giftLabel,
      giftLabelAr: entity.giftLabelAr,
    );
  }

  CartItemModel copyWithModel({
    String? id,
    String? productId,
    String? name,
    String? imageUrl,
    double? price,
    double? originalPrice,
    int? quantity,
    int? maxQuantity,
    bool? isAvailable,
    String? stockWarning,
    bool? isOnSale,
    double? savings,
    String? nameAr,
    String? brandName,
    String? brandNameAr,
    bool? isExpress,
    bool? isExpressEligible,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      quantity: quantity ?? this.quantity,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      isAvailable: isAvailable ?? this.isAvailable,
      stockWarning: stockWarning ?? this.stockWarning,
      isOnSale: isOnSale ?? this.isOnSale,
      savings: savings ?? this.savings,
      nameAr: nameAr ?? this.nameAr,
      brandName: brandName ?? this.brandName,
      brandNameAr: brandNameAr ?? this.brandNameAr,
      isExpress: isExpress ?? this.isExpress,
      isExpressEligible: isExpressEligible ?? this.isExpressEligible,
    );
  }
}
