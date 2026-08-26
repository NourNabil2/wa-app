// lib/features/orders/presentation/cubit/orders_cubit.dart

import 'package:fastway/features/auth/domain/usecases/usecase.dart';
import 'package:fastway/features/user_data/user_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/usecases/get_order_details_usecase.dart';
import '../../domain/usecases/get_orders_usecase.dart';
import '../../domain/usecases/track_order_usecase.dart';
import '../../domain/usecases/cancel_order_usecase.dart';
import '../../domain/usecases/reorder_usecase.dart';
import '../../domain/usecases/submit_return_usecase.dart';
import '../../domain/usecases/submit_store_review_usecase.dart';
import '../../domain/usecases/submit_shipment_review_usecase.dart';
import 'package:fastway/features/product_details/domain/usecases/submit_review_usecase.dart';
import 'orders_state.dart';

class OrdersCubit extends Cubit<OrdersState> {
  final GetOrdersUseCase _getOrdersUseCase;
  final GetOrderDetailsUseCase _getOrderDetailsUseCase;
  final TrackOrderUseCase _trackOrderUseCase;
  final CancelOrderUseCase _cancelOrderUseCase;
  final ReorderUseCase _reorderUseCase;
  final SubmitReturnUseCase _submitReturnUseCase;
  final SubmitStoreReviewUseCase _submitStoreReviewUseCase;
  final SubmitShipmentReviewUseCase _submitShipmentReviewUseCase;
  final SubmitReviewUseCase _submitReviewUseCase; // product (item) reviews

  OrdersCubit({
    required GetOrdersUseCase getOrdersUseCase,
    required GetOrderDetailsUseCase getOrderDetailsUseCase,
    required TrackOrderUseCase trackOrderUseCase,
    required CancelOrderUseCase cancelOrderUseCase,
    required ReorderUseCase reorderUseCase,
    required SubmitReturnUseCase submitReturnUseCase,
    required SubmitStoreReviewUseCase submitStoreReviewUseCase,
    required SubmitShipmentReviewUseCase submitShipmentReviewUseCase,
    required SubmitReviewUseCase submitReviewUseCase,
  })  : _getOrdersUseCase = getOrdersUseCase,
        _getOrderDetailsUseCase = getOrderDetailsUseCase,
        _trackOrderUseCase = trackOrderUseCase,
        _cancelOrderUseCase = cancelOrderUseCase,
        _reorderUseCase = reorderUseCase,
        _submitReturnUseCase = submitReturnUseCase,
        _submitStoreReviewUseCase = submitStoreReviewUseCase,
        _submitShipmentReviewUseCase = submitShipmentReviewUseCase,
        _submitReviewUseCase = submitReviewUseCase,
        super(OrdersInitial());

  bool get _isGuest => UserRepository().currentUser == null;

  Future<void> loadOrders() async {
    if (_isGuest) {
      emit(OrdersGuest());
      return;
    }
    if (isClosed) return;
    emit(OrdersLoading());
    final result = await _getOrdersUseCase(NoParams());
    if (isClosed) return;
    result.fold(
          (failure) => emit(OrdersError(failure)),
          (orders)  => emit(OrdersLoaded(orders)),
    );
  }

  Future<void> loadOrderDetails(String orderId) async {
    if (_isGuest) {
      emit(const OrderDetailsError(UnauthorizedFailure('orders.loginRequired')));      return;
    }
    if (isClosed) return;
    emit(OrderDetailsLoading());
    final result = await _getOrderDetailsUseCase(orderId);
    if (isClosed) return;
    result.fold(
          (failure) => emit(OrderDetailsError(failure)),
          (order) {
        if (order != null) {
          emit(OrderDetailsLoaded(order));
        } else {
          emit(const OrderDetailsError(CacheFailure('Order not found')));
        }
      },
    );
  }

  Future<void> trackOrder(String orderId) async {
    if (_isGuest) {
      emit(const OrderTrackingError(UnauthorizedFailure('orders.loginRequired')));      return;
    }
    if (isClosed) return;
    emit(OrderTrackingLoading());
    final trackResult = await _trackOrderUseCase(orderId);
    final detailsResult = await _getOrderDetailsUseCase(orderId);
    if (isClosed) return;

    trackResult.fold(
      (failure) => emit(OrderTrackingError(failure)),
      (trackOrder) {
        detailsResult.fold(
          (failure) => emit(OrderTrackingError(failure)),
          (detailsOrder) {
            if (detailsOrder != null) {
              final mergedOrder = trackOrder.copyWith(
                id: detailsOrder.id,
                items: detailsOrder.items,
                shippingAddress: detailsOrder.shippingAddress,
                paymentMethod: detailsOrder.paymentMethod,
                subtotal: detailsOrder.subtotal,
                shippingCost: detailsOrder.shippingCost,
                total: detailsOrder.total,
                vatAmount: detailsOrder.vatAmount,
                vatRate: detailsOrder.vatRate,
                couponDiscount: detailsOrder.couponDiscount,
                pointsDiscount: detailsOrder.pointsDiscount,
                walletPaid: detailsOrder.walletPaid,
                grossTotal: detailsOrder.grossTotal,
              );
              emit(OrderTrackingLoaded(mergedOrder));
            } else {
              emit(OrderTrackingLoaded(trackOrder));
            }
          },
        );
      },
    );
  }

  Future<void> cancelOrder(String orderId) async {
    if (_isGuest) {
      emit(const OrderCancelError(UnauthorizedFailure('orders.loginRequired')));
      return;
    }
    if (isClosed) return;
    emit(OrderCanceling());
    final result = await _cancelOrderUseCase(orderId);
    if (isClosed) return;
    result.fold(
          (failure) => emit(OrderCancelError(failure)),
          (_) {
            emit(OrderCanceled());
            loadOrderDetails(orderId);
          },
    );
  }

  Future<void> reorderOrder(String orderId) async {
    if (_isGuest) {
      emit(const OrderReorderError(UnauthorizedFailure('orders.loginRequired')));
      return;
    }
    if (isClosed) return;
    emit(OrderReordering());
    final result = await _reorderUseCase(orderId);
    if (isClosed) return;
    result.fold(
          (failure) => emit(OrderReorderError(failure)),
          (message) => emit(OrderReordered(message)),
    );
  }

  Future<void> submitReturn({
    required String orderNumber,
    required String orderId,
    required List<Map<String, dynamic>> items,
    required String reason,
    String? notes,
    List<String> imagePaths = const [],
  }) async {
    if (_isGuest) {
      emit(const OrderReturnError(UnauthorizedFailure('orders.loginRequired')));
      return;
    }
    if (isClosed) return;
    emit(OrderReturning());
    final result = await _submitReturnUseCase(
      orderNumber: orderNumber,
      orderId: orderId,
      items: items,
      reason: reason,
      notes: notes,
      imagePaths: imagePaths,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(OrderReturnError(failure)),
      (_) {
        emit(OrderReturned());
        loadOrderDetails(orderId);
      },
    );
  }

  /// Post-delivery reviews — fans out to store + shipment + per-item product
  /// reviews. Each call runs independently: a failure in one never aborts the
  /// others. Reports per-section success/failure, then refreshes the order once.
  Future<void> submitOrderReviews({
    required String orderId,
    ({int rating, String? comment})? store,
    ({int rating, String? comment})? shipment,
    Map<String, ({int rating, String? comment})> items = const {}, // key: productId
  }) async {
    if (_isGuest) {
      emit(const OrderReviewsSubmitError(UnauthorizedFailure('orders.loginRequired')));
      return;
    }
    if (isClosed) return;
    emit(OrderReviewsSubmitting());

    int succeeded = 0;
    final failed = <String>[];

    if (store != null) {
      final r = await _submitStoreReviewUseCase(orderId, store.rating, store.comment);
      r.fold((_) => failed.add('store'), (_) => succeeded++);
    }
    if (shipment != null) {
      final r = await _submitShipmentReviewUseCase(orderId, shipment.rating, shipment.comment);
      r.fold((_) => failed.add('shipment'), (_) => succeeded++);
    }
    for (final entry in items.entries) {
      final r = await _submitReviewUseCase(entry.key, entry.value.rating, entry.value.comment);
      r.fold((_) => failed.add('item:${entry.key}'), (_) => succeeded++);
    }

    if (isClosed) return;
    emit(OrderReviewsSubmitted(succeeded: succeeded, failedSections: failed));
    // Refresh once so reviewed flags update — only if anything actually persisted.
    if (succeeded > 0) await loadOrderDetails(orderId);
  }

  /// Request cancellation for an in-progress order.
  Future<bool> requestCancellation(String orderId, String reason) async {
    if (_isGuest) return false;
    emit(OrderCanceling());
    final result = await _cancelOrderUseCase.repository.requestCancellation(orderId, reason);
    return result.fold(
      (_) { emit(OrdersInitial()); return false; },
      (_) async {
        emit(OrderCanceled());
        await loadOrderDetails(orderId);
        return true;
      },
    );
  }

  /// Customer confirms they received the order.
  Future<bool> confirmDelivery(String orderId) async {
    if (_isGuest) return false;
    final result = await _cancelOrderUseCase.repository.confirmDelivery(orderId);
    return result.fold(
      (_) => false,
      (_) async {
        await loadOrderDetails(orderId);
        return true;
      },
    );
  }

  void refreshOrders() => loadOrders();
}