import '../../domain/entities/wishlist_entity.dart';

class WishlistItemModel extends WishlistItemEntity {
  const WishlistItemModel({
    required super.wishlistItemId,
    required super.productId,
    required super.productName,
    required super.productNameAr,
    super.imageUrl,
    required super.price,
    super.originalPrice,
    required super.isAvailable,
    required super.isWishlisted,
    required super.addedAt,
    super.rating,
    super.reviewCount,
    super.stockWarning,
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>;
    return WishlistItemModel(
      wishlistItemId: json['wishlist_item_id'].toString(),
      productId:      product['id'].toString(),
      productName:    product['name'] ?? '',
      productNameAr:  product['name_ar'] ?? '',
      imageUrl:       product['image_url'],
      price:          (product['effective_price'] ?? product['price'] ?? 0).toDouble(),
      originalPrice:  product['original_price']?.toDouble(),
      isAvailable:    product['is_available'] ?? true,
      isWishlisted:   true,
      addedAt:        DateTime.parse(json['added_at']),
      rating:         product['rating'] != null ? (product['rating'] as num).toDouble() : null,
      reviewCount:    product['review_count'] as int?,
      stockWarning:   product['stock_warning']?.toString(),
    );
  }
}

class WishlistModel extends WishlistEntity {
  const WishlistModel({
    required super.items,
    required super.total,
    required super.count,
  });

  factory WishlistModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>)
        .map((e) => WishlistItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return WishlistModel(
      items: items,
      total: json['total'] ?? items.length,
      count: json['count'] ?? items.length,
    );
  }
}
