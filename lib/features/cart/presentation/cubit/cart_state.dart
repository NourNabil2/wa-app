import 'package:equatable/equatable.dart';
import 'package:fastway/core/errors/failures.dart';
import '../../domain/entities/cart_entity.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final CartEntity cart;

  const CartLoaded(this.cart);

  @override
  List<Object?> get props => [cart];
}

class CartError extends CartState {
  final Failure failure;

  const CartError(this.failure);

  @override
  List<Object?> get props => [failure];
}

// ✅ NEW - تتبع أي product بالظبط بيحمل
class AddingToCart extends CartState {
  final String? productId; // null = ما في loading

  const AddingToCart({this.productId});

  @override
  List<Object?> get props => [productId];
}

class AddedToCart extends CartState {
  final String message;

  const AddedToCart(this.message);

  @override
  List<Object?> get props => [message];
}

class ApplyingCoupon extends CartState {}

class CouponApplied extends CartState {
  final String message;
  final CartEntity cart;

  const CouponApplied(this.message, this.cart);

  @override
  List<Object?> get props => [message, cart];
}

class CouponError extends CartState {
  final String message;

  const CouponError(this.message);

  @override
  List<Object?> get props => [message];
}

/// A non-fatal error that should be shown as a snackbar/alert
/// without replacing the cart view (e.g. express toggle rejected by server).
class CartToastError extends CartState {
  final String message;

  const CartToastError(this.message);

  @override
  List<Object?> get props => [message];
}