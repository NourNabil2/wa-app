// lib/features/product_details/domain/entities/product_details_entity.dart

import 'package:equatable/equatable.dart';
import 'package:fastway/features/home/domain/entities/product_entity.dart';

class ProductDetailsEntity extends Equatable {
  final String id, name, imageUrl;
  final String? nameAr;
  final List<String> galleryImages;
  final double price;
  final double? originalPrice, rating;
  final int? reviewCount;
  final bool isNew, isAvailable, isWishlisted;
  final String description;
  final String? descriptionAr;
  final String? brand, category;
  final NutritionFacts? nutritionFacts;
  final List<String> ingredients, benefits;
  final List<String> ingredientsAr, benefitsAr;
  final String usage;
  final String? usageAr;
  final List<ProductReview> reviews;
  final List<ProductEntity> relatedProducts;

  final bool isExpressEligible, isFeatured;
  final String? stockWarning;
  final int? pointsToEarn;
  final double? savings;
  final String? sku, brandId, brandLogoUrl, categoryName, categoryNameAr, subcategoryName, subcategoryNameAr, subcategoryId;
  final List<ProductEntity> brandPicks, alsoBought;

  // 👈 التعديل هنا: هنستخدم الكلاس المخصص للباندل
  final List<BundleComponent> bundleComponents;
  final BundleSavings? bundleSavings;
  final bool isBundle;
  final bool hasPromotion;
  final String? promotionEndsAt;

  final bool requiresColdShipping;
  final String? expiryDate;
  final bool showQuestions;

  // Variant flavors/tastes of this product
  final List<ProductVariant> variants;
  // Admin-defined header for the variant group, e.g. "Flavor", "Size", "Type".
  // Null → caller falls back to the default "Flavor" translation.
  final String? variantGroupLabel;
  final String? variantGroupLabelAr;

  /// The most units of this product the customer may put in their cart —
  /// min(available stock, the product's per-customer limit). The API collapses both
  /// ceilings into this one number (`max_purchasable`), so the stepper only has to
  /// respect a single bound. The cart API enforces exactly the same ceiling, so
  /// exceeding it here would just earn a 422.
  final int maxPurchasable;

  /// The per-customer limit on its own, or null when the product is uncapped.
  /// Only for wording: hitting [maxPurchasable] because of a limit ("limit 3 per
  /// customer") is a different message from hitting it because of stock ("only 3 left").
  final int? maxQtyPerCustomer;

  const ProductDetailsEntity({
    required this.id, required this.name, required this.imageUrl, required this.galleryImages,
    required this.price, this.originalPrice, this.rating, this.reviewCount,
    this.isNew = false, this.isAvailable = true, this.isWishlisted = false, required this.description,
    this.nameAr, this.descriptionAr,
    this.brand, this.category, this.nutritionFacts, required this.ingredients,
    required this.benefits, required this.usage,
    this.ingredientsAr = const [], this.benefitsAr = const [], this.usageAr,
    required this.reviews, required this.relatedProducts,
    this.isExpressEligible = false, this.isFeatured = false, this.stockWarning,
    this.pointsToEarn, this.savings, this.sku, this.brandId, this.brandLogoUrl,
    this.categoryName, this.categoryNameAr, this.subcategoryName, this.subcategoryNameAr, this.subcategoryId,
    this.brandPicks = const [], this.alsoBought = const [],
    this.bundleComponents = const [], this.bundleSavings, this.isBundle = false,
    this.hasPromotion = false, this.promotionEndsAt,
    this.requiresColdShipping = false, this.expiryDate, this.showQuestions = false,
    this.variants = const [], this.variantGroupLabel, this.variantGroupLabelAr,
    this.maxPurchasable = 99, this.maxQtyPerCustomer,
  });

  @override
  List<Object?> get props => [
    id, name, nameAr, imageUrl, galleryImages, price, originalPrice, rating, reviewCount,
    isNew, isAvailable, isWishlisted, description, descriptionAr, brand, category, nutritionFacts,
    ingredients, ingredientsAr, benefits, benefitsAr, usage, usageAr,
    reviews, relatedProducts, isExpressEligible, isFeatured,
    stockWarning, pointsToEarn, savings, sku, brandId, brandLogoUrl,
    categoryName, categoryNameAr, subcategoryName, subcategoryNameAr, subcategoryId,
    brandPicks, alsoBought, bundleComponents, bundleSavings, isBundle,
    hasPromotion, promotionEndsAt, requiresColdShipping, expiryDate, showQuestions,
    variants, variantGroupLabel, variantGroupLabelAr, maxPurchasable, maxQtyPerCustomer,
  ];
}

// ── Product Variant (flavor/taste sibling) ───────────────────────────────────
class ProductVariant extends Equatable {
  final String id;
  final String name;
  final String? nameAr;
  final String? label;    // admin-assigned flavor label e.g. "Cherry"
  final String? labelAr;  // Arabic label e.g. "كرز"
  final String imageUrl;
  final double price;
  final String? sku;
  /// true  = has stock (bright chip)
  /// false = out of stock but admin-enabled (dimmed chip, still navigable)
  /// absent from list = admin-disabled (never shown)
  final bool inStock;

  const ProductVariant({
    required this.id,
    required this.name,
    this.nameAr,
    this.label,
    this.labelAr,
    required this.imageUrl,
    required this.price,
    this.sku,
    this.inStock = true,
  });

  /// Display label: prefer admin label → fall back to product name
  String displayLabel(bool isAr) {
    if (isAr) return labelAr ?? nameAr ?? name;
    return label ?? name;
  }

  @override
  List<Object?> get props => [id, name, nameAr, label, labelAr, imageUrl, price, sku, inStock];
}

class BundleComponent extends Equatable {
  final String productId, productName, imageUrl;
  final String? productNameAr;
  final int quantity;
  const BundleComponent({required this.productId, required this.productName, this.productNameAr, required this.imageUrl, required this.quantity});
  @override List<Object?> get props => [productId, productName, productNameAr, imageUrl, quantity];
}

class BundleSavings extends Equatable {
  final double amount, percent;
  const BundleSavings({required this.amount, required this.percent});
  @override List<Object?> get props => [amount, percent];
}

class NutritionFacts extends Equatable {
  final int calories, protein, carbs, fats, servingSize;
  final String servingUnit;
  const NutritionFacts({required this.calories, required this.protein, required this.carbs, required this.fats, required this.servingSize, required this.servingUnit});
  @override List<Object?> get props => [calories, protein, carbs, fats, servingSize, servingUnit];
}

class ProductReview extends Equatable {
  final String id, userName;
  final String? userImage;
  final double rating;
  final String comment;
  final DateTime date;
  final bool isVerifiedPurchase;
  const ProductReview({required this.id, required this.userName, this.userImage, required this.rating, required this.comment, required this.date, this.isVerifiedPurchase = false});
  @override List<Object?> get props => [id, userName, userImage, rating, comment, date, isVerifiedPurchase];
}

class ProductQuestion extends Equatable {
  final String id;
  final String question;
  final String? answer;
  final String userName;
  final DateTime? answeredAt;
  final DateTime askedAt;
  const ProductQuestion({
    required this.id,
    required this.question,
    this.answer,
    required this.userName,
    this.answeredAt,
    required this.askedAt,
  });
  @override List<Object?> get props => [id, question, answer, userName, answeredAt, askedAt];
}