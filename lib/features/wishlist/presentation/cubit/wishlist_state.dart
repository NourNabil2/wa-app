import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/wishlist_entity.dart';

abstract class WishlistState extends Equatable {
  const WishlistState();
}

class WishlistInitial extends WishlistState {
  @override
  List<Object?> get props => [];
}

class WishlistLoading extends WishlistState {
  @override
  List<Object?> get props => [];
}

class WishlistLoaded extends WishlistState {
  final WishlistEntity wishlist;
  const WishlistLoaded(this.wishlist);

  @override
  List<Object?> get props => [wishlist];
}

class WishlistError extends WishlistState {
  final Failure failure;
  const WishlistError(this.failure);

  @override
  List<Object?> get props => [failure];
}

// Transient feedback states
class WishlistItemToggling extends WishlistState {
  final String productId;
  const WishlistItemToggling({required this.productId});

  @override
  List<Object?> get props => [productId];
}

/// Emitted briefly after a successful add, before `WishlistLoaded` arrives.
/// Carries [productId] so [WishlistHeartButton] can show the filled heart
/// optimistically during the reload — preventing a 1-frame flicker.
class WishlistItemAdded extends WishlistState {
  final String productId;
  final String message;

  const WishlistItemAdded({required this.productId, required this.message});

  @override
  List<Object?> get props => [productId, message];
}

/// Emitted briefly after a successful remove, before `WishlistLoaded` arrives.
/// Carries [productId] so the heart button can show the unfilled state
/// optimistically and the screen listener can show the snackbar.
class WishlistItemRemoved extends WishlistState {
  final String productId;
  final String message;

  const WishlistItemRemoved({required this.productId, required this.message});

  @override
  List<Object?> get props => [productId, message];
}
