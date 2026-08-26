// lib/features/orders/presentation/cubit/orders_state.dart

import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/order_entity.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object?> get props => [];
}


class OrdersInitial        extends OrdersState {}
class OrdersLoading        extends OrdersState {}
class OrderDetailsLoading  extends OrdersState {}
class OrderTrackingLoading extends OrdersState {}
class OrderCanceling       extends OrdersState {}

/// Emitted when the user is not logged in — no API call is made.
class OrdersGuest extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<OrderEntity> orders;
  const OrdersLoaded(this.orders);
  @override List<Object?> get props => [orders];
}

class OrdersError extends OrdersState {
  final Failure failure;
  const OrdersError(this.failure);
  @override List<Object?> get props => [failure];
}

class OrderDetailsLoaded extends OrdersState {
  final OrderEntity order;
  const OrderDetailsLoaded(this.order);
  @override List<Object?> get props => [order];
}

class OrderDetailsError extends OrdersState {
  final Failure failure;
  const OrderDetailsError(this.failure);
  @override List<Object?> get props => [failure];
}

class OrderTrackingLoaded extends OrdersState {
  final OrderEntity order;
  const OrderTrackingLoaded(this.order);
  @override List<Object?> get props => [order];
}

class OrderTrackingError extends OrdersState {
  final Failure failure;
  const OrderTrackingError(this.failure);
  @override List<Object?> get props => [failure];
}

class OrderCanceled extends OrdersState {}

class OrderCancelError extends OrdersState {
  final Failure failure;
  const OrderCancelError(this.failure);
  @override List<Object?> get props => [failure];
}

class OrderReordering extends OrdersState {}

class OrderReordered extends OrdersState {
  final String message;
  const OrderReordered(this.message);
  @override List<Object?> get props => [message];
}

class OrderReorderError extends OrdersState {
  final Failure failure;
  const OrderReorderError(this.failure);
  @override List<Object?> get props => [failure];
}

class OrderReturning extends OrdersState {}

class OrderReturned extends OrdersState {}

class OrderReturnError extends OrdersState {
  final Failure failure;
  const OrderReturnError(this.failure);
  @override List<Object?> get props => [failure];
}

// ── Post-delivery reviews (store + shipment + items) ──────────────────────────
class OrderReviewsSubmitting extends OrdersState {}

/// Emitted after the fan-out completes. [succeeded] is the number of review
/// calls that persisted; [failedSections] lists which ones failed
/// (e.g. 'store', 'shipment', 'item:<productId>'). Empty = full success.
class OrderReviewsSubmitted extends OrdersState {
  final int succeeded;
  final List<String> failedSections;
  const OrderReviewsSubmitted({required this.succeeded, this.failedSections = const []});
  @override List<Object?> get props => [succeeded, failedSections];
}

class OrderReviewsSubmitError extends OrdersState {
  final Failure failure;
  const OrderReviewsSubmitError(this.failure);
  @override List<Object?> get props => [failure];
}