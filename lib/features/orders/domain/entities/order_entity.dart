// lib/features/orders/domain/entities/order_entity.dart

import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Review sub-entities
// ─────────────────────────────────────────────────────────────────────────────

class StoreReviewEntity extends Equatable {
  final int rating;
  final String? comment;
  final bool isApproved;
  final String? adminReply;

  const StoreReviewEntity({
    required this.rating,
    this.comment,
    required this.isApproved,
    this.adminReply,
  });

  bool get isPending => !isApproved;

  @override
  List<Object?> get props => [rating, comment, isApproved, adminReply];
}

class ShipmentReviewEntity extends Equatable {
  final int rating;
  final String? comment;
  final bool isApproved;
  final String? shippingCompany;
  final String? adminReply;

  const ShipmentReviewEntity({
    required this.rating,
    this.comment,
    required this.isApproved,
    this.shippingCompany,
    this.adminReply,
  });

  bool get isPending => !isApproved;

  @override
  List<Object?> get props =>
      [rating, comment, isApproved, shippingCompany, adminReply];
}

/// The current user's own review of a single ordered item (product).
/// Shown back to the author even while pending approval, with any admin reply.
class ItemReviewEntity extends Equatable {
  final int rating;
  final String? comment;
  final bool isApproved;
  final String? adminReply;

  const ItemReviewEntity({
    required this.rating,
    this.comment,
    required this.isApproved,
    this.adminReply,
  });

  bool get isPending => !isApproved;

  @override
  List<Object?> get props => [rating, comment, isApproved, adminReply];
}

// ─────────────────────────────────────────────────────────────────────────────
// Return sub-entities
// ─────────────────────────────────────────────────────────────────────────────

class OrderReturnItemEntity extends Equatable {
  final String orderItemId;  // links back to order item for filtering
  final String? productName;
  final String? productNameAr;
  final String? imageUrl;
  final int quantity;
  final String? condition;

  const OrderReturnItemEntity({
    required this.orderItemId,
    this.productName,
    this.productNameAr,
    this.imageUrl,
    required this.quantity,
    this.condition,
  });

  @override
  List<Object?> get props => [orderItemId, productName, productNameAr, imageUrl, quantity, condition];
}

class OrderReturnEntity extends Equatable {
  final String id;
  final String status; // requested | approved | rejected | picked_up | refunded | closed
  final String reason;
  final String? notes;
  final String? rejectionReason;
  final double? refundAmount;
  final String? refundMethod;
  final DateTime? createdAt;
  final DateTime? approvedAt;
  final DateTime? refundedAt;
  final List<OrderReturnItemEntity> items;

  // T2.6 — Reverse-shipment fields (from T2.7 API)
  /// 'pickup' | 'dropoff' | 'manual' | null
  final String? returnMethod;
  final String? returnProvider;
  final String? returnTrackingNumber;
  final String? returnWaybillUrl;
  final DateTime? returnPickupBookedAt;

  const OrderReturnEntity({
    required this.id,
    required this.status,
    required this.reason,
    this.notes,
    this.rejectionReason,
    this.refundAmount,
    this.refundMethod,
    this.createdAt,
    this.approvedAt,
    this.refundedAt,
    this.items = const [],
    // Reverse shipment
    this.returnMethod,
    this.returnProvider,
    this.returnTrackingNumber,
    this.returnWaybillUrl,
    this.returnPickupBookedAt,
  });

  @override
  List<Object?> get props => [
    id, status, reason, refundAmount, refundMethod,
    createdAt, approvedAt, refundedAt, items,
    returnMethod, returnProvider, returnTrackingNumber, returnWaybillUrl, returnPickupBookedAt,
  ];
}

class OrderEntity extends Equatable {
  final String id;
  final String orderNumber;
  final DateTime createdAt;
  final double total;         // net charged to gateway/COD (after wallet)
  final double grossTotal;    // pre-wallet full sale value (for display)
  final double walletPaid;    // SAR tendered from wallet (0 if none)
  final String status;
  final List<OrderItemEntity> items;
  final String shippingAddress;
  final String phone;
  final String paymentMethod;
  final double shippingCost;
  final double subtotal;
  // Frozen at order placement (never recalculated afterward) — the single
  // source of truth for VAT display everywhere post-order (order details,
  // invoice). 0 on very old orders placed before these columns existed.
  final double vatRate;
  final double vatAmount;
  final List<OrderTimelineEntity>? timeline;
  final int pointsEarned;
  final int pointsUsed;
  final double pointsDiscount;
  final String? couponCode;
  final double couponDiscount;

  /// Loyalty-tier discount (e.g. أسطورة −5%). Behaves exactly like the coupon
  /// discount: a reduction on goods, already reflected in [total].
  final double tierDiscount;
  final String? notes;
  final String? shipmentStatus;
  final String? shipmentProvider;
  
  // Logistics fields
  final String? deliveryEstimate;
  final String? fulfillmentMode;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final String? driverName;
  final String? driverPhone;
  final double? deliveryLat;
  final double? deliveryLng;
  final double? warehouseLat;
  final double? warehouseLng;
  final List<String>? relatedOrders;
  /// Ids of [relatedOrders], same order. Routing uses these; the chips show the
  /// order_number. Null on older API responses — fall back to not navigating.
  final List<String>? relatedOrderIds;
  // All return requests (newest first). Use returnedItemIds for filtering.
  final List<OrderReturnEntity> returns;
  // Set of order_item_ids that are covered by a non-rejected return.
  final Set<String> returnedItemIds;
  // Cancellation fields
  final String? cancellationReason;
  final DateTime? cancellationRequestedAt;
  // E-23: deadline until which the order can still be cancelled (from backend)
  final DateTime? cancelBefore;
  
  // Invoice
  final bool hasInvoice;

  // Review fields
  final bool storeReviewed;
  final bool shipmentReviewed;
  final StoreReviewEntity? storeReview;
  final ShipmentReviewEntity? shipmentReview;

  // Convenience: the most recent non-rejected return (for quick status checks)
  OrderReturnEntity? get activeReturn =>
      returns.where((r) => r.status != 'rejected').isNotEmpty
          ? returns.firstWhere((r) => r.status != 'rejected')
          : null;

  // True only when ALL items have been returned (hides the request button)
  bool get fullyReturned =>
      items.isNotEmpty &&
      items.every((i) => returnedItemIds.contains(i.id));

  const OrderEntity({
    required this.id,
    required this.orderNumber,
    required this.createdAt,
    required this.total,
    double? grossTotal,
    this.walletPaid = 0.0,
    required this.status,
    required this.items,
    required this.shippingAddress,
    required this.phone,
    required this.paymentMethod,
    required this.shippingCost,
    required this.subtotal,
    this.vatRate = 0.0,
    this.vatAmount = 0.0,
    this.timeline,
    this.pointsEarned = 0,
    this.pointsUsed = 0,
    this.pointsDiscount = 0.0,
    this.couponCode,
    this.couponDiscount = 0.0,
    this.tierDiscount = 0.0,
    this.notes,
    this.shipmentStatus,
    this.shipmentProvider,
    this.deliveryEstimate,
    this.fulfillmentMode,
    this.shippedAt,
    this.deliveredAt,
    this.driverName,
    this.driverPhone,
    this.deliveryLat,
    this.deliveryLng,
    this.warehouseLat,
    this.warehouseLng,
    this.relatedOrders,
    this.relatedOrderIds,
    this.returns = const [],
    this.returnedItemIds = const {},
    this.cancellationReason,
    this.cancellationRequestedAt,
    this.cancelBefore,
    this.hasInvoice = false,
    this.storeReviewed = false,
    this.shipmentReviewed = false,
    this.storeReview,
    this.shipmentReview,
  }) : grossTotal = grossTotal ?? total;

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        createdAt,
        total,
        grossTotal,
        walletPaid,
        status,
        items,
        shippingAddress,
        phone,
        paymentMethod,
        shippingCost,
        subtotal,
        vatRate,
        vatAmount,
        timeline,
        pointsEarned,
        pointsUsed,
        pointsDiscount,
        couponCode,
        couponDiscount,
        tierDiscount,
        notes,
        shipmentStatus,
        shipmentProvider,
        deliveryEstimate,
        fulfillmentMode,
        shippedAt,
        deliveredAt,
        driverName,
        driverPhone,
        deliveryLat,
        deliveryLng,
        warehouseLat,
        warehouseLng,
        relatedOrders,
        relatedOrderIds,
        returns,
        returnedItemIds,
        cancellationReason,
        cancellationRequestedAt,
        cancelBefore,
        hasInvoice,
        storeReviewed,
        shipmentReviewed,
        storeReview,
        shipmentReview,
      ];

  OrderEntity copyWith({
    String? id,
    String? orderNumber,
    DateTime? createdAt,
    double? total,
    double? grossTotal,
    double? walletPaid,
    String? status,
    List<OrderItemEntity>? items,
    String? shippingAddress,
    String? phone,
    String? paymentMethod,
    double? shippingCost,
    double? subtotal,
    double? vatRate,
    double? vatAmount,
    List<OrderTimelineEntity>? timeline,
    int? pointsEarned,
    int? pointsUsed,
    double? pointsDiscount,
    String? couponCode,
    double? couponDiscount,
    String? notes,
    String? shipmentStatus,
    String? shipmentProvider,
    String? deliveryEstimate,
    String? fulfillmentMode,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    String? driverName,
    String? driverPhone,
    double? deliveryLat,
    double? deliveryLng,
    double? warehouseLat,
    double? warehouseLng,
    List<String>? relatedOrders,
    List<String>? relatedOrderIds,
    List<OrderReturnEntity>? returns,
    Set<String>? returnedItemIds,
    String? cancellationReason,
    DateTime? cancellationRequestedAt,
    DateTime? cancelBefore,
    bool? hasInvoice,
    bool? storeReviewed,
    bool? shipmentReviewed,
    StoreReviewEntity? storeReview,
    ShipmentReviewEntity? shipmentReview,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      createdAt: createdAt ?? this.createdAt,
      total: total ?? this.total,
      grossTotal: grossTotal ?? this.grossTotal,
      walletPaid: walletPaid ?? this.walletPaid,
      status: status ?? this.status,
      items: items ?? this.items,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      phone: phone ?? this.phone,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      shippingCost: shippingCost ?? this.shippingCost,
      subtotal: subtotal ?? this.subtotal,
      vatRate: vatRate ?? this.vatRate,
      vatAmount: vatAmount ?? this.vatAmount,
      timeline: timeline ?? this.timeline,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      pointsUsed: pointsUsed ?? this.pointsUsed,
      pointsDiscount: pointsDiscount ?? this.pointsDiscount,
      couponCode: couponCode ?? this.couponCode,
      couponDiscount: couponDiscount ?? this.couponDiscount,
      notes: notes ?? this.notes,
      shipmentStatus: shipmentStatus ?? this.shipmentStatus,
      shipmentProvider: shipmentProvider ?? this.shipmentProvider,
      deliveryEstimate: deliveryEstimate ?? this.deliveryEstimate,
      fulfillmentMode: fulfillmentMode ?? this.fulfillmentMode,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      deliveryLat: deliveryLat ?? this.deliveryLat,
      deliveryLng: deliveryLng ?? this.deliveryLng,
      warehouseLat: warehouseLat ?? this.warehouseLat,
      warehouseLng: warehouseLng ?? this.warehouseLng,
      relatedOrders: relatedOrders ?? this.relatedOrders,
      relatedOrderIds: relatedOrderIds ?? this.relatedOrderIds,
      returns: returns ?? this.returns,
      returnedItemIds: returnedItemIds ?? this.returnedItemIds,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancellationRequestedAt: cancellationRequestedAt ?? this.cancellationRequestedAt,
      cancelBefore: cancelBefore ?? this.cancelBefore,
      hasInvoice: hasInvoice ?? this.hasInvoice,
      storeReviewed: storeReviewed ?? this.storeReviewed,
      shipmentReviewed: shipmentReviewed ?? this.shipmentReviewed,
      storeReview: storeReview ?? this.storeReview,
      shipmentReview: shipmentReview ?? this.shipmentReview,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'orders.status.pending';
      case 'under_review':
        return 'orders.status.under_review';
      case 'pending_payment':
        return 'orders.status.pending_payment';
      case 'payment_unconfirmed':
        return 'orders.status.payment_unconfirmed';
      case 'processing':
        return 'orders.status.processing';
      case 'shipped':
        return 'orders.status.shipped';
      case 'out_for_delivery':
        return 'orders.status.out_for_delivery';
      case 'delivered':
        return 'orders.status.delivered';
      case 'cancelled':
        return 'orders.status.cancelled';
      case 'refunded':
        return 'orders.status.refunded';
      case 'cancellation_requested':
        return 'orders.status.cancellation_requested';
      default:
        return 'orders.status.unknown';
    }
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// True when the order was created for an online/BNPL payment that never
  /// completed — the customer can either retry payment or return to the cart.
  bool get isAwaitingPayment =>
      status == 'pending_payment' || status == 'payment_unconfirmed';
}

class OrderItemEntity extends Equatable {
  final String id;
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;
  final String? nameAr;
  final String? fulfillmentStatus;
  final DateTime? shippedAt;
  final bool reviewed;
  final ItemReviewEntity? review;

  const OrderItemEntity({
    required this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    this.nameAr,
    this.fulfillmentStatus,
    this.shippedAt,
    this.reviewed = false,
    this.review,
  });

  @override
  List<Object?> get props => [
        id, productId, name, imageUrl, price, quantity,
        nameAr, fulfillmentStatus, shippedAt, reviewed, review,
      ];

  double get totalPrice => price * quantity;
}

class OrderTimelineEntity extends Equatable {
  final String status;
  final String title;
  final String description;
  final DateTime? timestamp;
  final bool isCompleted;
  final String? titleAr;
  final String? descriptionAr;

  const OrderTimelineEntity({
    required this.status,
    required this.title,
    required this.description,
    this.timestamp,
    required this.isCompleted,
    this.titleAr,
    this.descriptionAr,
  });

  @override
  List<Object?> get props => [
        status, title, description, timestamp, isCompleted,
        titleAr, descriptionAr,
      ];

  int get stepIndex {
    switch (status) {
      case 'order_placed':
        return 0;
      case 'processing':
        return 1;
      case 'shipped':
        return 2;
      case 'out_for_delivery':
        return 3;
      case 'delivered':
        return 4;
      default:
        return 0;
    }
  }
}
