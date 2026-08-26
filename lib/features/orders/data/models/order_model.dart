// lib/features/orders/data/models/order_model.dart

import '../../domain/entities/order_entity.dart';

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.orderNumber,
    required super.createdAt,
    required super.total,
    super.grossTotal,       // pre-wallet full sale value (null = same as total)
    super.walletPaid,       // SAR tendered from wallet (default 0.0)
    required super.status,
    required super.items,
    required super.shippingAddress,
    required super.phone,
    required super.paymentMethod,
    required super.shippingCost,
    required super.subtotal,
    super.vatRate = 0.0,
    super.vatAmount = 0.0,
    super.timeline,
    super.pointsEarned = 0,
    super.pointsUsed = 0,
    super.pointsDiscount = 0.0,
    super.couponCode,
    super.couponDiscount = 0.0,
    super.tierDiscount = 0.0,
    super.notes,
    super.shipmentStatus,
    super.shipmentProvider,
    super.deliveryEstimate,
    super.fulfillmentMode,
    super.shippedAt,
    super.deliveredAt,
    super.returns = const [],
    super.returnedItemIds = const {},
    super.driverName,
    super.driverPhone,
    super.deliveryLat,
    super.deliveryLng,
    super.warehouseLat,
    super.warehouseLng,
    super.relatedOrders,
    super.relatedOrderIds,
    super.cancellationReason,
    super.cancellationRequestedAt,
    super.cancelBefore, // E-23
    super.hasInvoice = false,
    super.storeReviewed = false,
    super.shipmentReviewed = false,
    super.storeReview,
    super.shipmentReview,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
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

    // API returns shipping_address as a Map object, not a flat string
    final addressMap = json['shipping_address'];
    final addressStr = addressMap is Map<String, dynamic>
        ? ss(addressMap['full_address'] ?? addressMap['city'])
        : ss(addressMap);

    // phone lives inside shipping_address
    final phone = addressMap is Map<String, dynamic>
        ? ss(addressMap['phone'])
        : ss(json['phone']);

    return OrderModel(
      id: ss(json['id'] ?? json['_id']),
      orderNumber: ss(json['order_number']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      // gross_total = pre-wallet sale value. Falls back to total for old/COD orders.
      grossTotal: (json['gross_total'] as num?)?.toDouble(),
      walletPaid: (json['wallet_paid'] as num?)?.toDouble() ?? 0.0,
      status: ss(json['status'], 'unknown'),
      items: json['items'] != null
          ? (json['items'] as List<dynamic>)
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList()
          : [],
      shippingAddress: addressStr,
      phone: phone,
      paymentMethod: json['payment_method'] is Map
          ? ss(json['payment_method']['name'])
          : ss(json['payment_method']),
      shippingCost: (json['shipping_cost'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      vatRate: (json['vat_rate'] as num?)?.toDouble() ?? 0,
      vatAmount: (json['vat_amount'] as num?)?.toDouble() ?? 0,
      timeline: json['timeline'] != null
          ? (json['timeline'] as List<dynamic>)
          .map((e) => OrderTimelineModel.fromJson(e as Map<String, dynamic>))
          .toList()
          : null,
      pointsEarned: json['total_points_to_earn'] as int? ?? 0,
      pointsUsed: json['points_used'] as int? ?? 0,
      pointsDiscount: (json['points_discount'] as num?)?.toDouble() ?? 0.0,
      couponCode: ssOpt(json['coupon_code']),
      couponDiscount: (json['coupon_discount'] as num?)?.toDouble() ?? 0.0,
      tierDiscount: (json['tier_discount'] as num?)?.toDouble() ?? 0.0,
      notes: ssOpt(json['notes']),
      shipmentStatus: ssOpt(json['shipment_status']),
      shipmentProvider: ssOpt(json['shipment_provider']),
      deliveryEstimate: ssOpt(json['delivery_estimate']),
      fulfillmentMode: ssOpt(json['fulfillment_mode']),
      shippedAt: json['shipped_at'] != null
          ? DateTime.tryParse(json['shipped_at'].toString()) : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'].toString()) : null,
      returns: _parseReturns(json['returns']),
      returnedItemIds: json['returned_item_ids'] != null
          ? Set<String>.from((json['returned_item_ids'] as List<dynamic>).map((e) => e.toString()))
          : const {},
      driverName: json['delivery_assignment'] != null
          ? ssOpt(json['delivery_assignment']['driver_name']) : null,
      driverPhone: json['delivery_assignment'] != null
          ? ssOpt(json['delivery_assignment']['driver_phone']) : null,
      deliveryLat: (json['delivery_lat'] as num?)?.toDouble(),
      deliveryLng: (json['delivery_lng'] as num?)?.toDouble(),
      warehouseLat: (json['warehouse_lat'] as num?)?.toDouble(),
      warehouseLng: (json['warehouse_lng'] as num?)?.toDouble(),
      relatedOrders: json['related_orders'] != null
          ? List<String>.from(json['related_orders']) : null,
      relatedOrderIds: json['related_order_ids'] != null
          ? List<String>.from(
              (json['related_order_ids'] as List).map((e) => e.toString()))
          : null,
      cancellationReason: ssOpt(json['cancellation_reason']),
      cancellationRequestedAt: json['cancellation_requested_at'] != null
          ? DateTime.tryParse(json['cancellation_requested_at'].toString())
          : null,
      // E-23: deadline until which pending order can be self-cancelled
      cancelBefore: json['cancel_before'] != null
          ? DateTime.tryParse(json['cancel_before'].toString())
          : null,
      hasInvoice: json['has_invoice'] as bool? ?? false,
      storeReviewed: json['store_reviewed'] as bool? ?? false,
      shipmentReviewed: json['shipment_reviewed'] as bool? ?? false,
      storeReview: json['store_review'] != null ? StoreReviewModel.fromJson(json['store_review']) : null,
      shipmentReview: json['shipment_review'] != null ? ShipmentReviewModel.fromJson(json['shipment_review']) : null,
    );
  }

  static List<OrderReturnEntity> _parseReturns(dynamic data) {
    if (data == null || data is! List) return [];
    return (data).map((r) => _parseOneReturn(r as Map<String, dynamic>)).toList();
  }

  static OrderReturnEntity _parseOneReturn(Map<String, dynamic> r) {
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
    return OrderReturnEntity(
      id: r['id'].toString(),
      status: ss(r['status'], 'requested'),
      reason: ss(r['reason']),
      notes: ssOpt(r['notes']),
      rejectionReason: ssOpt(r['rejection_reason']),
      refundAmount: (r['refund_amount'] as num?)?.toDouble(),
      refundMethod: ssOpt(r['refund_method']),
      createdAt: r['created_at'] != null
          ? DateTime.tryParse(r['created_at'].toString()) : null,
      approvedAt: r['approved_at'] != null
          ? DateTime.tryParse(r['approved_at'].toString()) : null,
      refundedAt: r['refunded_at'] != null
          ? DateTime.tryParse(r['refunded_at'].toString()) : null,
      items: r['items'] != null
          ? (r['items'] as List<dynamic>).map((i) {
              final item = i as Map<String, dynamic>;
              return OrderReturnItemEntity(
                orderItemId: item['order_item_id']?.toString() ?? '',
                productName: ssOpt(item['product_name']),
                productNameAr: ssOpt(item['product_name_ar']),
                imageUrl: ssOpt(item['image_url']),
                quantity: (item['quantity'] as num?)?.toInt() ?? 1,
                condition: ssOpt(item['condition']),
              );
            }).toList()
          : [],
      // T2.6 — Reverse-shipment fields from T2.7 API
      returnMethod: ssOpt(r['return_method']),
      returnProvider: ssOpt(r['return_provider']),
      returnTrackingNumber: ssOpt(r['return_tracking_number']),
      returnWaybillUrl: ssOpt(r['return_waybill_url']),
      returnPickupBookedAt: r['return_pickup_booked_at'] != null
          ? DateTime.tryParse(r['return_pickup_booked_at'].toString()) : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'created_at': createdAt.toIso8601String(),
      'total': total,
      'status': status,
      'items': items
          .map((e) => e is OrderItemModel ? e.toJson() : OrderItemModel.fromEntity(e).toJson())
          .toList(),
      'shipping_address': shippingAddress,
      'phone': phone,
      'payment_method': paymentMethod,
      'shipping_cost': shippingCost,
      'subtotal': subtotal,
      'timeline': timeline
          ?.map((e) => e is OrderTimelineModel ? e.toJson() : OrderTimelineModel.fromEntity(e).toJson())
          .toList(),
      'total_points_to_earn': pointsEarned,
      'points_used': pointsUsed,
      'points_discount': pointsDiscount,
      'coupon_code': couponCode,
      'coupon_discount': couponDiscount,
      'tier_discount': tierDiscount,
      'notes': notes,
      'shipment_status': shipmentStatus,
      'shipment_provider': shipmentProvider,
      'delivery_estimate': deliveryEstimate,
      'fulfillment_mode': fulfillmentMode,
      'shipped_at': shippedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'return_request': returns.map((r) => r.status).toList(),
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'related_orders': relatedOrders,
      'related_order_ids': relatedOrderIds,
      'store_reviewed': storeReviewed,
      'shipment_reviewed': shipmentReviewed,
      'store_review': storeReview != null ? StoreReviewModel.fromEntity(storeReview!).toJson() : null,
      'shipment_review': shipmentReview != null ? ShipmentReviewModel.fromEntity(shipmentReview!).toJson() : null,
    };
  }

  factory OrderModel.fromEntity(OrderEntity entity) {
    return OrderModel(
      id: entity.id,
      orderNumber: entity.orderNumber,
      createdAt: entity.createdAt,
      total: entity.total,
      status: entity.status,
      items: entity.items,
      shippingAddress: entity.shippingAddress,
      phone: entity.phone,
      paymentMethod: entity.paymentMethod,
      shippingCost: entity.shippingCost,
      subtotal: entity.subtotal,
      timeline: entity.timeline,
      pointsEarned: entity.pointsEarned,
      pointsUsed: entity.pointsUsed,
      pointsDiscount: entity.pointsDiscount,
      couponCode: entity.couponCode,
      couponDiscount: entity.couponDiscount,
      tierDiscount: entity.tierDiscount,
      notes: entity.notes,
      shipmentStatus: entity.shipmentStatus,
      shipmentProvider: entity.shipmentProvider,
      deliveryEstimate: entity.deliveryEstimate,
      fulfillmentMode: entity.fulfillmentMode,
      shippedAt: entity.shippedAt,
      deliveredAt: entity.deliveredAt,
      returns: entity.returns,
      returnedItemIds: entity.returnedItemIds,
      driverName: entity.driverName,
      driverPhone: entity.driverPhone,
      relatedOrders: entity.relatedOrders,
      relatedOrderIds: entity.relatedOrderIds,
      cancellationReason: entity.cancellationReason,
      cancellationRequestedAt: entity.cancellationRequestedAt,
      cancelBefore: entity.cancelBefore, // E-23
      storeReviewed: entity.storeReviewed,
      shipmentReviewed: entity.shipmentReviewed,
      storeReview: entity.storeReview,
      shipmentReview: entity.shipmentReview,
    );
  }

  @override
  OrderModel copyWith({
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
    double? tierDiscount,
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
    return OrderModel(
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
      tierDiscount: tierDiscount ?? this.tierDiscount,
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
}

class OrderItemModel extends OrderItemEntity {
  const OrderItemModel({
    required super.id,
    required super.productId,
    required super.name,
    required super.imageUrl,
    required super.price,
    required super.quantity,
    super.nameAr,
    super.fulfillmentStatus,
    super.shippedAt,
    super.reviewed = false,
    super.review,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    String ss(dynamic v, [String fallback = '']) {
      if (v == null) return fallback;
      if (v is String) return v;
      if (v is Map) return v['en']?.toString() ?? v.values.firstOrNull?.toString() ?? fallback;
      return v.toString();
    }
    return OrderItemModel(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      name: ss(json['name']),
      imageUrl: ss(json['image_url']),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      nameAr: json['name_ar'] != null ? ss(json['name_ar']) : null,
      fulfillmentStatus: json['fulfillment_status']?.toString(),
      shippedAt: json['shipped_at'] != null
          ? DateTime.tryParse(json['shipped_at'].toString()) : null,
      reviewed: json['reviewed'] as bool? ?? false,
      review: json['review'] != null
          ? ItemReviewModel.fromJson(json['review'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'image_url': imageUrl,
      'price': price,
      'quantity': quantity,
      'name_ar': nameAr,
      'fulfillment_status': fulfillmentStatus,
      'shipped_at': shippedAt?.toIso8601String(),
      'reviewed': reviewed,
      'review': review != null
          ? ItemReviewModel.fromEntity(review!).toJson()
          : null,
    };
  }

  factory OrderItemModel.fromEntity(OrderItemEntity entity) {
    return OrderItemModel(
      id: entity.id,
      productId: entity.productId,
      name: entity.name,
      imageUrl: entity.imageUrl,
      price: entity.price,
      quantity: entity.quantity,
      nameAr: entity.nameAr,
      fulfillmentStatus: entity.fulfillmentStatus,
      shippedAt: entity.shippedAt,
      reviewed: entity.reviewed,
      review: entity.review,
    );
  }
}

class OrderTimelineModel extends OrderTimelineEntity {
  const OrderTimelineModel({
    required super.status,
    required super.title,
    required super.description,
    super.timestamp,
    required super.isCompleted,
    super.titleAr,
    super.descriptionAr,
  });

  factory OrderTimelineModel.fromJson(Map<String, dynamic> json) {
    String ss(dynamic v, [String fallback = '']) {
      if (v == null) return fallback;
      if (v is String) return v;
      if (v is Map) return v['en']?.toString() ?? v.values.firstOrNull?.toString() ?? fallback;
      return v.toString();
    }
    return OrderTimelineModel(
      status: ss(json['status']),
      title: ss(json['title']),
      description: ss(json['description']),
      // BUG-30 FIX: API returns occurred_at, not timestamp
      timestamp: json['occurred_at'] != null
          ? DateTime.tryParse(json['occurred_at'].toString())
          : json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp'].toString())
              : null,
      isCompleted: json['is_completed'] as bool? ?? false,
      titleAr: json['title_ar'] != null ? ss(json['title_ar']) : null,
      descriptionAr: json['description_ar'] != null ? ss(json['description_ar']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'title': title,
      'description': description,
      'timestamp': timestamp?.toIso8601String(),
      'is_completed': isCompleted,
      'title_ar': titleAr,
      'description_ar': descriptionAr,
    };
  }

  factory OrderTimelineModel.fromEntity(OrderTimelineEntity entity) {
    return OrderTimelineModel(
      status: entity.status,
      title: entity.title,
      description: entity.description,
      timestamp: entity.timestamp,
      isCompleted: entity.isCompleted,
      titleAr: entity.titleAr,
      descriptionAr: entity.descriptionAr,
    );
  }
}

class StoreReviewModel extends StoreReviewEntity {
  const StoreReviewModel({
    required super.rating,
    super.comment,
    required super.isApproved,
    super.adminReply,
  });

  factory StoreReviewModel.fromJson(Map<String, dynamic> json) {
    return StoreReviewModel(
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString(),
      isApproved: json['is_approved'] as bool? ?? false,
      adminReply: json['admin_reply']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
      'is_approved': isApproved,
      'admin_reply': adminReply,
    };
  }

  factory StoreReviewModel.fromEntity(StoreReviewEntity entity) {
    return StoreReviewModel(
      rating: entity.rating,
      comment: entity.comment,
      isApproved: entity.isApproved,
      adminReply: entity.adminReply,
    );
  }
}

class ShipmentReviewModel extends ShipmentReviewEntity {
  const ShipmentReviewModel({
    required super.rating,
    super.comment,
    required super.isApproved,
    super.shippingCompany,
    super.adminReply,
  });

  factory ShipmentReviewModel.fromJson(Map<String, dynamic> json) {
    return ShipmentReviewModel(
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString(),
      isApproved: json['is_approved'] as bool? ?? false,
      shippingCompany: json['shipping_company']?.toString(),
      adminReply: json['admin_reply']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
      'is_approved': isApproved,
      'shipping_company': shippingCompany,
      'admin_reply': adminReply,
    };
  }

  factory ShipmentReviewModel.fromEntity(ShipmentReviewEntity entity) {
    return ShipmentReviewModel(
      rating: entity.rating,
      comment: entity.comment,
      isApproved: entity.isApproved,
      shippingCompany: entity.shippingCompany,
      adminReply: entity.adminReply,
    );
  }
}

class ItemReviewModel extends ItemReviewEntity {
  const ItemReviewModel({
    required super.rating,
    super.comment,
    required super.isApproved,
    super.adminReply,
  });

  factory ItemReviewModel.fromJson(Map<String, dynamic> json) {
    return ItemReviewModel(
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString(),
      isApproved: json['is_approved'] as bool? ?? false,
      adminReply: json['admin_reply']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
      'is_approved': isApproved,
      'admin_reply': adminReply,
    };
  }

  factory ItemReviewModel.fromEntity(ItemReviewEntity entity) {
    return ItemReviewModel(
      rating: entity.rating,
      comment: entity.comment,
      isApproved: entity.isApproved,
      adminReply: entity.adminReply,
    );
  }
}

