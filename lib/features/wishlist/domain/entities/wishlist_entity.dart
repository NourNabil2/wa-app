import 'package:equatable/equatable.dart';

class WishlistItemEntity extends Equatable {
  final String wishlistItemId;
  final String productId;
  final String productName;
  final String productNameAr;
  final String? imageUrl;
  final double price;
  final double? originalPrice;
  final bool isAvailable;
  final bool isWishlisted;
  final DateTime addedAt;
  // Optional enrichment fields (populated when available from API)
  final double? rating;
  final int? reviewCount;
  final String? stockWarning;

  const WishlistItemEntity({
    required this.wishlistItemId,
    required this.productId,
    required this.productName,
    required this.productNameAr,
    this.imageUrl,
    required this.price,
    this.originalPrice,
    required this.isAvailable,
    required this.isWishlisted,
    required this.addedAt,
    this.rating,
    this.reviewCount,
    this.stockWarning,
  });

  @override
  List<Object?> get props => [wishlistItemId, productId, isAvailable];
}

class WishlistEntity extends Equatable {
  final List<WishlistItemEntity> items;
  final int total;
  final int count;

  const WishlistEntity({
    required this.items,
    required this.total,
    required this.count,
  });

  /// Creates a copy with a new productId added as a minimal placeholder entry.
  /// Used by WishlistCubit to keep the local cache in sync after an optimistic add.
  WishlistEntity copyWithAdded(String productId) {
    // Only add a placeholder if it doesn't already exist.
    if (items.any((i) => i.productId == productId)) return this;
    final placeholder = WishlistItemEntity(
      wishlistItemId: '__optimistic__$productId',
      productId: productId,
      productName: '',
      productNameAr: '',
      price: 0,
      isAvailable: true,
      isWishlisted: true,
      addedAt: DateTime.now(),
    );
    return WishlistEntity(
      items: [placeholder, ...items],
      total: total + 1,
      count: count + 1,
    );
  }

  /// Creates a copy with the item matching [productId] removed.
  WishlistEntity copyWithRemoved(String productId) {
    final filtered = items.where((i) => i.productId != productId).toList();
    return WishlistEntity(
      items: filtered,
      total: (total - 1).clamp(0, total),
      count: (count - 1).clamp(0, count),
    );
  }

  @override
  List<Object?> get props => [items, total, count];
}
