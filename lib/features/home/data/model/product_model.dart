import '../../domain/entities/product_entity.dart';

/// Safely convert any JSON numeric-ish value to [int].
/// Handles: int → direct, double → truncate, String → parse, null → null.
int? _safeInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt();
  return null;
}

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.imageUrl,
    required super.price,
    super.originalPrice,
    super.rating,
    super.reviewCount,
    super.isNew,
    super.isAvailable,
    super.nameAr,
    super.stockWarning,
    super.pointsToEarn,
    super.isOnSale,
    super.savings,
    super.isBundle,
    super.isExpressEligible,
    super.isFeatured,
    super.categoryId,
    super.hasPromotion,
    super.promotionEndsAt,
    super.requiresColdShipping,
    super.expiryDate,
    super.isWishlisted,
    super.brandName,
    super.brandNameAr,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Safely coerce a JSON field to String — guards against localised Map values
    // like {"en": "...", "ar": "..."} that the API may return for any text field.
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

    final stock = _safeInt(json['stock']) ?? 1;
    final apiIsAvailable = json['is_available'] as bool? ?? true;

    // Product is only truly available when BOTH the flag is true AND stock > 0
    final isAvailable = apiIsAvailable && stock > 0;

    return ProductModel(
      id: json['id'].toString(),
      name: ss(json['name'], 'Unknown'),
      imageUrl: ss(json['image_url'] ?? json['image']),
      price: (json['price'] as num?)?.toDouble()
          ?? double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      originalPrice: json['original_price'] != null
          ? (json['original_price'] as num?)?.toDouble()
              ?? double.tryParse(json['original_price'].toString())
          : null,
      rating: json['rating'] != null
          ? (json['rating'] as num?)?.toDouble()
          : null,
      reviewCount: _safeInt(json['review_count']),
      isNew: json['is_new'] as bool? ?? false,
      isAvailable: isAvailable,
      nameAr: ssOpt(json['name_ar']),
      stockWarning: ssOpt(json['stock_warning']),
      pointsToEarn: _safeInt(json['points_to_earn']) ?? 0,
      isOnSale: json['is_on_sale'] as bool? ?? false,
      savings: (json['savings'] as num?)?.toDouble() ?? 0.0,
      isBundle: json['is_bundle'] as bool? ?? false,
      isExpressEligible: json['is_express_eligible'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      categoryId: json['category_id']?.toString(),
      hasPromotion: json['has_promotion'] as bool? ?? false,
      promotionEndsAt: ssOpt(json['promotion_ends_at']),
      requiresColdShipping: json['requires_cold_shipping'] as bool? ?? false,
      expiryDate: ssOpt(json['expiry_date']),
      isWishlisted: json['is_wishlisted'] as bool? ?? false,
      brandName: ssOpt(json['brand_name']) ?? ssOpt(json['brand']) ?? _extractBrandFallback(ss(json['name'], 'Unknown')),
      brandNameAr: ssOpt(json['brand_name_ar']) ?? _extractBrandFallbackAr(ssOpt(json['name_ar']) ?? ''),
    );
  }

  static String? _extractBrandFallbackAr(String arabicName) {
    if (arabicName.isEmpty) return null;
    final lower = arabicName.toLowerCase();
    if (lower.contains('قو ويل')) return 'قو ويل';
    if (lower.contains('ابلايد') || lower.contains('أبلايد') || lower.contains('نيوتريشن')) return 'أبلايد نيوتريشن';
    if (lower.contains('نانو')) return 'نانو سابس';
    if (lower.contains('فايب') || lower.contains('كولاجين')) return 'فايب';
    if (lower.contains('ماسل تك')) return 'ماسل تك';
    if (lower.contains('ناو')) return 'ناو فودز';
    if (lower.contains('أوبتي')) return 'أوبتيموم نيوترشن';
    return null;
  }

  static String? _extractBrandFallback(String englishName) {
    if (englishName.isEmpty || englishName == 'Unknown') return null;
    final lower = englishName.toLowerCase();
    if (lower.contains('gowell')) return 'GoWell';
    if (lower.contains('abe ') || lower.contains('applied nutrition')) return 'Applied Nutrition';
    if (lower.contains('nano supps') || lower.contains('nano ')) return 'Nano Supps';
    if (lower.contains('vibe') || lower.contains('collagen')) return 'Vibe';
    // generic fallback: first word if it looks like a brand
    final parts = englishName.split(' ');
    if (parts.isNotEmpty && parts[0].length > 1) return parts[0];
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image_url': imageUrl,
    'price': price,
    'original_price': originalPrice,
    'rating': rating,
    'review_count': reviewCount,
    'is_new': isNew,
    'is_available': isAvailable,
    'name_ar': nameAr,
    'stock_warning': stockWarning,
    'points_to_earn': pointsToEarn,
    'is_on_sale': isOnSale,
    'savings': savings,
    'is_bundle': isBundle,
    'is_express_eligible': isExpressEligible,
    'is_featured': isFeatured,
    'category_id': categoryId,
    'has_promotion': hasPromotion,
    'promotion_ends_at': promotionEndsAt,
    'requires_cold_shipping': requiresColdShipping,
    'expiry_date': expiryDate,
    'is_wishlisted': isWishlisted,
    'brand_name': brandName,
    'brand_name_ar': brandNameAr,
  };
}