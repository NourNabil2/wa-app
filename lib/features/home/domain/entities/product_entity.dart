import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final double? originalPrice;
  final double? rating;
  final int? reviewCount;
  final bool isNew;
  final bool isAvailable;
  final String? nameAr;

  /// Returns the localized product name based on the given locale code.
  /// Falls back to the English [name] if [nameAr] is null or empty.
  String localizedName(String locale) =>
      (locale == 'ar' && nameAr != null && nameAr!.isNotEmpty) ? nameAr! : name;

  /// Returns the localized brand name based on the given locale code.
  /// Falls back to the English [brandName] if [brandNameAr] is null or empty.
  String? localizedBrandName(String locale) =>
      (locale == 'ar' && brandNameAr != null && brandNameAr!.isNotEmpty) ? brandNameAr : brandName;

  final String? stockWarning;
  final int pointsToEarn;
  final bool isOnSale;
  final double savings;
  final bool isBundle;
  final bool isExpressEligible;
  final bool isFeatured;
  final String? categoryId;
  final bool hasPromotion;
  final String? promotionEndsAt;
  final bool requiresColdShipping;
  final String? expiryDate;
  final bool isWishlisted;
  final String? brandName;
  final String? brandNameAr;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.originalPrice,
    this.rating,
    this.reviewCount,
    this.isNew = false,
    this.isAvailable = true,
    this.nameAr,
    this.stockWarning,
    this.pointsToEarn = 0,
    this.isOnSale = false,
    this.savings = 0.0,
    this.isBundle = false,
    this.isExpressEligible = false,
    this.isFeatured = false,
    this.categoryId,
    this.hasPromotion = false,
    this.promotionEndsAt,
    this.requiresColdShipping = false,
    this.expiryDate,
    this.isWishlisted = false,
    this.brandName,
    this.brandNameAr,
  });

  @override
  List<Object?> get props => [
    id, name, imageUrl, price, originalPrice,
    rating, reviewCount, isNew, isAvailable,
    nameAr, stockWarning, pointsToEarn, isOnSale, savings,
    isBundle, isExpressEligible, isFeatured, categoryId,
    hasPromotion, promotionEndsAt, requiresColdShipping, expiryDate, isWishlisted, brandName, brandNameAr,
  ];
}