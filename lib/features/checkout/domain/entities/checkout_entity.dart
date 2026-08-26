import 'package:equatable/equatable.dart';
import 'package:fastway/features/checkout/domain/entities/payment_method_entity.dart';
import 'package:fastway/features/checkout/domain/entities/saved_address_entity.dart';

import 'shipping_method_entity.dart';

class CheckoutEntity extends Equatable {
  final List<CheckoutItemEntity> items;
  final double subtotal;
  final double discount;
  final double shippingCost;
  final double total;
  final double? vatAmount;       // VAT extracted from total (VAT-inclusive). From API: vat.amount
  final String? couponCode;
  final double? couponDiscount;

  /// Loyalty-tier discount for this checkout (0 for guests / untiered customers).
  final double? tierDiscount;
  final ShippingMethodEntity? selectedShipping;
  final PaymentMethodEntity? selectedPayment;
  final AddressEntity? selectedAddress;
  final int pointsToEarn;
  final Map<String, dynamic>? pointsInfo;
  /// S7: User's wallet balance at checkout time (null = not authenticated or no wallet).
  final double? walletBalance;
  /// S7: Maximum wallet amount usable on this order — clamped to payable total
  /// (from `wallet.max_usable` in the checkout summary). Distinct from
  /// [walletBalance]: balance is shown in the toggle label; maxUsable is what
  /// actually gets applied when the user toggles wallet on.
  final double? walletMaxUsable;
  final List<CheckoutGroupEntity>? groups;

  const CheckoutEntity({
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.shippingCost,
    required this.total,
    this.vatAmount,
    this.couponCode,
    this.couponDiscount,
    this.tierDiscount,
    this.selectedShipping,
    this.selectedPayment,
    this.selectedAddress,
    this.pointsToEarn = 0,
    this.pointsInfo,
    this.walletBalance,
    this.walletMaxUsable,
    this.groups,
  });

  CheckoutEntity copyWith({
    List<CheckoutItemEntity>? items,
    double? subtotal,
    double? discount,
    double? shippingCost,
    double? total,
    double? vatAmount,
    String? couponCode,
    double? couponDiscount,
    double? tierDiscount,
    ShippingMethodEntity? selectedShipping,
    PaymentMethodEntity? selectedPayment,
    AddressEntity? selectedAddress,
    int? pointsToEarn,
    Map<String, dynamic>? pointsInfo,
    double? walletBalance,
    double? walletMaxUsable,
    List<CheckoutGroupEntity>? groups,
  }) {
    return CheckoutEntity(
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      shippingCost: shippingCost ?? this.shippingCost,
      total: total ?? this.total,
      vatAmount: vatAmount ?? this.vatAmount,
      couponCode: couponCode ?? this.couponCode,
      couponDiscount: couponDiscount ?? this.couponDiscount,
      tierDiscount: tierDiscount ?? this.tierDiscount,
      selectedShipping: selectedShipping ?? this.selectedShipping,
      selectedPayment: selectedPayment ?? this.selectedPayment,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      pointsToEarn: pointsToEarn ?? this.pointsToEarn,
      pointsInfo: pointsInfo ?? this.pointsInfo,
      walletBalance: walletBalance ?? this.walletBalance,
      walletMaxUsable: walletMaxUsable ?? this.walletMaxUsable,
      groups: groups ?? this.groups,
    );
  }

  @override
  List<Object?> get props => [
        items,
        subtotal,
        discount,
        shippingCost,
        total,
        vatAmount,
        couponCode,
        couponDiscount,
        tierDiscount,
        selectedShipping,
        selectedPayment,
        selectedAddress,
        pointsToEarn,
        pointsInfo,
        walletBalance,
        walletMaxUsable,
        groups,
      ];
}

class CheckoutItemEntity extends Equatable {
  final String id;
  /// The actual product ID — used for navigating to the product detail page.
  final String? productId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;
  final String? stockWarning;
  /// Whether this cart item was toggled to express by the user
  final bool isExpress;
  /// Whether the product is eligible for express (from product.is_express_eligible)
  final bool isExpressEligible;

  const CheckoutItemEntity({
    required this.id,
    this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    this.stockWarning,
    this.isExpress = false,
    this.isExpressEligible = false,
  });

  double get totalPrice => price * quantity;

  @override
  List<Object?> get props => [id, productId, name, imageUrl, price, quantity, stockWarning, isExpress, isExpressEligible];
}

class CheckoutGroupEntity extends Equatable {
  final String id;
  final String storeId;
  final String storeName;
  final String label;    // e.g. '⚡ Express Delivery'
  final String labelAr;  // e.g. '⚡ توصيل سريع'
  final List<CheckoutItemEntity> items;
  final ShippingMethodEntity? selectedShipping;
  final List<ShippingMethodEntity>? availableShippingMethods;
  final bool isExpressGroup;
  final bool hasColdItems;

  const CheckoutGroupEntity({
    required this.id,
    required this.storeId,
    required this.storeName,
    this.label = '',
    this.labelAr = '',
    required this.items,
    this.selectedShipping,
    this.availableShippingMethods,
    this.isExpressGroup = false,
    this.hasColdItems = false,
  });

  CheckoutGroupEntity copyWith({
    String? id,
    String? storeId,
    String? storeName,
    String? label,
    String? labelAr,
    List<CheckoutItemEntity>? items,
    ShippingMethodEntity? selectedShipping,
    List<ShippingMethodEntity>? availableShippingMethods,
    bool? isExpressGroup,
    bool? hasColdItems,
  }) {
    return CheckoutGroupEntity(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      label: label ?? this.label,
      labelAr: labelAr ?? this.labelAr,
      items: items ?? this.items,
      selectedShipping: selectedShipping ?? this.selectedShipping,
      availableShippingMethods: availableShippingMethods ?? this.availableShippingMethods,
      isExpressGroup: isExpressGroup ?? this.isExpressGroup,
      hasColdItems: hasColdItems ?? this.hasColdItems,
    );
  }

  @override
  List<Object?> get props => [id, storeId, storeName, label, labelAr, items, selectedShipping, availableShippingMethods, isExpressGroup, hasColdItems];
}


