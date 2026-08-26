// lib/features/checkout/presentation/cubit/checkout_cubit.dart
import 'dart:convert';
import '../../domain/entities/checkout_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telr_mobile_payment_sdk/telr_mobile_payment_sdk.dart'
    if (dart.library.html) 'telr_stub.dart';
import '../../../../core/api/model/endpoints.dart';
import '../../../../core/platform/native_sheet.dart';
import '../../../../core/utils/app_constans.dart';
import 'web_apple_pay.dart';
import '../../../../core/cubit/delivery_location/delivery_location_cubit.dart';
import '../../../../core/cubit/delivery_location/delivery_location_state.dart';
import '../../../profile/domain/usecases/get_addresses_usecase.dart';
import '../../../user_data/auth_guard.dart';
import '../../../user_data/user_repo.dart';
import '../../domain/entities/payment_method_entity.dart';
import '../../domain/entities/place_order_result.dart';
import '../../domain/entities/saved_address_entity.dart';
import '../../domain/entities/shipping_method_entity.dart';
import '../../domain/usecases/get_checkout_data_usecase.dart';
import '../../domain/usecases/get_cities_usecase.dart';
import '../../domain/usecases/get_payment_methods_usecase.dart';
import '../../domain/usecases/get_shipping_methods_usecase.dart';
import '../../domain/usecases/place_order_usecase.dart';
import '../../domain/usecases/get_delivery_slots_usecase.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../../../cart/domain/usecases/apply_coupon_usecase.dart';
import '../../../cart/domain/usecases/remove_coupon_usecase.dart';
import 'checkout_state.dart';

/// Safely coerces a JSON value to String.
/// Handles Map (localised) values like {"en": "...", "ar": "..."} gracefully.
String _s(dynamic v, [String fallback = '']) {
  if (v == null) return fallback;
  if (v is String) return v;
  if (v is Map) return v['en']?.toString() ?? v.values.firstOrNull?.toString() ?? fallback;
  return v.toString();
}

class CheckoutCubit extends Cubit<CheckoutState> {
  final GetCheckoutDataUseCase _getCheckoutDataUseCase;
  final GetShippingMethodsUseCase _getShippingMethodsUseCase;
  final GetPaymentMethodsUseCase _getPaymentMethodsUseCase;
  final GetCitiesUseCase _getCitiesUseCase;
  final GetCountriesUseCase _getCountriesUseCase;
  final PlaceOrderUseCase _placeOrderUseCase;
  final GetAddressesUseCase _getAddressesUseCase;
  final GetDeliverySlotsUseCase _getDeliverySlotsUseCase;
  final CheckoutRepository _checkoutRepository;
  final DeliveryLocationCubit _locationCubit;
  final ApplyCouponUseCase _applyCouponUseCase;
  final RemoveCouponUseCase _removeCouponUseCase;

  /// Tracks the gateway used in the most recent initiation attempt so that
  /// retryPayment() can pass the same provider back to the WebView.
  PaymentProvider _lastProvider = PaymentProvider.telr;

  CheckoutLoaded? _lastLoadedState;

  /// Guest cart id (X-Session-ID), preloaded during loadCheckout so the WEB
  /// Apple Pay tap handler can build its config synchronously (Safari needs the
  /// ApplePaySession created inside the gesture — no awaits before it).
  String? _webSessionId;

  @override
  void emit(CheckoutState state) {
    if (state is CheckoutLoaded) {
      _lastLoadedState = state;
    }
    super.emit(state);
  }

  void restoreLoadedState() {
    if (_lastLoadedState != null && state is! CheckoutLoaded && !isClosed) {
      emit(_lastLoadedState!);
    }
  }

  CheckoutCubit({
    required GetCheckoutDataUseCase getCheckoutDataUseCase,
    required GetShippingMethodsUseCase getShippingMethodsUseCase,
    required GetPaymentMethodsUseCase getPaymentMethodsUseCase,
    required GetCitiesUseCase getCitiesUseCase,
    required GetCountriesUseCase getCountriesUseCase,
    required PlaceOrderUseCase placeOrderUseCase,
    required GetAddressesUseCase getAddressesUseCase,
    required GetDeliverySlotsUseCase getDeliverySlotsUseCase,
    required CheckoutRepository checkoutRepository,
    required DeliveryLocationCubit locationCubit,
    required ApplyCouponUseCase applyCouponUseCase,
    required RemoveCouponUseCase removeCouponUseCase,
  })  : _getCheckoutDataUseCase = getCheckoutDataUseCase,
        _getShippingMethodsUseCase = getShippingMethodsUseCase,
        _getPaymentMethodsUseCase = getPaymentMethodsUseCase,
        _getCitiesUseCase = getCitiesUseCase,
        _getCountriesUseCase = getCountriesUseCase,
        _placeOrderUseCase = placeOrderUseCase,
        _getAddressesUseCase = getAddressesUseCase,
        _getDeliverySlotsUseCase = getDeliverySlotsUseCase,
        _checkoutRepository = checkoutRepository,
        _locationCubit = locationCubit,
        _applyCouponUseCase = applyCouponUseCase,
        _removeCouponUseCase = removeCouponUseCase,
        super(CheckoutInitial());

  /// Reads the current delivery address coordinates from the global
  /// DeliveryLocationCubit — the single source of truth for location.
  ({double? lat, double? lng}) get _coords {
    final locState = _locationCubit.state;
    if (locState is DeliveryLocationResolved) {
      return (lat: locState.lat, lng: locState.lng);
    }
    return (lat: null, lng: null);
  }

  // ─── Load ────────────────────────────────────────────────────────────────

  Future<void> loadCheckout() async {
    emit(CheckoutLoading());
    // Preload the guest session id so a WEB Apple Pay tap can build its config
    // synchronously (best-effort; harmless if it fails or the user is logged in).
    try {
      _webSessionId =
          (await SharedPreferences.getInstance()).getString(AppConstants.sessionKey);
    } catch (_) {/* ignore — logged-in users don't need it */}
    // Read coordinates once from the global DeliveryLocationCubit
    final c = _coords;

    // Fire all independent fetches in parallel
    final checkoutFuture      = _getCheckoutDataUseCase();
    final shippingFuture      = _getShippingMethodsUseCase();
    final paymentFuture       = _getPaymentMethodsUseCase();
    final citiesFuture        = _getCitiesUseCase();
    final countriesFuture     = _getCountriesUseCase();
    final deliverySlotsFuture = _getDeliverySlotsUseCase();

    final checkout      = await checkoutFuture;
    final shipping      = await shippingFuture;
    final payment       = await paymentFuture;
    final cities        = await citiesFuture;
    final countries     = await countriesFuture;
    final deliverySlots = await deliverySlotsFuture;

    for (final r in [checkout, shipping, payment, cities, countries, deliverySlots]) {
      final failure = r.fold((f) => f, (_) => null);
      if (failure != null) { emit(CheckoutError(failure)); return; }
    }

    // Load addresses; use the DeliveryLocationCubit's selected address as default
    final isLoggedIn = UserRepository().currentUser != null;
    List<AddressEntity> addressList = [];
    AddressEntity? defaultAddress;
    final locState = _locationCubit.state;
    if (locState is DeliveryLocationResolved) {
      defaultAddress = locState.selectedAddress;
    }

    if (isLoggedIn) {
      final addressesResult = await _getAddressesUseCase();
      addressesResult.fold(
        (_) => addressList = [],
        (list) {
          addressList = List<AddressEntity>.from(list);
          if (addressList.isEmpty) return;

          // Always prefer the address book's current isDefault. This runs once at
          // the start of loadCheckout() — before the customer has made any
          // in-checkout address choice (see selectAddress(), a separate later
          // action) — so DeliveryLocationCubit's cached selectedAddress here is
          // never an intentional pick, only possibly-stale app state (e.g. right
          // after "Set as Default" was changed elsewhere in the app).
          defaultAddress = addressList.firstWhere(
            (a) => a.isDefault,
            orElse: () => addressList.first,
          );
        },
      );
    }

    // Fetch checkout groups from backend using delivery location coords.
    // Prefer the selected address's own coordinates (now correctly parsed) over
    // the location cubit's GPS coords which may not be available yet.
    List<Map<String, dynamic>> rawGroups = [];
    List<CheckoutGroupEntity> parsedGroups = [];
    Map<String, dynamic>? pointsInfo;
    double? walletBalance;
    double? walletMaxUsable;
    bool nationalAddressMandatory = false;

    final double? summaryLat = defaultAddress?.lat ?? c.lat;
    final double? summaryLng = defaultAddress?.lng ?? c.lng;
    final summaryResult = await _checkoutRepository.getCheckoutSummary(lat: summaryLat, lng: summaryLng);
    bool summaryFailed = false;
    summaryResult.fold(
      (failure) {
        // The most common cause is an empty cart (422). Surface it clearly.
        summaryFailed = true;
        emit(CheckoutError(failure));
      },
      (data) {
        final groupsList = (data['groups'] as List<dynamic>?) ?? [];
        rawGroups = groupsList.map((g) => g as Map<String, dynamic>).toList();
        pointsInfo = data['points'] as Map<String, dynamic>?;
        walletBalance = (data['wallet_balance'] as num?)?.toDouble();
        // wallet.max_usable = backend-clamped amount (≤ cart total). Distinct
        // from walletBalance (raw balance shown in the toggle label).
        final walletInfo = data['wallet'] as Map<String, dynamic>?;
        walletMaxUsable = (walletInfo?['max_usable'] as num?)?.toDouble();
        nationalAddressMandatory = data['national_address_mandatory'] as bool? ?? false;

        parsedGroups = rawGroups.map((g) {
          final gId = g['group_id']?.toString() ?? '1';
          final parsedMethods = (g['available_shipping_methods'] as List<dynamic>?)
              ?.map((m) => ShippingMethodEntity(
                    id: m['id']?.toString() ?? '',
                    name: _s(m['name']),
                    nameAr: _s(m['name_ar']),
                    description: '',
                    cost: double.tryParse(m['cost']?.toString() ?? '0') ?? 0.0,
                    originalCost: double.tryParse(m['original_cost']?.toString() ?? '0')
                        ?? double.tryParse(m['cost']?.toString() ?? '0') ?? 0.0,
                    estimatedTime: _s(m['estimated_time']),
                    estimatedTimeAr: _s(m['estimated_time_ar']),
                    isFree: m['is_free'] as bool? ?? false,
                    provider: _s(m['provider'], 'manual'),
                    iconUrl: m['icon_url']?.toString() ??
                             m['logo']?.toString() ??
                             shipping.fold((l) => <ShippingMethodEntity>[], (r) => r).where((sm) => sm.id == m['id']?.toString()).firstOrNull?.iconUrl,
                    isCodSupported: m['is_cod_supported'] as bool? ?? false,
                    supportsColdChain: m['supports_cold_chain'] as bool? ?? true,
                    isDisabled: m['is_disabled'] as bool? ?? false,
                    isSelected: m['is_selected'] as bool? ?? false,
                  ))
              .toList();

          // User requested: do NOT auto-select by default, EXCEPT for express groups
          ShippingMethodEntity? preSelected = null;
          if (g['type'] == 'express' && parsedMethods != null && parsedMethods.isNotEmpty) {
            preSelected = parsedMethods.where((m) => !m.isDisabled).firstOrNull;
          }

          return CheckoutGroupEntity(
            id: gId,
            storeId: g['express_warehouse_id']?.toString() ?? '',
            storeName: _s(g['label'] ?? g['type'], 'Store'),
            label: _s(g['label']),
            labelAr: _s(g['label_ar']),
            isExpressGroup: g['type'] == 'express',
            hasColdItems: g['has_cold_items'] as bool? ?? false,
            selectedShipping: preSelected,
            items: (g['items'] as List<dynamic>?)?.map((i) {
              final iMap = i as Map<String, dynamic>? ?? {};
              final p = iMap['product'] as Map<String, dynamic>?;
              return CheckoutItemEntity(
                id: iMap['id']?.toString() ?? '',
                name: _s(p?['name'] ?? iMap['name']),
                imageUrl: _s(p?['image_url'] ?? iMap['image_url'] ?? p?['primary_image_url']),
                price: double.tryParse((p?['price'] ?? iMap['price'])?.toString() ?? '0') ?? 0.0,
                quantity: (iMap['quantity'] as num?)?.toInt() ?? 1,
                isExpress: iMap['is_express'] as bool? ?? false,
                isExpressEligible: iMap['is_express_eligible'] as bool? ?? false,
              );
            }).toList() ?? [],
            availableShippingMethods: parsedMethods,
          );
        }).toList();
      },
    );

    // If the summary failed (e.g. empty cart), do NOT proceed to CheckoutLoaded.
    if (summaryFailed) return;

    var checkoutEntity = checkout.getOrElse(() => throw StateError('unreachable'));

    final double groupsSubtotal = rawGroups.fold(0.0, (sum, g) {
      final st = (g['subtotal'] as num?)?.toDouble() ?? 0.0;
      return sum + st;
    });

    if (pointsInfo != null) {
      checkoutEntity = checkoutEntity.copyWith(
        pointsInfo: pointsInfo,
        pointsToEarn: (pointsInfo!['points_to_earn'] as num?)?.toInt() ?? checkoutEntity.pointsToEarn,
        // ✅ FIX: حدّث الـ subtotal من الـ groups لأن الـ entity الأصلية ممكن تكون subtotal = 0
        subtotal: groupsSubtotal > 0 ? groupsSubtotal : checkoutEntity.subtotal,
      );
    } else {
      // حتى لو مفيش pointsInfo، حدّث الـ subtotal
      if (groupsSubtotal > 0) {
        checkoutEntity = checkoutEntity.copyWith(subtotal: groupsSubtotal);
      }
    }
    checkoutEntity = checkoutEntity.copyWith(groups: parsedGroups);

    // Wallet balance from the summary — drives the "Pay with wallet" toggle.
    // (Without this the field stays null from getCheckout() and the toggle
    //  never renders even when the user has a positive balance.)
    if (walletBalance != null) {
      checkoutEntity = checkoutEntity.copyWith(
        walletBalance: walletBalance,
        walletMaxUsable: walletMaxUsable,
      );
    }

    // Auto-apply per-group pre-selections
    final autoSelections = <String, ShippingMethodEntity>{};
    for (final group in parsedGroups) {
      if (group.selectedShipping != null) {
        autoSelections[group.id] = group.selectedShipping!;
      }
    }

    emit(CheckoutLoaded(
      checkout:        checkoutEntity,
      shippingMethods: shipping.getOrElse(() => []),
      paymentMethods:  payment.getOrElse(() => []),
      cities:          cities.getOrElse(() => []),
      countries:       countries.getOrElse(() => []),
      deliverySlots:   deliverySlots.getOrElse(() => {}),
      addresses:       addressList,
      rawGroups:       rawGroups,
      selectedAddress: defaultAddress,
      nationalAddressMandatory: nationalAddressMandatory,
      groupShippingSelections: autoSelections,
    ));
  }

  /// The groups payload sent to the server — the SAME one for a quote and for the
  /// order that follows it. Extracted from placeOrder() precisely so the two can
  /// never drift: a quote built from a different payload would quote a price the
  /// customer is not then charged.
  List<Map<String, dynamic>>? _buildGroupsPayload(CheckoutLoaded s) {
    final globalShipping = s.selectedShipping;

    // Nothing to quote until at least one shipping method is chosen.
    if (globalShipping == null && s.groupShippingSelections.isEmpty) return null;

    final groupsPayload = (s.checkout.groups != null && s.checkout.groups!.isNotEmpty)
        ? s.checkout.groups!.map((g) {
            final groupShipping = s.groupShippingSelections[g.id]
                ?? g.selectedShipping
                ?? globalShipping;

            final rawGroup = s.rawGroups.firstWhere(
                (r) => r['group_id']?.toString() == g.id,
                orElse: () => {});
            final expId = rawGroup['express_warehouse_id'] 
                       ?? rawGroup['warehouse_id'] 
                       ?? rawGroup['store_id'] 
                       ?? g.id;

            return {
              'group_id': int.tryParse(g.id) ?? g.id,
              'shipping_method_id': groupShipping!.id == 'express'
                  ? 'express'
                  : int.tryParse(groupShipping.id) ?? groupShipping.id,
              if (groupShipping.id == 'express')
                'express_warehouse_id': int.tryParse(expId.toString()) ?? expId,
            };
          }).toList()
        : s.rawGroups.isNotEmpty
            ? s.rawGroups.map((rawGroup) {
                final gId = rawGroup['group_id']?.toString() ?? '';
                final groupShipping = s.groupShippingSelections[gId] ?? globalShipping;
                final expId = rawGroup['express_warehouse_id'] 
                           ?? rawGroup['warehouse_id'] 
                           ?? rawGroup['store_id'] 
                           ?? gId;

                return {
                  'group_id': rawGroup['group_id'],
                  'shipping_method_id': groupShipping!.id == 'express'
                      ? 'express'
                      : int.tryParse(groupShipping.id) ?? groupShipping.id,
                  if (groupShipping.id == 'express')
                    'express_warehouse_id': int.tryParse(expId.toString()) ?? expId,
                };
              }).toList()
            // Fallback: single group with group_id = 1
            : [{
                'group_id': 1,
                'shipping_method_id': int.tryParse(globalShipping!.id) ?? globalShipping.id,
              }];


    return groupsPayload.cast<Map<String, dynamic>>();
  }

  /// Re-quote from the server whenever anything that moves the price changes.
  ///
  /// The delivery fee is VAT-INCLUSIVE (25 SAR = 21.74 + 3.26 VAT) and joins the
  /// taxable base once a method is picked, so the VAT line and the total both move.
  /// The app must NOT work this out itself — /checkout/quote runs the same code
  /// that places the order, so the screen and the invoice always agree.
  Future<void> _refreshQuote() async {
    final s = state;
    if (s is! CheckoutLoaded) return;

    final groupsPayload = _buildGroupsPayload(s);
    if (groupsPayload == null || groupsPayload.isEmpty) return;

    final result = await _checkoutRepository.getCheckoutQuote(
      groups: groupsPayload,
      pointsToUse: s.pointsToUse > 0 ? s.pointsToUse : null,
      walletAmount: s.walletAmount > 0 ? s.walletAmount : null,
    );

    // A failed quote must not break checkout — the screen keeps its previous
    // figures and the server still prices the order correctly at placement.
    result.fold(
      (_) {},
      (json) {
        final current = state;
        if (current is CheckoutLoaded) {
          emit(current.copyWith(quote: CheckoutQuote.fromJson(json)));
        }
      },
    );
  }

  // ─── Selections ──────────────────────────────────────────────────────────

  void selectShippingMethod(ShippingMethodEntity method) {
    final s = state;
    if (s is! CheckoutLoaded) return;
    emit(s.copyWith(selectedShipping: method));
    _refreshQuote();   // the fee (and the VAT inside it) just changed
  }

  /// Selects a shipping method for a specific group (multi-group checkout).
  void selectGroupShippingMethod(String groupId, ShippingMethodEntity method) {
    final s = state;
    if (s is! CheckoutLoaded) return;
    final updated = Map<String, ShippingMethodEntity>.from(s.groupShippingSelections)
      ..[groupId] = method;
    emit(s.copyWith(groupShippingSelections: updated));
    _refreshQuote();   // the fee (and the VAT inside it) just changed
  }

  void selectPaymentMethod(PaymentMethodEntity method) {
    final s = state;
    if (s is! CheckoutLoaded) return;
    emit(s.copyWith(selectedPayment: method));
  }

  void selectAddress(AddressEntity address) {
    final s = state;
    if (s is! CheckoutLoaded) return;
    // Keep the global navbar in sync with the address chosen in checkout.
    _locationCubit.setManualAddress(address);
    emit(s.copyWith(selectedAddress: address));
    _reloadSummaryWithAddress(address);
  }

  Future<void> _reloadSummaryWithAddress(AddressEntity address) async {
    final s = state;
    if (s is! CheckoutLoaded) return;

    // Priority: address-level coords (geocoded by backend) > GPS fallback.
    // setManualAddress() has already updated DeliveryLocationCubit with these coords.
    final summaryLat = address.lat ?? _coords.lat;
    final summaryLng = address.lng ?? _coords.lng;

    final summaryResult = await _checkoutRepository.getCheckoutSummary(
      lat: summaryLat, lng: summaryLng,
    );
    summaryResult.fold((_) {}, (data) {
      final groupsList = (data['groups'] as List<dynamic>?) ?? [];
      final rawGroups = groupsList.map((g) => g as Map<String, dynamic>).toList();
      final pointsInfo = data['points'] as Map<String, dynamic>?;
      final walletBalance = (data['wallet_balance'] as num?)?.toDouble();
      final walletInfo = data['wallet'] as Map<String, dynamic>?;
      final walletMaxUsable = (walletInfo?['max_usable'] as num?)?.toDouble();

      final parsedGroups = rawGroups.map((g) {
        final gId = _s(g['group_id']?.toString(), '1');
        final parsedMethods = (g['available_shipping_methods'] as List<dynamic>?)
            ?.map((m) => ShippingMethodEntity(
                  id: m['id']?.toString() ?? '',
                  name: _s(m['name']),
                  nameAr: _s(m['name_ar']),
                  description: '',
                  cost: double.tryParse(m['cost']?.toString() ?? '0') ?? 0.0,
                  originalCost: double.tryParse(m['original_cost']?.toString() ?? '0')
                      ?? double.tryParse(m['cost']?.toString() ?? '0') ?? 0.0,
                  estimatedTime: _s(m['estimated_time']),
                  estimatedTimeAr: _s(m['estimated_time_ar']),
                  isFree: m['is_free'] as bool? ?? false,
                  provider: _s(m['provider'], 'manual'),
                  iconUrl: m['icon_url']?.toString() ??
                           m['logo']?.toString() ??
                           s.shippingMethods.where((sm) => sm.id == m['id']?.toString()).firstOrNull?.iconUrl,
                  isCodSupported: m['is_cod_supported'] as bool? ?? false,
                  supportsColdChain: m['supports_cold_chain'] as bool? ?? true,
                  isDisabled: m['is_disabled'] as bool? ?? false,
                  isSelected: m['is_selected'] as bool? ?? false,
                ))
            .toList();

        // User requested: auto-select for express groups
        ShippingMethodEntity? preSelected = null;
        if (parsedMethods != null && parsedMethods.isNotEmpty) {
          preSelected = parsedMethods.where((m) => m.isSelected).firstOrNull;
          if (preSelected == null && g['type'] == 'express') {
            preSelected = parsedMethods.where((m) => !m.isDisabled).firstOrNull;
          }
        }

        return CheckoutGroupEntity(
          id: gId,
          storeId: g['express_warehouse_id']?.toString() ?? '',
          storeName: _s(g['label'] ?? g['type'], 'Store'),
          label: _s(g['label']),
          labelAr: _s(g['label_ar']),
          isExpressGroup: g['type'] == 'express',
          hasColdItems: g['has_cold_items'] as bool? ?? false,
          selectedShipping: preSelected,
          items: (g['items'] as List<dynamic>?)?.map((i) {
            final iMap = i as Map<String, dynamic>? ?? {};
            final p = iMap['product'] as Map<String, dynamic>?;
            return CheckoutItemEntity(
              id: iMap['id']?.toString() ?? '',
              name: _s(p?['name'] ?? iMap['name']),
              imageUrl: _s(p?['image_url'] ?? iMap['image_url'] ?? p?['primary_image_url']),
              price: double.tryParse((p?['price'] ?? iMap['price'])?.toString() ?? '0') ?? 0.0,
              quantity: (iMap['quantity'] as num?)?.toInt() ?? 1,
              isExpress: iMap['is_express'] as bool? ?? false,
              isExpressEligible: iMap['is_express_eligible'] as bool? ?? false,
            );
          }).toList() ?? [],
          availableShippingMethods: parsedMethods,
        );
      }).toList();

      // Auto-apply backend pre-selections
      final autoSelections = <String, ShippingMethodEntity>{};
      for (final group in parsedGroups) {
        if (group.selectedShipping != null) {
          autoSelections[group.id] = group.selectedShipping!;
        }
      }

      var checkoutEntity = s.checkout;

      // ✅ FIX: احسب الـ subtotal الحقيقي من الـ groups
      final double reloadSubtotal = rawGroups.fold(0.0, (sum, g) {
        return sum + ((g['subtotal'] as num?)?.toDouble() ?? 0.0);
      });

      if (pointsInfo != null) {
        checkoutEntity = checkoutEntity.copyWith(
          pointsInfo: pointsInfo,
          pointsToEarn: (pointsInfo['points_to_earn'] as num?)?.toInt() ?? checkoutEntity.pointsToEarn,
          subtotal: reloadSubtotal > 0 ? reloadSubtotal : checkoutEntity.subtotal,
        );
      } else if (reloadSubtotal > 0) {
        checkoutEntity = checkoutEntity.copyWith(subtotal: reloadSubtotal);
      }
      checkoutEntity = checkoutEntity.copyWith(groups: parsedGroups);
      if (walletBalance != null) {
        checkoutEntity = checkoutEntity.copyWith(
          walletBalance: walletBalance,
          walletMaxUsable: walletMaxUsable,
        );
      }

      if (!isClosed) {
        emit(s.copyWith(
          checkout: checkoutEntity,
          rawGroups: rawGroups,
          groupShippingSelections: autoSelections, // apply backend pre-selections
        ));
      }
    });
  }

  void setGuestAddress(Map<String, dynamic> address) {
    final s = state;
    if (s is! CheckoutLoaded) return;
    emit(s.copyWith(guestAddress: address));
  }

  void updatePointsToUse(int points) {
    final s = state;
    if (s is! CheckoutLoaded) return;
    emit(s.copyWith(pointsToUse: points));
    _refreshQuote();   // points reduce the taxable base, so the VAT moves too
  }

  /// S7: Apply wallet balance at checkout.
  /// Guards: cannot be applied with BNPL (Tabby/Tamara) or COD methods.
  /// [amount] is clamped between 0 and the available balance.
  void setWalletAmount(double amount) {
    final s = state;
    if (s is! CheckoutLoaded) return;
    final method = s.selectedPayment;
    if (method != null && (method.provider == PaymentProvider.tabby ||
        method.provider == PaymentProvider.tamara ||
        method.provider == PaymentProvider.cod)) {
      // Cannot use wallet with BNPL / COD — silently ignore
      return;
    }
    emit(s.copyWith(walletAmount: amount.clamp(0.0, double.infinity)));
    _refreshQuote();   // the wallet is a TENDER — it changes `total`, not the VAT
  }

  /// S7: Clear wallet amount (e.g. when switching to BNPL/COD method).
  void clearWalletAmount() {
    final s = state;
    if (s is! CheckoutLoaded) return;
    emit(s.copyWith(walletAmount: 0.0));
    _refreshQuote();
  }

  void selectDeliveryDateAndSlot(String date, String slot) {
    final s = state;
    if (s is! CheckoutLoaded) return;
    emit(s.copyWith(selectedDeliveryDate: date, selectedDeliverySlot: slot));
  }

  /// GAP-3: Customer delivery notes — stored in state and sent with place-order.
  void setNotes(String notes) {
    final s = state;
    if (s is! CheckoutLoaded) return;
    emit(s.copyWith(deliveryNotes: notes.trim()));
  }

  /// GAP-39: Apply a coupon/promo code — updates the checkout entity's couponCode.
  Future<void> setCouponCode(String code) async {
    final s = state;
    if (s is! CheckoutLoaded) return;
    
    final c = _coords;
    final addressId = s.selectedAddress?.id;
    
    final result = await _applyCouponUseCase(code.trim(), lat: c.lat, lng: c.lng, addressId: addressId);
    
    if (isClosed) return;
    result.fold(
      (failure) {
        emit(CheckoutError(failure));
        emit(s); // Revert to loaded state
      },
      (_) => loadCheckout(),
    );
  }

  /// GAP-39: Remove the applied coupon.
  Future<void> removeCouponCode() async {
    final s = state;
    if (s is! CheckoutLoaded) return;
    
    final c = _coords;
    final addressId = s.selectedAddress?.id;
    
    final result = await _removeCouponUseCase(lat: c.lat, lng: c.lng, addressId: addressId);
    
    if (isClosed) return;
    result.fold(
      (failure) {
        emit(CheckoutError(failure));
        emit(s); // Revert
      },
      (_) => loadCheckout(),
    );
  }

  // ─── Place Order ─────────────────────────────────────────────────────────

  Future<bool> placeOrder(BuildContext context) async {
    if (state is! CheckoutLoaded) return false;
    CheckoutLoaded s = state as CheckoutLoaded;

    // Clear previous error item if any
    if (s.errorItemName != null) {
      s = s.copyWith(errorItemName: null);
      emit(s);
    }

    final globalShipping = s.selectedShipping;
    final payment        = s.selectedPayment;
    final groups         = s.checkout.groups;
    final hasGroups      = groups != null && groups.isNotEmpty;

    // Shipping is satisfied if:
    //  • A global shipping method is selected (single-group fallback UI), OR
    //  • At least one per-group selection exists (multi-group UI)
    final shippingSelected = globalShipping != null || s.groupShippingSelections.isNotEmpty;

    // O4b: a payment method is only required when the wallet doesn't already
    // cover the whole order — a pure wallet checkout has no gateway to pick.
    if (!shippingSelected || (payment == null && !s.isWalletFullyCovering)) {
      emit(OrderError('checkout.selectShippingPayment'.tr()));
      emit(s);
      return false;
    }

    final isGuest = AuthGuard.isGuest(context);

    if (!isGuest && s.selectedAddress == null) {
      emit(OrderError('checkout.selectAddress'.tr()));
      emit(s);
      return false;
    }

    if (isGuest && s.guestAddress == null) {
      emit(OrderError('checkout.enterGuestAddress'.tr()));
      emit(s);
      return false;
    }

    // ── National Address (short_address) validation ──────────────────────────
    // If the backend requires it, validate client-side to show a clear message
    // instead of a cryptic 422 server error.
    if (!isGuest && s.nationalAddressMandatory) {
      final addr = s.selectedAddress;
      if (addr != null && (addr.shortAddress == null || addr.shortAddress!.trim().isEmpty)) {
        emit(OrderError('checkout.shortAddressRequired'.tr()));
        emit(s);
        return false;
      }
    }

    // ── Per-group shipping validation ─────────────────────────────────────────
    // Every group (including single-group carts) must have a shipping selection.
    // Global selection acts as a valid fallback for any group.
    if (hasGroups) {
      for (final group in groups) {
        final hasSelection = s.groupShippingSelections.containsKey(group.id)
            || group.selectedShipping != null
            || globalShipping != null; // global is a valid fallback
        if (!hasSelection) {
          emit(OrderError('checkout.selectShippingPayment'.tr()));
          emit(s);
          return false;
        }
      }
    }

    emit(PlacingOrder());

    final groupsPayload = _buildGroupsPayload(s)!;

    // Guests can never use the wallet (server forces wallet_amount=0 for
    // them), so `payment` is guaranteed non-null on the guest branch by the
    // gate above. Only the authenticated branch can omit it (wallet-only).
    final result = isGuest
      ? await _placeOrderUseCase.placeGuest(
        groups: groupsPayload,
        paymentMethodId: int.tryParse(payment!.id) ?? 0,
        guestAddress: s.guestAddress!,
        notes: (s.deliveryNotes ?? '').trim().isEmpty ? null : s.deliveryNotes!.trim(),
        pointsToUse: s.pointsToUse,
        walletAmount: s.walletAmount > 0 ? s.walletAmount : null,
        deliveryDate: s.selectedDeliveryDate,
        deliverySlot: s.selectedDeliverySlot,
      )
      : await _placeOrderUseCase(
        groups: groupsPayload,
        paymentMethodId: payment != null ? (int.tryParse(payment.id) ?? 0) : null,
        addressId: int.tryParse(s.selectedAddress!.id) ?? 0,
        notes: (s.deliveryNotes ?? '').trim().isEmpty ? null : s.deliveryNotes!.trim(),
        pointsToUse: s.pointsToUse,
        walletAmount: s.walletAmount > 0 ? s.walletAmount : null,
        deliveryDate: s.selectedDeliveryDate,
        deliverySlot: s.selectedDeliverySlot,
      );

    if (isClosed) return true;

    result.fold(
          (failure) {
            // Gateway rejected the order (e.g. Tabby amount too high). Surface a
            // dedicated state so the screen shows a prominent "choose another
            // method" dialog rather than a fleeting error snackbar.
            if (failure.code == 'PAYMENT_REJECTED') {
              emit(PaymentRejected(failure.message));
              restoreLoadedState();
            } else if (failure.message.contains(' only has ') && failure.message.contains(' units')) {
              final itemName = failure.message.split(' only has').first.trim();
              emit(s.copyWith(errorItemName: itemName));
              // Delay OrderError so the UI can rebuild CheckoutLoaded first
              Future.delayed(const Duration(milliseconds: 50), () {
                if (!isClosed) {
                  emit(OrderError(failure.message));
                  restoreLoadedState();
                }
              });
            } else {
              emit(OrderError(failure.message));
              restoreLoadedState();
            }
          },
          (order)   => _handleOrderPlaced(order),
    );

    return true;
  }

  // ─── Payment Initiation ──────────────────────────────────────────────────

  /// Called automatically after a successful place-order for online payments.
  ///
  /// Flow:
  ///   OrderPlaced (online) → [InitiatingPayment] → POST /checkout/initiate-payment
  ///     → success: [PaymentInitiated]  → screen opens TelrPaymentPage
  ///     → failure: [PaymentInitiationFailed] → screen shows retry option
  void _handleOrderPlaced(PlaceOrderResult order) {
    if (order.isCod || order.isWalletOnly) {
      // Cash on delivery, or a pure wallet-only order (O4b) — no gateway
      // redirect needed either way; the order is already settled.
      emit(OrderPlaced(order));
      return;
    }

    // Derive the correct provider so Tabby/Tamara open in the external browser
    // (their checkout blocks iframe/WebView via X-Frame-Options) and intercept
    // the right return URL path.
    //
    // NOTE: by the time this runs the state is `PlacingOrder`, NOT `CheckoutLoaded`
    // (placeOrder emitted PlacingOrder before awaiting). Reading `state` here would
    // always fall back to telr and load Tabby in a WebView. Use the preserved last
    // loaded state, which still holds the customer's selected payment method.
    final provider = (state is CheckoutLoaded)
        ? (state as CheckoutLoaded).selectedPayment?.provider ?? PaymentProvider.telr
        : _lastLoadedState?.selectedPayment?.provider ?? PaymentProvider.telr;

    // For online payments the API already returns a payment_url inside
    // payment_initiation when place-order succeeds. Use it directly if
    // available; otherwise call the separate initiate-payment endpoint.
    if (order.paymentUrl != null && order.paymentUrl!.isNotEmpty) {
      // Defense-in-depth: if the URL is clearly a BNPL gateway, trust the URL over
      // a possibly-stale provider so it always opens in the external browser.
      final resolved = _providerFromUrl(order.paymentUrl!, provider);
      emit(PaymentInitiated(
        paymentUrl:  order.paymentUrl!,
        orderNumber: order.orderNumber,
        provider: resolved,
      ));
      return;
    }

    // Fallback: explicitly initiate payment (e.g. if place-order didn't
    // return a URL — the order id is encoded in the order number for now;
    // real impl should carry orderId from PlaceOrderResult).
    emit(OrderPlaced(order)); // emit so screen knows order was created
    _initiatePaymentForOrder(order, provider);
  }

  /// Explicitly calls POST /checkout/initiate-payment when the place-order
  /// response did not include a payment_url.
  Future<void> _initiatePaymentForOrder(PlaceOrderResult order, [PaymentProvider provider = PaymentProvider.telr]) async {
    _lastProvider = provider;
    // Parse the numeric order id. If unavailable, surface a friendly error.
    final orderId = int.tryParse(order.orderNumber.replaceAll(RegExp(r'\D'), ''));
    if (orderId == null) {
      emit(PaymentInitiationFailed(
        message:     'checkout.payment.cannotParseOrderId'.tr(),
        orderNumber: order.orderNumber,
        orderId: order.orderId
      ));
      return;
    }

    emit(InitiatingPayment(order.orderNumber));

    final result = await _checkoutRepository.initiatePayment(order.orderId);

    if (isClosed) return;

    result.fold(
          (failure) {
            emit(PaymentInitiationFailed(
              message:     failure.message,
              orderNumber: order.orderNumber,
              orderId: order.orderId
            ));
            restoreLoadedState();
          },
          (url) {
            // When the provider is unknown (e.g. an order-details retry that
            // could not map the method name), infer it from the gateway URL so
            // the payment page picks the right return-path / BNPL browser flow.
            final resolved = provider == PaymentProvider.unknown
                ? _providerFromUrl(url, provider)
                : provider;
            emit(PaymentInitiated(
              paymentUrl:  url,
              orderNumber: order.orderNumber,
              provider: resolved,
            ));
          },
    );
  }

  /// Best-effort provider detection from the gateway checkout URL — used when
  /// the caller could not determine the provider up front.
  PaymentProvider _providerFromUrl(String url, PaymentProvider fallback) {
    final u = url.toLowerCase();
    if (u.contains('tabby'))  return PaymentProvider.tabby;
    if (u.contains('tamara')) return PaymentProvider.tamara;
    if (u.contains('telr'))   return PaymentProvider.telr;
    return fallback == PaymentProvider.unknown ? PaymentProvider.telr : fallback;
  }

  /// Re-attempts payment for an order that was already placed but whose
  /// payment initiation failed (e.g. gateway credentials error).
  Future<void> retryPayment(String orderId, String orderNumber,
      [PaymentProvider? provider]) async {
    final fakeOrder = PlaceOrderResult(
      orderId:     orderId,
      orderNumber: orderNumber,
      status:      'pending',
      total:       0,
      isCod:       false,
    );
    await _initiatePaymentForOrder(fakeOrder, provider ?? _lastProvider);
  }

  /// Customer backed out of a failed BNPL payment: cancel the unpaid order group
  /// (server releases stock reservations) and rebuild the cart from its items.
  /// Pass either the numeric id or the order_number — the backend accepts both.
  Future<bool> backToCart(String orderIdOrNumber) async {
    final result = await _checkoutRepository.cancelUnpaid(orderIdOrNumber);
    if (isClosed) return false;
    return result.fold((_) => false, (_) => true);
  }

  // ─── WebView return URL handlers ─────────────────────────────────────────
  ///
  /// Telr:   ?status=authorised&cartid=ORD-12345  (legacy, order already exists)
  /// Tabby:  ?status=authorised&order_id=ORD-12345
  /// Tamara: ?status=authorised&order_id=ORD-12345
  void handlePaymentReturn(Uri returnUrl) {
    final status = returnUrl.queryParameters['status'] ?? '';
    // Telr uses 'cartid'; Tamara & Tabby use 'order_id'
    final orderNumber = returnUrl.queryParameters['cartid']
        ?? returnUrl.queryParameters['order_id']
        ?? '';
    final total = double.tryParse(returnUrl.queryParameters['total'] ?? '');

    switch (status.toLowerCase()) {
      case 'authorised':
        emit(PaymentConfirmed(orderNumber, total: total));
        break;
      case 'declined':
        emit(PaymentFailed(
          message:     'checkout.payment.declined'.tr(),
          orderNumber: orderNumber,
        ));
        break;
      case 'cancelled':
        emit(PaymentFailed(
          message:     'checkout.payment.cancelled'.tr(),
          orderNumber: orderNumber,
        ));
        restoreLoadedState();
        break;
      case 'failed':
        emit(PaymentFailed(
          message:     'checkout.payment.failed'.tr(),
          orderNumber: orderNumber,
        ));
        restoreLoadedState();
        break;
      default:
        emit(PaymentFailed(
          message:     'checkout.payment.unknownStatus'.tr(args: [status]),
          orderNumber: orderNumber,
        ));
        restoreLoadedState();
    }
  }

  /// Called when the WebView intercepts the deep link from the server result page.
  ///
  /// URL format: fastway://payment-result?success=true&order_number=ORD-xxx&status=authorised
  ///
  /// Used for the deferred checkout flow (Telr CI- intents) where the server
  /// creates the order and redirects to this deep link with the REAL order number.
  void handleDeepLinkPaymentResult(Uri uri) {
    final success     = uri.queryParameters['success'] == 'true';
    final orderNumber = uri.queryParameters['order_number'] ?? '';
    final status      = uri.queryParameters['status'] ?? '';
    final total       = double.tryParse(uri.queryParameters['total'] ?? '');

    if (success) {
      emit(PaymentConfirmed(orderNumber, total: total));
    } else {
      final message = switch (status) {
        'declined'            => 'checkout.payment.declined'.tr(),
        'cancelled'           => 'checkout.payment.cancelled'.tr(),
        'verification_failed' => 'checkout.payment.verificationFailed'.tr(),
        'intent_expired'      => 'checkout.payment.sessionExpired'.tr(),
        _                     => 'checkout.payment.failed'.tr(),
      };
      emit(PaymentFailed(message: message, orderNumber: orderNumber));
      restoreLoadedState();
    }
  }

  // ─── Apple Pay via the Telr Flutter SDK ───────────────────────────────────────
  //
  // Flow (iOS app only — gated by the caller):
  //   1. createSdkOrder → backend validates cart + creates a Telr order, returns
  //      { ap_ref, token_url, order_url }.
  //   2. TelrSdk.init(applePayMerchantIdentifier) + TelrSdk.payWithApplePay(tokenUrl,
  //      orderUrl) → opens the native Apple Pay sheet directly (no Telr webview)
  //      and charges via Telr.
  //   3. On SDK success → confirmSdkPayment(ap_ref): backend VERIFIES the charge
  //      with Telr (never trusts the SDK flag) and creates the order.
  //
  // On success  → emits PaymentConfirmed with the real order number.
  // On cancel   → restores the loaded state silently (user backed out).
  // On decline/error → emits OrderError with a localized message.
  Future<void> applePayPlaceOrder(
    BuildContext context, {
    required String appleMerchantId,
  }) async {
    if (state is! CheckoutLoaded) return;
    final s = state as CheckoutLoaded;

    final globalShipping = s.selectedShipping;
    final payment        = s.selectedPayment;
    final groups         = s.checkout.groups;

    if (payment == null) {
      emit(OrderError('checkout.selectShippingPayment'.tr()));
      emit(s);
      return;
    }

    final isGuest = AuthGuard.isGuest(context);

    // Payment page language — the SDK renders the Apple Pay/Telr UI in this
    // locale. Capture it now (sync) before any await so we don't touch context
    // across an async gap. 'ar' when the app is Arabic, else 'en'.
    final payPageLang = context.locale.languageCode == 'ar' ? 'ar' : 'en';

    // ── Build groups payload — identical logic to placeOrder() ───────────────
    final groupsPayload = (groups != null && groups.isNotEmpty)
        ? groups.map((g) {
            final groupShipping = s.groupShippingSelections[g.id]
                ?? g.selectedShipping
                ?? globalShipping;
            final rawGroup = s.rawGroups.firstWhere(
                (r) => r['group_id']?.toString() == g.id,
                orElse: () => {});
            final expId = rawGroup['express_warehouse_id']
                       ?? rawGroup['warehouse_id']
                       ?? rawGroup['store_id']
                       ?? g.id;
            return {
              'group_id': int.tryParse(g.id) ?? g.id,
              'shipping_method_id': groupShipping?.id == 'express'
                  ? 'express'
                  : int.tryParse(groupShipping?.id ?? '') ?? groupShipping?.id,
              if (groupShipping?.id == 'express')
                'express_warehouse_id': int.tryParse(expId.toString()) ?? expId,
            };
          }).toList()
        : [{'group_id': 1, 'shipping_method_id': int.tryParse(globalShipping?.id ?? '') ?? globalShipping?.id}];

    final paymentMethodId = int.tryParse(payment.id) ?? 0;
    final addressId       = isGuest ? null : int.tryParse(s.selectedAddress?.id ?? '');
    final guestAddress    = isGuest ? s.guestAddress : null;

    emit(PlacingOrder());

    // ── Step 1: create the Telr order (backend validates cart + total) ────────
    final orderResult = await _checkoutRepository.createSdkOrder(
      paymentMethodId: paymentMethodId,
      groups:          groupsPayload,
      addressId:       addressId,
      guestAddress:    guestAddress,
      notes:           (s.deliveryNotes ?? '').trim().isEmpty ? null : s.deliveryNotes!.trim(),
      pointsToUse:     s.pointsToUse > 0 ? s.pointsToUse : null,
      deliveryDate:    s.selectedDeliveryDate,
      deliverySlot:    s.selectedDeliverySlot,
    );

    if (isClosed) return;

    final init = orderResult.fold((f) => null, (v) => v);
    if (init == null) {
      orderResult.fold((f) => emit(OrderError(f.message)), (_) {});
      restoreLoadedState();
      return;
    }

    // ── Step 2: open the NATIVE Apple Pay sheet directly ──────────────────────
    // payWithApplePay runs Apple Pay with NO Telr SDK UI (no webview, no card
    // list) — it's for a merchant-owned button, which is exactly our case.
    // (presentPayment would instead open Telr's full payment page.)
    PaymentResponse sdkResponse;
    try {
      await TelrSdk.init(
        applePayMerchantIdentifier: appleMerchantId,
        preferredLanguageCode: payPageLang,
      );
      sdkResponse = await TelrSdk.payWithApplePay(init.tokenUrl, init.orderUrl);
    } catch (e) {
      if (isClosed) return;
      emit(OrderError('checkout.payment.failed'.tr()));
      restoreLoadedState();
      return;
    }

    // The Telr plugin's payWithApplePay never dismisses the view controller the
    // native SDK presented (unlike every other method in that plugin), leaving
    // the sheet stranded with a dead close button. Do it ourselves, for every
    // outcome, before touching state or navigation.
    await dismissStrandedNativeSheet();

    if (isClosed) return;

    // User cancelled the sheet — no charge, restore silently.
    if (sdkResponse.status == TelrPaymentStatus.cancelled) {
      restoreLoadedState();
      return;
    }

    // SDK reported a hard failure before any charge could be verified.
    if (!sdkResponse.success && sdkResponse.status == TelrPaymentStatus.failure) {
      emit(OrderError('checkout.payment.declined'.tr()));
      restoreLoadedState();
      return;
    }

    // ── Step 3: confirm server-side (backend re-verifies with Telr) ───────────
    final confirmResult = await _checkoutRepository.confirmSdkPayment(init.apRef);

    if (isClosed) return;

    confirmResult.fold(
      (failure) {
        emit(OrderError(failure.message));
        restoreLoadedState();
      },
      (orderNumber) {
        // Carry the amount through so the success screen shows what was actually
        // paid — without it PaymentConfirmed.total is null and the screen renders 0.
        emit(PaymentConfirmed(orderNumber, total: double.tryParse(init.amount ?? '')));
      },
    );
  }

  // ─── Apple Pay on the WEB (Telr Configuration 1 / Apple Pay JS) ────────────────
  //
  // Web-only sibling of applePayPlaceOrder. The Telr mobile SDK does not run on
  // web, so this drives the browser ApplePaySession (web/apple_pay.js), which:
  //   • validates the merchant → POST /payments/telr/applepay/validate-merchant
  //   • charges + places order → POST /payments/telr/applepay (remote.json)
  //
  // MUST stay synchronous up to startWebApplePay(): Safari requires the session
  // to be created inside the tap gesture, so every input is read synchronously
  // (_webSessionId is preloaded in loadCheckout; the token is in-memory).
  //
  // Like the native flow, this charges the FULL (pre-wallet) order total — the
  // wallet tender is not applied to Apple Pay orders.
  Future<void> webApplePayPlaceOrder(BuildContext context) async {
    if (state is! CheckoutLoaded) return;
    final s = state as CheckoutLoaded;

    final globalShipping = s.selectedShipping;
    final payment        = s.selectedPayment;
    final groups         = s.checkout.groups;

    if (payment == null) {
      emit(OrderError('checkout.selectShippingPayment'.tr()));
      emit(s);
      return;
    }

    final isGuest = AuthGuard.isGuest(context);
    final lang    = context.locale.languageCode == 'ar' ? 'ar' : 'en';
    final token   = UserRepository().currentUser?.token;

    // Groups payload — identical logic to placeOrder()/applePayPlaceOrder().
    final groupsPayload = (groups != null && groups.isNotEmpty)
        ? groups.map((g) {
            final groupShipping = s.groupShippingSelections[g.id]
                ?? g.selectedShipping
                ?? globalShipping;
            final rawGroup = s.rawGroups.firstWhere(
                (r) => r['group_id']?.toString() == g.id,
                orElse: () => {});
            final expId = rawGroup['express_warehouse_id']
                       ?? rawGroup['warehouse_id']
                       ?? rawGroup['store_id']
                       ?? g.id;
            return {
              'group_id': int.tryParse(g.id) ?? g.id,
              'shipping_method_id': groupShipping?.id == 'express'
                  ? 'express'
                  : int.tryParse(groupShipping?.id ?? '') ?? groupShipping?.id,
              if (groupShipping?.id == 'express')
                'express_warehouse_id': int.tryParse(expId.toString()) ?? expId,
            };
          }).toList()
        : [{'group_id': 1, 'shipping_method_id': int.tryParse(globalShipping?.id ?? '') ?? globalShipping?.id}];

    final paymentMethodId = int.tryParse(payment.id) ?? 0;
    final addressId       = isGuest ? null : int.tryParse(s.selectedAddress?.id ?? '');
    final guestAddress    = isGuest ? s.guestAddress : null;
    final notes           = (s.deliveryNotes ?? '').trim();

    final checkoutBody = <String, dynamic>{
      'groups': groupsPayload,
      'payment_method_id': paymentMethodId,
      if (addressId != null)    'address_id': addressId,
      if (guestAddress != null) 'guest_address': guestAddress,
      if (notes.isNotEmpty)     'notes': notes,
      if (s.pointsToUse > 0)    'points_to_use': s.pointsToUse,
      if (s.selectedDeliveryDate != null) 'delivery_date': s.selectedDeliveryDate,
      if (s.selectedDeliverySlot != null) 'delivery_slot': s.selectedDeliverySlot,
    };

    // Sheet amount = gross (pre-wallet) total the backend will charge. The
    // backend recomputes authoritatively; this is for display.
    final amount = s.quote?.grossTotal ?? s.preWalletGrossTotal;

    final config = <String, dynamic>{
      'apiBase':        Endpoints.baseUrl,
      'validatePath':   Endpoints.telrValidateMerchant,
      'chargePath':     Endpoints.telrWebApplePay,
      'authHeader':     (token != null && token.isNotEmpty) ? 'Bearer $token' : null,
      'sessionId':      _webSessionId,
      'acceptLanguage': lang,
      'countryCode':    'SA',
      'currencyCode':   'SAR',
      'supportedNetworks':    const ['mada', 'visa', 'masterCard', 'amex'],
      'merchantCapabilities': const ['supports3DS'],
      'label':          'Fastway',
      'amount':         amount.toStringAsFixed(2),
      'checkoutBody':   checkoutBody,
    };

    emit(PlacingOrder());

    // Session is created synchronously inside startWebApplePay (no await before it).
    String resultJson;
    try {
      resultJson = await startWebApplePay(jsonEncode(config));
    } catch (e) {
      if (isClosed) return;
      emit(OrderError('checkout.payment.failed'.tr()));
      restoreLoadedState();
      return;
    }
    if (isClosed) return;

    Map<String, dynamic> res;
    try {
      res = jsonDecode(resultJson) as Map<String, dynamic>;
    } catch (_) {
      res = const {'status': 'error'};
    }

    switch (res['status']) {
      case 'success':
        emit(PaymentConfirmed((res['orderNumber'] ?? '').toString()));
        return;
      case 'cancelled':
        restoreLoadedState();
        return;
      case 'failure':
        emit(OrderError('checkout.payment.declined'.tr()));
        restoreLoadedState();
        return;
      default:
        emit(OrderError('checkout.payment.failed'.tr()));
        restoreLoadedState();
        return;
    }
  }
}
