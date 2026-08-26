// lib/features/cart/domain/entities/payment_method_entity.dart

import 'package:equatable/equatable.dart';

enum PaymentProvider { cod, telr, tamara, tabby, unknown }

class PaymentMethodEntity extends Equatable {
  final String id;
  final String name;
  final PaymentProvider provider;
  final String? iconUrl;
  final bool isCod;

  // S4/S5 — Apple Pay gate fields (never null-checks crash; default false/null is safe)
  final bool applePayEnabled;
  final String? appleMerchantId;

  // Client-only marker: true for the synthetic "Apple Pay" tile the checkout
  // screen splits out of the Telr method (same backend id, distinct UI entry).
  // Never comes from the API — lets two tiles share `id` (both are Telr under
  // the hood) while still being distinguishable for tile selection/highlight.
  final bool isApplePayTile;

  const PaymentMethodEntity({
    required this.id,
    required this.name,
    required this.provider,
    this.iconUrl,
    this.isCod = false,
    this.applePayEnabled = false,
    this.appleMerchantId,
    this.isApplePayTile = false,
  });

  @override
  List<Object?> get props => [id, name, provider, iconUrl, isCod, applePayEnabled, appleMerchantId, isApplePayTile];
}