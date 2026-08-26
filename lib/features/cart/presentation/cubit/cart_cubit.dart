import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/cubit/delivery_location/delivery_location_cubit.dart';
import '../../../../core/cubit/delivery_location/delivery_location_state.dart';
import '../../../../core/utils/app_constans.dart';
import '../../domain/usecases/add_to_cart_usecase.dart';
import '../../domain/usecases/apply_coupon_usecase.dart';
import '../../domain/usecases/get_cart_usecase.dart';
import '../../domain/usecases/merge_guest_cart_usecase.dart';
import '../../domain/usecases/remove_coupon_usecase.dart';
import '../../domain/usecases/remove_item_usecase.dart';
import '../../domain/usecases/update_quantity_usecase.dart';
import '../../domain/usecases/toggle_express_item_usecase.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final GetCartUseCase _getCartUseCase;
  final AddToCartUseCase _addToCartUseCase;
  final UpdateQuantityUseCase _updateQuantityUseCase;
  final RemoveItemUseCase _removeItemUseCase;
  final ApplyCouponUseCase _applyCouponUseCase;
  final RemoveCouponUseCase _removeCouponUseCase;
  final ToggleExpressItemUseCase _toggleExpressItemUseCase;
  final MergeGuestCartUseCase _mergeGuestCartUseCase;
  final DeliveryLocationCubit _locationCubit;

  CartCubit({
    required GetCartUseCase getCartUseCase,
    required AddToCartUseCase addToCartUseCase,
    required UpdateQuantityUseCase updateQuantityUseCase,
    required RemoveItemUseCase removeItemUseCase,
    required ApplyCouponUseCase applyCouponUseCase,
    required RemoveCouponUseCase removeCouponUseCase,
    required ToggleExpressItemUseCase toggleExpressItemUseCase,
    required MergeGuestCartUseCase mergeGuestCartUseCase,
    required DeliveryLocationCubit locationCubit,
  })  : _getCartUseCase = getCartUseCase,
        _addToCartUseCase = addToCartUseCase,
        _updateQuantityUseCase = updateQuantityUseCase,
        _removeItemUseCase = removeItemUseCase,
        _applyCouponUseCase = applyCouponUseCase,
        _removeCouponUseCase = removeCouponUseCase,
        _toggleExpressItemUseCase = toggleExpressItemUseCase,
        _mergeGuestCartUseCase = mergeGuestCartUseCase,
        _locationCubit = locationCubit,
        super(CartInitial());

  /// Gets the current delivery location coordinates from the global DeliveryLocationCubit.
  /// These are passed to every cart API call so the backend can compute
  /// per-product express eligibility relative to the selected address.
  ({double? lat, double? lng}) get _coords {
    final locState = _locationCubit.state;
    if (locState is DeliveryLocationResolved) {
      return (lat: locState.lat, lng: locState.lng);
    }
    return (lat: null, lng: null);
  }

  /// Gets the currently selected address ID (for logged-in users).
  /// When provided, the backend uses it to geocode the exact delivery address
  /// (Priority 2 in ResolveDeliveryCoordinates) instead of the default address.
  String? get _addressId {
    final locState = _locationCubit.state;
    if (locState is DeliveryLocationResolved) {
      return locState.selectedAddress?.id;
    }
    return null;
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadCart() async {
    emit(CartLoading());
    final c = _coords;
    final result = await _getCartUseCase(lat: c.lat, lng: c.lng, addressId: _addressId);
    if (isClosed) return;
    result.fold(
          (failure) => emit(CartError(failure)),
          (cart) => emit(CartLoaded(cart)),
    );
  }

  /// Merge the guest session cart into the user cart, then reload.
  /// Call this once after a successful login, BEFORE loading the cart.
  Future<void> mergeAndLoad() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString(AppConstants.sessionKey);
      if (sessionId != null && sessionId.isNotEmpty) {
        final c = _coords;
        await _mergeGuestCartUseCase(sessionId, lat: c.lat, lng: c.lng);
        await prefs.remove(AppConstants.sessionKey);
      }
    } catch (_) {
      // Merge is best-effort — never block the login flow
    }
    await loadCart();
  }

  // ── Add ───────────────────────────────────────────────────────────────────

  Future<void> addToCart({
    required String productId,
    required int quantity,
  }) async {
    if (isClosed) return;
    // Remember the current cart so we can revert on error
    final previousCart = state is CartLoaded ? (state as CartLoaded).cart : null;
    emit(AddingToCart(productId: productId));
    final c = _coords;
    final result = await _addToCartUseCase(
      productId: productId,
      quantity: quantity,
      lat: c.lat,
      lng: c.lng,
      addressId: _addressId,
    );
    if (isClosed) return;
    result.fold(
      (failure) {
        // Show a toast error, then revert back to the previous cart (non-fatal)
        emit(CartToastError(failure.message));
        if (previousCart != null) {
          emit(CartLoaded(previousCart));
        }
      },
      (cart) {
        emit(AddedToCart('cart.messages.added_success'.tr()));
        emit(CartLoaded(cart));
      },
    );
  }

  // ── Quantity helpers ──────────────────────────────────────────────────────

  Future<void> incrementQuantity(String itemId) async {
    final s = state;
    if (s is! CartLoaded) return;
    final item = s.cart.items.firstWhere((i) => i.id == itemId);
    if (item.quantity >= item.maxQuantity) return;
    final previousCart = s.cart;
    emit(AddingToCart(productId: item.productId));
    final c = _coords;
    final result = await _updateQuantityUseCase(
      itemId: itemId,
      quantity: item.quantity + 1,
      lat: c.lat,
      lng: c.lng,
      addressId: _addressId,
    );
    if (isClosed) return;
    result.fold(
      (failure) {
        emit(CartToastError(failure.message));
        emit(CartLoaded(previousCart));
      },
      (cart) => emit(CartLoaded(cart)),
    );
  }

  Future<void> decrementQuantity(String itemId) async {
    final s = state;
    if (s is! CartLoaded) return;
    final item = s.cart.items.firstWhere((i) => i.id == itemId);
    if (item.quantity <= 1) return;
    final previousCart = s.cart;
    emit(AddingToCart(productId: item.productId));
    final c = _coords;
    final result = await _updateQuantityUseCase(
      itemId: itemId,
      quantity: item.quantity - 1,
      lat: c.lat,
      lng: c.lng,
      addressId: _addressId,
    );
    if (isClosed) return;
    result.fold(
      (failure) {
        emit(CartToastError(failure.message));
        emit(CartLoaded(previousCart));
      },
      (cart) => emit(CartLoaded(cart)),
    );
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    if (state is! CartLoaded) return;
    final previousCart = (state as CartLoaded).cart;
    final c = _coords;
    final result = await _updateQuantityUseCase(
      itemId: itemId,
      quantity: quantity,
      lat: c.lat,
      lng: c.lng,
      addressId: _addressId,
    );
    if (isClosed) return;
    result.fold(
      (failure) {
        emit(CartToastError(failure.message));
        emit(CartLoaded(previousCart));
      },
      (cart) => emit(CartLoaded(cart)),
    );
  }

  // ── Remove ────────────────────────────────────────────────────────────────

  Future<void> removeItem(String itemId) async {
    if (state is! CartLoaded) return;
    final previousCart = (state as CartLoaded).cart;
    final c = _coords;
    final result = await _removeItemUseCase(itemId, lat: c.lat, lng: c.lng, addressId: _addressId);
    if (isClosed) return;
    result.fold(
      (failure) {
        emit(CartToastError(failure.message));
        emit(CartLoaded(previousCart));
      },
      (cart) => emit(CartLoaded(cart)),
    );
  }

  // ── Coupon ────────────────────────────────────────────────────────────────

  Future<void> applyCoupon(String couponCode) async {
    if (couponCode.trim().isEmpty) return;
    final currentState = state;
    dynamic currentCart;
    if (currentState is CartLoaded) currentCart = currentState.cart;
    emit(ApplyingCoupon());
    final c = _coords;
    final result = await _applyCouponUseCase(couponCode.trim(), lat: c.lat, lng: c.lng, addressId: _addressId);
    if (isClosed) return;
    result.fold(
          (failure) {
        emit(CouponError(failure.message));
        if (currentCart != null) emit(CartLoaded(currentCart));
      },
          (cart) {
        emit(CouponApplied('cart.messages.coupon_applied_success'.tr(), cart));
        emit(CartLoaded(cart));
      },
    );
  }

  Future<void> removeCoupon() async {
    if (isClosed) return;
    final c = _coords;
    final result = await _removeCouponUseCase(lat: c.lat, lng: c.lng, addressId: _addressId);
    if (isClosed) return;
    result.fold(
          (failure) => emit(CouponError(failure.message)),
          (cart) => emit(CartLoaded(cart)),
    );
  }

  // ── Express Toggle ─────────────────────────────────────────────────────────

  Future<void> toggleExpressItem(String itemId) async {
    final previous = state; // remember cart to revert on error
    if (previous is! CartLoaded) return;
    final c = _coords;
    final result = await _toggleExpressItemUseCase(itemId, lat: c.lat, lng: c.lng, addressId: _addressId);
    if (isClosed) return;
    result.fold(
      (failure) {
        // Show error alert without killing the cart view
        emit(CartToastError(failure.message));
        emit(previous); // revert UI back to current cart
      },
      (cart) => emit(CartLoaded(cart)),
    );
  }
}