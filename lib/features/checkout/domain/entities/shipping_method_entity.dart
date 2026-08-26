// lib/features/checkout/domain/entities/shipping_method_entity.dart

import 'package:equatable/equatable.dart';

class ShippingMethodEntity extends Equatable {
  final String id;
  final String name;
  final String nameAr;
  final String description;
  final double cost;
  /// Real price before free-shipping threshold discount.
  /// When isFree=true due to threshold, cost=0 but originalCost = the actual rate.
  final double originalCost;

  /// Admin-written delivery statement (shipping method → "Delivery Statement"), shown
  /// under the selected method at checkout. Never auto-calculated — blank when the admin
  /// left it blank. [estimatedTimeAr] is its Arabic twin; pick by locale.
  final String estimatedTime;
  final String estimatedTimeAr;
  final bool isFree;
  final String provider;
  final String type;
  final bool isCodSupported;
  final String? iconUrl;
  final bool supportsColdChain;

  /// true when the backend marks this method as locked for this group
  /// (e.g. express row when no express products are in cart)
  final bool isDisabled;

  /// true when the backend pre-selects this method as default
  final bool isSelected;

  const ShippingMethodEntity({
    required this.id,
    required this.name,
    this.nameAr = '',
    required this.description,
    required this.cost,
    double? originalCost,
    required this.estimatedTime,
    this.estimatedTimeAr = '',
    this.isFree = false,
    this.provider = 'manual',
    this.type = 'standard',
    this.isCodSupported = false,
    this.iconUrl,
    this.supportsColdChain = true,
    this.isDisabled = false,
    this.isSelected = false,
  }) : originalCost = originalCost ?? cost;

  bool get isExpressMethod => provider.toLowerCase() == 'express';

  @override
  List<Object?> get props => [
        id, name, nameAr, description, cost, originalCost, estimatedTime, estimatedTimeAr,
        isFree, provider, type, isCodSupported, iconUrl, supportsColdChain,
        isDisabled, isSelected,
      ];
}