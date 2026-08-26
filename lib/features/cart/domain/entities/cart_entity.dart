// lib/features/cart/domain/entities/cart_entity.dart

import 'package:equatable/equatable.dart';
import '../../../home/domain/entities/product_entity.dart';

class CartEntity extends Equatable {
  final List<CartItemEntity> items;
  final double subtotal;
  final double discount;
  final double shippingCost;
  final double total;
  final String? couponCode;
  final double? couponDiscount;

  /// Loyalty-tier discount for this cart (null/0 for guests and untiered customers).
  final double? tierDiscount;

  /// Extra points percentage this customer's tier grants (e.g. 10 for +10%).
  /// Labels the points bar — the points figure itself already includes it.
  final double? tierBonusPercent;
  final double totalSavings;
  final String? savingsMessage;
  final List<ProductEntity>? suggestions;

  // 👈 المتغيرات الجديدة اللي انضافت في الباك إند
  final int pointsEarned;
  final int? pointsUsed;
  final double? pointsDiscount;
  final bool coldRecommendation;

  const CartEntity({
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.shippingCost,
    required this.total,
    this.couponCode,
    this.couponDiscount,
    this.tierDiscount,
    this.tierBonusPercent,
    this.totalSavings = 0.0,
    this.savingsMessage,
    this.suggestions,
    this.pointsEarned = 0,
    this.pointsUsed,
    this.pointsDiscount,
    this.coldRecommendation = false,
  });

  CartEntity copyWith({
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
  }) {
    return CartEntity(
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      shippingCost: shippingCost ?? this.shippingCost,
      total: total ?? this.total,
      couponCode: couponCode ?? this.couponCode,
      couponDiscount: couponDiscount ?? this.couponDiscount,
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

  @override
  List<Object?> get props => [
    items,
    subtotal,
    discount,
    shippingCost,
    total,
    couponCode,
    couponDiscount,
    tierDiscount,
    tierBonusPercent,
    totalSavings,
    savingsMessage,
    suggestions,
    pointsEarned,
    pointsUsed,
    pointsDiscount,
    coldRecommendation,
  ];
}

class CartItemEntity extends Equatable {
  final String id;
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final double? originalPrice;
  final int quantity;
  final int maxQuantity;
  final bool isAvailable;
  final String? stockWarning;
  final bool isOnSale;
  final double savings;
  final String? nameAr;
  final String? brandName;
  final String? brandNameAr;
  final bool isExpress;
  final bool isExpressEligible;
  final bool requiresColdShipping; // GAP-41

  /// Granted by an automatic cart offer (buy 1 get 1, free gift over an amount).
  ///
  /// A gift is an ordinary line the server prices at 0 — it ships, it deducts
  /// stock, it appears on the invoice. Its quantity is derived from the offer,
  /// so the UI must not offer a stepper: editing it would only be corrected on
  /// the next cart change.
  final bool isGift;

  /// Customer-facing name of the offer that granted this line, e.g. "Buy 1 Get 1".
  final String? giftLabel;
  final String? giftLabelAr;

  /// Returns the localized product name based on the given locale code.
  String localizedName(String locale) =>
      (locale == 'ar' && nameAr != null && nameAr!.isNotEmpty) ? nameAr! : name;

  /// Returns the localized brand name based on the given locale code.
  String? localizedBrandName(String locale) =>
      (locale == 'ar' && brandNameAr != null && brandNameAr!.isNotEmpty) ? brandNameAr : brandName;

  const CartItemEntity({
    required this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.originalPrice,
    required this.quantity,
    this.maxQuantity = 10,
    this.isAvailable = true,
    this.stockWarning,
    this.isOnSale = false,
    this.savings = 0.0,
    this.nameAr,
    this.brandName,
    this.brandNameAr,
    this.isExpress = false,
    this.isExpressEligible = false,
    this.requiresColdShipping = false,
    this.isGift = false,
    this.giftLabel,
    this.giftLabelAr,
  });

  /// Localised offer name, matching how the product name is localised above.
  String? localizedGiftLabel(String locale) =>
      (locale == 'ar' && giftLabelAr != null && giftLabelAr!.isNotEmpty)
          ? giftLabelAr
          : giftLabel;

  double get totalPrice => price * quantity;
  double? get discountAmount => originalPrice != null
      ? (originalPrice! - price) * quantity
      : null;

  CartItemEntity copyWith({
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
    bool? requiresColdShipping,
    bool? isGift,
    String? giftLabel,
    String? giftLabelAr,
  }) {
    return CartItemEntity(
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
      requiresColdShipping: requiresColdShipping ?? this.requiresColdShipping,
      isGift: isGift ?? this.isGift,
      giftLabel: giftLabel ?? this.giftLabel,
      giftLabelAr: giftLabelAr ?? this.giftLabelAr,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    name,
    imageUrl,
    price,
    originalPrice,
    quantity,
    maxQuantity,
    isAvailable,
    stockWarning,
    isOnSale,
    savings,
    nameAr,
    brandName,
    brandNameAr,
    isExpress,
    isExpressEligible,
    requiresColdShipping,
    isGift,
    giftLabel,
    giftLabelAr,
  ];
}