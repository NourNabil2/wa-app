// lib/features/product_details/data/models/product_details_model.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/features/home/data/model/product_model.dart';
import 'package:fastway/features/home/domain/entities/product_entity.dart';
import 'package:fastway/features/product_details/domain/entities/product_details_entity.dart';

/// Safely convert any JSON numeric-ish value to [int].
int? _safeInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt();
  return null;
}

class ProductDetailsModel extends ProductDetailsEntity {
  const ProductDetailsModel({
    required super.id, required super.name, required super.imageUrl, required super.galleryImages,
    required super.price, super.originalPrice, super.rating, super.reviewCount, super.isNew,
    super.isAvailable, super.isWishlisted, required super.description, super.nameAr, super.descriptionAr,
    super.brand, super.category, super.nutritionFacts, super.brandLogoUrl,
    required super.ingredients, required super.benefits, required super.usage,
    super.ingredientsAr, super.benefitsAr, super.usageAr,
    required super.reviews,
    required super.relatedProducts, super.isExpressEligible, super.isFeatured, super.stockWarning,
    super.pointsToEarn, super.savings, super.sku, super.brandId,
    super.categoryName, super.categoryNameAr, super.subcategoryName, super.subcategoryNameAr,
    super.subcategoryId, super.brandPicks, super.alsoBought, super.bundleComponents,
    super.bundleSavings, super.isBundle, super.hasPromotion, super.promotionEndsAt,
    super.requiresColdShipping, super.expiryDate, super.showQuestions,
    super.variants, super.variantGroupLabel, super.variantGroupLabelAr,
    super.maxPurchasable, super.maxQtyPerCustomer,
  });

  factory ProductDetailsModel.fromJson(Map<String, dynamic> json) {
    // Safely coerce a JSON field to String — guards against localised Map values.
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
    final isAvailable = apiIsAvailable && stock > 0;

    final rawGallery = json['gallery'] as List<dynamic>? ?? [];
    final galleryImages = rawGallery.map((e) => e.toString()).where((url) => url.isNotEmpty).toList();
    if (galleryImages.isEmpty) {
      final mainImage = ss(json['image_url']);
      if (mainImage.isNotEmpty) galleryImages.add(mainImage);
    }

    List<String> parseStringList(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    NutritionFacts? nutritionFacts;
    final rawNutrition = json['nutrition_facts'];
    if (rawNutrition != null && rawNutrition is Map<String, dynamic>) {
      nutritionFacts = NutritionFacts(
        calories: (rawNutrition['calories'] as num? ?? 0).toInt(),
        protein: (rawNutrition['protein'] as num? ?? 0).toInt(),
        carbs: (rawNutrition['carbs'] as num? ?? 0).toInt(),
        fats: (rawNutrition['fats'] as num? ?? 0).toInt(),
        servingSize: (rawNutrition['serving_size'] as num? ?? 0).toInt(),
        servingUnit: ss(rawNutrition['serving_unit'], 'g'),
      );
    }

    final reviews = (json['reviews'] as List<dynamic>? ?? []).map((r) {
      final map = r as Map<String, dynamic>;
      return ProductReview(
        id: map['id'].toString(),
        userName: ss(map['user_name'], 'product.user'.tr()),
        userImage: ssOpt(map['user_image']),
        rating: (map['rating'] as num? ?? 0).toDouble(),
        comment: ss(map['comment']),
        date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
        isVerifiedPurchase: map['is_verified_purchase'] as bool? ?? false,
      );
    }).toList();

    List<ProductEntity> parseProductList(String key) {
      final raw = json[key] as List<dynamic>? ?? [];
      return raw.map((r) => ProductModel.fromJson(r as Map<String, dynamic>)).toList();
    }

    // 👈 الحل الجذري للإيرور بتاعك:
    final bundleComponents = (json['bundle_components'] as List<dynamic>? ?? []).map((c) {
      final map = c as Map<String, dynamic>;
      return BundleComponent(
        productId: map['product_id']?.toString() ?? '',
        productName: ss(map['product_name'], 'product.product'.tr()),
        productNameAr: ssOpt(map['product_name_ar']),
        imageUrl: ss(map['image_url']),
        quantity: _safeInt(map['quantity']) ?? 1,
      );
    }).toList();

    BundleSavings? bundleSavings;
    if (json['bundle_savings'] != null && json['bundle_savings'] is Map) {
      bundleSavings = BundleSavings(
        amount: (json['bundle_savings']['amount'] as num? ?? 0).toDouble(),
        percent: (json['bundle_savings']['percent'] as num? ?? 0).toDouble(),
      );
    }

    // Parse variants (flavor siblings)
    final variants = (json['variants'] as List<dynamic>? ?? []).map((v) {
      final map = v as Map<String, dynamic>;
      return ProductVariant(
        id: map['id'].toString(),
        name: ss(map['name'], 'Variant'),
        nameAr: ssOpt(map['name_ar']),
        label: ssOpt(map['label']),
        labelAr: ssOpt(map['label_ar']),
        imageUrl: ss(map['image_url']),
        price: (map['price'] as num? ?? 0).toDouble(),
        sku: map['sku']?.toString(),
        inStock: map['in_stock'] as bool? ?? true,
      );
    }).toList();

    return ProductDetailsModel(
      id: json['id'].toString(),
      name: ss(json['name'], 'No Name'),
      nameAr: ssOpt(json['name_ar']),
      imageUrl: ss(json['image_url']),
      galleryImages: galleryImages,
      price: (json['price'] as num? ?? 0).toDouble(),
      originalPrice: json['original_price'] != null
          ? (json['original_price'] as num?)?.toDouble() : null,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      reviewCount: _safeInt(json['review_count']),
      isNew: json['is_new'] as bool? ?? false,
      isAvailable: isAvailable,
      isWishlisted: json['is_wishlisted'] as bool? ?? false,
      isExpressEligible: json['is_express_eligible'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      stockWarning: ssOpt(json['stock_warning']),
      pointsToEarn: _safeInt(json['points_to_earn']),
      savings: (json['savings'] as num?)?.toDouble(),
      description: ss(json['description']),
      descriptionAr: ssOpt(json['description_ar']),
      brand: ssOpt(json['brand']),
      brandLogoUrl: ssOpt(json['brand_logo_url']),
      brandId: json['brand_id']?.toString(),
      category: json['category_id']?.toString(),
      categoryName: ssOpt(json['category_name']),
      categoryNameAr: ssOpt(json['category_name_ar']),
      subcategoryId: json['subcategory_id']?.toString(),
      subcategoryName: ssOpt(json['subcategory_name']),
      subcategoryNameAr: ssOpt(json['subcategory_name_ar']),
      nutritionFacts: nutritionFacts,
      ingredients: parseStringList(json['ingredients']),
      ingredientsAr: parseStringList(json['ingredients_ar']),
      benefits: parseStringList(json['benefits']),
      benefitsAr: parseStringList(json['benefits_ar']),
      usage: ss(json['usage']),
      usageAr: ssOpt(json['usage_ar']),
      reviews: reviews,
      relatedProducts: parseProductList('related_products'),
      alsoBought: parseProductList('also_bought'),
      brandPicks: parseProductList('brand_picks'),
      bundleComponents: bundleComponents,
      bundleSavings: bundleSavings,
      isBundle: json['is_bundle'] as bool? ?? false,
      sku: json['sku']?.toString(),
      hasPromotion: json['has_promotion'] as bool? ?? false,
      promotionEndsAt: ssOpt(json['promotion_ends_at']),
      requiresColdShipping: json['requires_cold_shipping'] as bool? ?? false,
      expiryDate: ssOpt(json['expiry_date']),
      showQuestions: json['show_questions'] as bool? ?? false,
      variants: variants,
      variantGroupLabel: ssOpt(json['variant_group_label']),
      variantGroupLabelAr: ssOpt(json['variant_group_label_ar']),
      // The API collapses stock and the per-customer limit into max_purchasable.
      // Fall back to `stock` (an older API build won't send it), and never fall back
      // to 0 — a missing field must not make the product look unbuyable. isAvailable
      // above already decides that, from `stock` and `is_available`.
      maxPurchasable: _safeInt(json['max_purchasable']) ?? (stock > 0 ? stock : 99),
      maxQtyPerCustomer: _safeInt(json['max_qty_per_customer']),
    );
  }
}