import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/wishlist_entity.dart';
import '../../domain/usecases/get_wishlist_usecase.dart';
import '../../domain/usecases/toggle_wishlist_usecase.dart';
import '../../domain/usecases/remove_wishlist_item_usecase.dart';
import '../../domain/usecases/clear_wishlist_usecase.dart';
import 'wishlist_state.dart';

class WishlistCubit extends Cubit<WishlistState> {
  final GetWishlistUseCase _getWishlist;
  final ToggleWishlistUseCase _toggle;
  final RemoveWishlistItemUseCase _removeItem;
  final ClearWishlistUseCase _clear;

  WishlistCubit({
    required GetWishlistUseCase getWishlist,
    required ToggleWishlistUseCase toggle,
    required RemoveWishlistItemUseCase removeItem,
    required ClearWishlistUseCase clear,
  })  : _getWishlist = getWishlist,
        _toggle = toggle,
        _removeItem = removeItem,
        _clear = clear,
        super(WishlistInitial());

  // ── Internal: cache last known list ────────────────────────────────────────
  WishlistEntity? _lastKnownWishlist;

  /// Synchronous O(1) lookup — safe to call from build() without a setState.
  /// Returns `null` if the wishlist has never been loaded (initial state).
  bool? isProductWishlisted(String productId) {
    return _lastKnownWishlist?.items.any((i) => i.productId == productId);
  }

  /// Whether the cubit has loaded at least once.
  bool get hasData => _lastKnownWishlist != null;

  Future<void> loadWishlist() async {
    emit(WishlistLoading());
    final result = await _getWishlist();
    if (isClosed) return;
    result.fold(
      (f) => emit(WishlistError(f)),
      (w) {
        _lastKnownWishlist = w;
        emit(WishlistLoaded(w));
      },
    );
  }

  /// Optimistic toggle called from product card heart buttons.
  /// Flow: WishlistItemToggling → WishlistItemAdded/Removed → loadWishlist.
  Future<void> toggleProduct(String productId) async {
    emit(WishlistItemToggling(productId: productId));

    final result = await _toggle(productId);
    if (isClosed) return;

    result.fold(
      (f) {
        emit(WishlistError(f));
        if (_lastKnownWishlist != null) {
          emit(WishlistLoaded(_lastKnownWishlist!));
        }
      },
      (r) {
        if (r.isWishlisted) {
          // Update cache immediately so isProductWishlisted() stays correct
          // during the WishlistLoading window that follows loadWishlist().
          _lastKnownWishlist = _lastKnownWishlist?.copyWithAdded(productId);
          emit(WishlistItemAdded(
            productId: productId,
            message: 'wishlist.add_success',
          ));
        } else {
          _lastKnownWishlist = _lastKnownWishlist?.copyWithRemoved(productId);
          emit(WishlistItemRemoved(
            productId: productId,
            message: 'wishlist.remove_success',
          ));
        }
        loadWishlist();
      },
    );
  }

  /// Removes an item by wishlist row ID (swipe-to-delete on WishlistScreen).
  Future<void> removeItem(
    String wishlistItemId, {
    required String productId,
  }) async {
    final result = await _removeItem(wishlistItemId);
    if (isClosed) return;
    result.fold(
      (f) => emit(WishlistError(f)),
      (_) {
        _lastKnownWishlist = _lastKnownWishlist?.copyWithRemoved(productId);
        emit(WishlistItemRemoved(
          productId: productId,
          message: 'wishlist.remove_success',
        ));
        loadWishlist();
      },
    );
  }

  Future<void> clearAll() async {
    final result = await _clear();
    if (isClosed) return;
    result.fold(
      (f) => emit(WishlistError(f)),
      (_) {
        _lastKnownWishlist = const WishlistEntity(items: [], total: 0, count: 0);
        emit(const WishlistLoaded(WishlistEntity(items: [], total: 0, count: 0)));
      },
    );
  }
}
