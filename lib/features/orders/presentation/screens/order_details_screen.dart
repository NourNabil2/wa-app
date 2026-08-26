// lib/features/orders/presentation/screens/order_details_screen.dart
//
// RESPONSIVE VERSION
// ─────────────────────────────────────────────────────────────────────────────
// • Mobile  (< 900px)  → Single column scroll
// • Desktop (≥ 900px)  → SimpleWebShell with 2-column layout

import 'package:fastway/core/theme/colors.dart';
import 'dart:async'; // E-23: Timer for cancellation countdown

import 'package:fastway/core/routes/app_navigator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/layout/simple_web_shell.dart';
import 'package:fastway/core/responsive/responsive_layout.dart';
import 'package:fastway/core/widgets/app_buton.dart';
import 'package:fastway/core/widgets/skeletons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_snack_bar.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../domain/entities/order_entity.dart';
import '../cubit/orders_cubit.dart';
import '../cubit/orders_state.dart';
import '../widgets/order_product_item.dart';
import '../widgets/order_status_badge.dart';
import '../widgets/order_payment_recovery_card.dart';
import '../widgets/order_summary_section.dart';
import '../../../../core/services/app_settings_service.dart';
import '../widgets/return_request_sheet.dart';
import '../widgets/return_status_modal.dart';
import '../widgets/rate_order_sheet.dart';
import '../widgets/my_order_reviews_card.dart';
import '../widgets/delivery_sla_widget.dart'; // T8.6
import 'invoice_screen.dart';
import '../../../../core/api/model/endpoints.dart';
import '../../../../core/widgets/selectable.dart';

/// Returns true if the customer is allowed to submit a NEW return request.
/// Allowed when: no prior return, OR prior return is fully done (refunded/closed/rejected).
bool _canRequestReturn(String? returnStatus) {
  return returnStatus == null ||
      returnStatus == 'refunded' ||
      returnStatus == 'closed' ||
      returnStatus == 'rejected';
}

/// True when the delivered order still has at least one un-reviewed section
/// (store, shipment, or any item). Drives the "Rate your order" button.
bool _canRateOrder(OrderEntity order) {
  if (order.status != 'delivered') return false;
  return !order.storeReviewed ||
      !order.shipmentReviewed ||
      order.items.any((i) => !i.reviewed && i.productId.isNotEmpty);
}

Widget _rateOrderButton(BuildContext context, OrderEntity order) {
  return SizedBox(
    width: double.infinity,
    height: 56,
    child: OutlinedButton.icon(
      onPressed: () => RateOrderSheet.show(context, order),
      icon: const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFBBF24)),
      label: Text(
        'orders.rate_order.button'.tr(),
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: ColorsManager.primaryColor.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        foregroundColor: ColorsManager.primaryColor,
      ),
    ),
  );
}

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrdersCubit>().loadOrderDetails(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isWebLayout(context)
          ? (isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F6FA))
          : ColorsManager.backgroundSurface,
      appBar: isWebLayout(context)
          ? null
          : CustomAppBar(
              title: 'orders.details.title'.tr(),
              centerTitle: true,
              showBackIcon: true,
            ),
      body: BlocConsumer<OrdersCubit, OrdersState>(
        buildWhen: (previous, current) => 
            current is OrderDetailsLoading || 
            current is OrderDetailsLoaded || 
            current is OrderDetailsError,
        listener: (context, state) {
          if (state is OrderDetailsError) {
            CustomSnackBar.show(context ,
              message: state.failure.message,
              type: SnackBarType.error,
            );
          } else if (state is OrderReordered) {
            CustomSnackBar.show(context, message: 'orders.reorder_success'.tr());
            AppNavigator.pushNamed(context, Routes.cart);
          } else if (state is OrderReorderError) {
            CustomSnackBar.show(context, message: state.failure.message, type: SnackBarType.error);
          } else if (state is OrderCanceled) {
            CustomSnackBar.show(context, message: 'orders.cancel_success'.tr());
            // Reload the details so the status badge updates
            context.read<OrdersCubit>().loadOrderDetails(widget.orderId);
          } else if (state is OrderCancelError) {
            CustomSnackBar.show(context, message: state.failure.message, type: SnackBarType.error);
          }
        },
        builder: (context, state) {
          if (state is OrderDetailsLoading) {
            return const Center(child: GenericPageSkeleton());
          }
          if (state is OrderDetailsError) {
            return ErrorStateWidget(
              failure: state.failure,
              onRetry: () => context
                  .read<OrdersCubit>()
                  .loadOrderDetails(widget.orderId),
            );
          }
          if (state is OrderDetailsLoaded) {
            if (isWebLayout(context)) {
              return SimpleWebShell(
                content: _WebOrderDetails(order: state.order),
              );
            }
            return _OrderDetailsContent(order: state.order);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOBILE ORDER DETAILS
// ═══════════════════════════════════════════════════════════════════════════════

class _OrderDetailsContent extends StatelessWidget {
  final OrderEntity order;

  const _OrderDetailsContent({required this.order});

  @override
  Widget build(BuildContext context) {
    final v = AppSizeVertical.instance;
    final h = AppSizeHorizontal.instance;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: h.s16, vertical: v.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Split Order Banner
          if (order.relatedOrders?.isNotEmpty == true)
            _SplitOrderBanner(relatedOrders: order.relatedOrders!, relatedOrderIds: order.relatedOrderIds),

          _OrderHeaderCard(order: order),
          SizedBox(height: v.s16),


          // ── Driver Card (when assigned)
          if (order.driverName != null) ...[
            _DriverInfoCard(
              driverName: order.driverName!,
              driverPhone: order.driverPhone,
            ),
            SizedBox(height: v.s20),
          ],

          _ProductsSection(items: order.items),
          SizedBox(height: v.s20),
          OrderSummarySection(order: order),
          SizedBox(height: v.s20),
          _ShippingInfoCard(order: order),
          SizedBox(height: v.s24),
          // T8.9: View Invoice button — shown as soon as the order is placed,
          // independent of delivery status (see OrderResource::has_invoice).
          if (order.hasInvoice) _InvoiceButton(order: order),
          if (order.hasInvoice) SizedBox(height: v.s12),
          if (order.status == 'delivered') ...[
            AppButton(
              text: 'orders.reorder'.tr(),
              onPressed: () => context.read<OrdersCubit>().reorderOrder(order.id),
              horizontalPadding: 0,
              verticalPadding: 0,
              backgroundColor: ColorsManager.primaryColor.withValues(alpha: 0.1),
              textColor: ColorsManager.primaryColor,
            ),
            SizedBox(height: v.s12),
            if (_canRateOrder(order)) ...[
              _rateOrderButton(context, order),
              SizedBox(height: v.s12),
            ],
            MyOrderReviewsCard(order: order),
            SizedBox(height: v.s12),
            if (order.status == 'delivered' &&
                !order.fullyReturned &&
                AppSettingsService.instance.canReturn(order.deliveredAt ?? order.createdAt))
              Padding(
                padding: EdgeInsets.zero,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => ReturnRequestSheet.show(context, order),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      foregroundColor: Colors.red,
                    ),
                    child: Text('orders.request_return'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
            if (order.returns.isNotEmpty)
              ...order.returns.asMap().entries.map((e) {
                final ret = e.value;
                final label = order.returns.length > 1
                    ? (e.key == 0 ? '${'orders.view_return'.tr()} (Latest)' : '#${order.returns.length - e.key} ${'orders.view_return'.tr()}')
                    : 'orders.view_return'.tr();
                return Padding(
                  padding: EdgeInsets.zero,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => ReturnStatusModal.show(context, order, specificReturn: ret),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: ColorsManager.primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        foregroundColor: ColorsManager.primaryColor,
                      ),
                      child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    ),
                  ),
                );
              }),
          ],
          // ── Cancel button: pending orders only ──────────────────
          if (order.status == 'pending') ...[
            SizedBox(height: v.s12),
            Builder(
              builder: (context) {
                final cancelButton = BlocBuilder<OrdersCubit, OrdersState>(
                  builder: (context, state) {
                    final isCanceling = state is OrderCanceling;
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: isCanceling
                            ? null
                            : () => _confirmCancel(context, order.id),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          foregroundColor: Colors.red,
                        ),
                        child: isCanceling
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                            : Text('orders.cancel'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      ),
                    );
                  },
                );

                if (order.cancelBefore != null) {
                  return _CancellationCountdown(deadline: order.cancelBefore!, button: cancelButton);
                } else {
                  return cancelButton;
                }
              },
            ),
          ],
          // ── Request Cancellation: pending orders past the instant-cancel window ──
          if (order.status == 'pending' &&
              order.cancelBefore != null &&
              order.cancelBefore!.isBefore(DateTime.now())) ...[
            SizedBox(height: v.s12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () => _requestCancellation(context, order),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.orange.shade700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  foregroundColor: Colors.orange.shade700,
                ),
                child: Text('orders.request_cancellation'.tr(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
          // ── Cancellation pending indicator ───────────────────
          if (order.status == 'cancellation_requested') ...[
            SizedBox(height: v.s12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Icon(Icons.hourglass_top_rounded, color: Colors.orange.shade700, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'orders.cancellation_under_review'.tr(),
                    style: TextStyle(fontSize: 13, color: Colors.orange.shade800),
                  ),
                ),
              ]),
            ),
          ],

          // ── Awaiting payment: retry / back-to-cart (BNPL & online) ──────
          if (order.isAwaitingPayment) ...[
            SizedBox(height: v.s12),
            OrderPaymentRecoveryCard(order: order),
          ],

        ],
      ),
    );
  }
  /// Shows a confirmation dialog before cancelling the order (pending).
  void _confirmCancel(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        title: Text('orders.cancel'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text('orders.cancel_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<OrdersCubit>().cancelOrder(orderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            child: Text('orders.cancel'.tr()),
          ),
        ],
      ),
    );
  }

  /// Shows bottom sheet to collect reason, then calls request-cancellation API.
  void _requestCancellation(BuildContext context, OrderEntity order) {
    final reasonController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(16)))),
            const SizedBox(height: 20),
            Text('orders.request_cancellation'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('orders.cancellation_reason_hint'.tr(), style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'orders.cancellation_reason_placeholder'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) return;
                  Navigator.pop(ctx);
                  final ok = await context.read<OrdersCubit>().requestCancellation(order.id, reason);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok ? 'orders.cancellation_submitted'.tr() : 'orders.cancellation_failed'.tr()),
                      backgroundColor: ok ? Colors.orange : Colors.red,
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                child: Text('orders.submit_cancellation'.tr(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

}

// ═══════════════════════════════════════════════════════════════════════════════
// WEB ORDER DETAILS — Responsive layout
// ═══════════════════════════════════════════════════════════════════════════════

class _WebOrderDetails extends StatelessWidget {
  final OrderEntity order;

  const _WebOrderDetails({required this.order});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, outerCs) {
      final isOuterNarrow = outerCs.maxWidth < 900;
      final outerHPad = isOuterNarrow
          ? (outerCs.maxWidth < 480 ? 12.0 : outerCs.maxWidth * 0.04)
          : 32.0;
      final vertPad = isOuterNarrow ? 20.0 : 40.0;

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: vertPad, horizontal: outerHPad),
        child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1440),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WebPageHeader(order: order),
            SizedBox(height: isOuterNarrow ? 16 : 28),
            LayoutBuilder(builder: (context, cs) {
              // Use a wider threshold so mobile-web widths (< 900px) go single-column
              final isNarrow = cs.maxWidth < 900;

              // ── Shared widgets ─────────────────────────────────────────
              final splitBanner = order.relatedOrders?.isNotEmpty == true
                  ? _SplitOrderBanner(relatedOrders: order.relatedOrders!, relatedOrderIds: order.relatedOrderIds)
                  : null;
              final headerCard = _OrderHeaderCard(order: order);
              final driverCard = order.driverName != null
                  ? _DriverInfoCard(driverName: order.driverName!, driverPhone: order.driverPhone)
                  : null;
              final productsSection = _ProductsSection(items: order.items);
              final shippingCard = _ShippingInfoCard(order: order);
              final summarySection = OrderSummarySection(order: order);

              Widget actionsColumn() => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  summarySection,
                  const SizedBox(height: 16),
                  // T8.9: View Invoice button — shown as soon as the order is
                  // placed, independent of delivery status.
                  if (order.hasInvoice) _InvoiceButton(order: order),
                  if (order.hasInvoice) const SizedBox(height: 12),
                  if (order.status == 'delivered') ...[
                    AppButton(
                      text: 'orders.reorder'.tr(),
                      onPressed: () => context.read<OrdersCubit>().reorderOrder(order.id),
                      horizontalPadding: 0, verticalPadding: 0, borderRadius: 12,
                      backgroundColor: ColorsManager.primaryColor.withValues(alpha: 0.1),
                      textColor: ColorsManager.primaryColor,
                    ),
                    const SizedBox(height: 12),
                    if (_canRateOrder(order)) ...[
                      _rateOrderButton(context, order),
                      const SizedBox(height: 12),
                    ],
                    MyOrderReviewsCard(order: order),
                    const SizedBox(height: 12),
                    if (!order.fullyReturned && AppSettingsService.instance.canReturn(order.deliveredAt ?? order.createdAt)) ...[
                      SizedBox(
                        width: double.infinity, height: 56,
                        child: OutlinedButton(
                          onPressed: () => ReturnRequestSheet.show(context, order),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), foregroundColor: Colors.red),
                          child: Text('orders.request_return'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ],
                    if (order.returns.isNotEmpty)
                      ...order.returns.asMap().entries.map((e) {
                        final ret = e.value;
                        final label = order.returns.length > 1
                            ? (e.key == 0 ? '${'orders.view_return'.tr()} (Latest)' : '#${order.returns.length - e.key} ${'orders.view_return'.tr()}')
                            : 'orders.view_return'.tr();
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            width: double.infinity, height: 56,
                            child: OutlinedButton(
                              onPressed: () => ReturnStatusModal.show(context, order, specificReturn: ret),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: ColorsManager.primaryColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), foregroundColor: ColorsManager.primaryColor),
                              child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                            ),
                          ),
                        );
                      }),
                  ],
                  if (order.status == 'pending') ...[
                    Builder(
                      builder: (context) {
                        final cancelButton = BlocBuilder<OrdersCubit, OrdersState>(
                          builder: (context, state) {
                            final isCanceling = state is OrderCanceling;
                            return SizedBox(
                              width: double.infinity, height: 56,
                              child: OutlinedButton(
                                onPressed: isCanceling ? null : () => _showWebCancelDialog(context, order.id),
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), foregroundColor: Colors.red),
                                child: isCanceling
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                                    : Text('orders.cancel'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ),
                            );
                          },
                        );

                        if (order.cancelBefore != null) {
                          return _CancellationCountdown(deadline: order.cancelBefore!, button: cancelButton);
                        } else {
                          return cancelButton;
                        }
                      },
                    ),
                  ],
                  if (order.status == 'pending' &&
                      order.cancelBefore != null &&
                      order.cancelBefore!.isBefore(DateTime.now())) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: OutlinedButton(
                        onPressed: () => _requestWebCancellation(context, order),
                        style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.orange.shade700), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), foregroundColor: Colors.orange.shade700),
                        child: Text('orders.request_cancellation'.tr(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                  if (order.status == 'cancellation_requested') ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.withValues(alpha: 0.3))),
                      child: Row(children: [
                        Icon(Icons.hourglass_top_rounded, color: Colors.orange.shade700, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text('orders.cancellation_under_review'.tr(), style: TextStyle(fontSize: 13, color: Colors.orange.shade800))),
                      ]),
                    ),
                  ],
                  // ── Awaiting payment: retry / back-to-cart (BNPL & online) ──
                  if (order.isAwaitingPayment) ...[
                    const SizedBox(height: 12),
                    OrderPaymentRecoveryCard(order: order),
                  ],
                ],
              );

              if (isNarrow) {
                // ── Single column on narrow / mobile viewports ────────────
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (splitBanner != null) ...[splitBanner, const SizedBox(height: 16)],
                    headerCard,
                    const SizedBox(height: 16),
                    if (driverCard != null) ...[driverCard, const SizedBox(height: 16)],
                    productsSection,
                    const SizedBox(height: 16),
                    shippingCard,
                    const SizedBox(height: 20),
                    actionsColumn(),
                    const SizedBox(height: 32),
                  ],
                );
              }

              // ── Two-column on wide viewports ──────────────────────────
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (splitBanner != null) ...[splitBanner, const SizedBox(height: 16)],
                        headerCard,
                        const SizedBox(height: 20),
                        if (driverCard != null) ...[driverCard, const SizedBox(height: 20)],
                        productsSection,
                        const SizedBox(height: 20),
                        shippingCard,
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 2,
                    child: actionsColumn(),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    ); // end SingleChildScrollView
    }); // end LayoutBuilder
  }


  void _showWebCancelDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        title: Text('orders.cancel'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text('orders.cancel_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<OrdersCubit>().cancelOrder(orderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            child: Text('orders.cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _requestWebCancellation(BuildContext context, OrderEntity order) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('orders.request_cancellation'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('orders.cancellation_reason_hint'.tr(), style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'orders.cancellation_reason_placeholder'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              final ok = await context.read<OrdersCubit>().requestCancellation(order.id, reason);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'orders.cancellation_submitted'.tr() : 'orders.cancellation_failed'.tr()),
                  backgroundColor: ok ? Colors.orange : Colors.red,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            child: Text('orders.submit_cancellation'.tr()),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WEB PAGE HEADER — order details
// ═══════════════════════════════════════════════════════════════════════════════

class _WebPageHeader extends StatelessWidget {
  final OrderEntity order;
  const _WebPageHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenW = MediaQuery.sizeOf(context).width;
    final isSmall = screenW < 500;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon badge
        Container(
          width: isSmall ? 36 : 44,
          height: isSmall ? 36 : 44,
          decoration: BoxDecoration(
            color: ColorsManager.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.receipt_long_rounded, color: ColorsManager.primaryColor, size: isSmall ? 18 : 22),
        ),
        SizedBox(width: isSmall ? 10 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'orders.details.title'.tr(),
                style: TextStyle(
                  fontSize: isSmall ? 17 : 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0D0D14),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                order.orderNumber,
                style: TextStyle(
                  fontSize: isSmall ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: ColorsManager.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ORDER HEADER CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _OrderHeaderCard extends StatelessWidget {
  final OrderEntity order;

  const _OrderHeaderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final h = AppSizeHorizontal.instance;
    final v = AppSizeVertical.instance;
    final t = TextSizeApp.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(h.s16),
      decoration: BoxDecoration(
        color: isDark ? ColorsManager.surfaceDarkCard : ColorsManager.inputSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorsManager.inputBorder.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.defaultText.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Selectable(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${'orders.order_number'.tr()}:',
                      style: TextStyle(
                        fontSize: 12,
                        color: ColorsManager.defaultTextSecondary,
                      ),
                    ),
                    SizedBox(height: v.s4),
                    Text(
                      order.orderNumber,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ColorsManager.defaultText,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  OrderStatusBadge(status: order.status),
              // Show latest return status badge (includes rejected)
              if (order.returns.isNotEmpty) ...[
                SizedBox(height: v.s8),
                Builder(builder: (_) {
                  final latest = order.returns.first; // API returns newest first
                  final st = latest.status;
                  final isRejected = st == 'rejected';
                  final isGood = st == 'approved' || st == 'refunded' || st == 'closed';
                  final bg = isRejected
                      ? Colors.red.withValues(alpha: 0.15)
                      : isGood
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.amber.withValues(alpha: 0.15);
                  final bc = isRejected
                      ? Colors.red.withValues(alpha: 0.5)
                      : isGood
                          ? Colors.green.withValues(alpha: 0.5)
                          : Colors.amber.withValues(alpha: 0.5);
                  final fc = isRejected
                      ? Colors.red
                      : isGood
                          ? Colors.green
                          : Colors.amber.shade700;
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: h.s8, vertical: v.s4),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: bc),
                    ),
                    child: Text(
                      'orders.return_status.$st'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: fc,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ],
                  if (order.status == 'delivered' && order.pointsEarned > 0) ...[
                    SizedBox(height: v.s8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: h.s8, vertical: v.s4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1C40F).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1C40F).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events_rounded, size: t.s14, color: const Color(0xFFF1C40F)),
                          SizedBox(width: h.s4),
                          Text(
                            'orders.points_earned_badge'
                                .tr(namedArgs: {'count': order.pointsEarned.toString()}),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFF39C12),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          Divider(
            height: v.s24,
            color: ColorsManager.inputBorder.withValues(alpha: 0.2),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DetailItem(
                icon: Icons.calendar_today_outlined,
                label: 'orders.date'.tr(),
                value: DateFormat('dd MMMM yyyy', context.locale.languageCode).format(order.createdAt),
              ),
              _DetailItem(
                icon: Icons.access_time,
                label: 'orders.time'.tr(),
                value: DateFormat('HH:mm').format(order.createdAt),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DETAIL ITEM
// ═══════════════════════════════════════════════════════════════════════════════

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final h = AppSizeHorizontal.instance;

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: ColorsManager.defaultTextSecondary,
        ),
        SizedBox(width: h.s8),
        Selectable(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: ColorsManager.defaultTextSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ColorsManager.defaultText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PRODUCTS SECTION
// ═══════════════════════════════════════════════════════════════════════════════

class _ProductsSection extends StatelessWidget {
  final List<OrderItemEntity> items;

  const _ProductsSection({required this.items});

  @override
  Widget build(BuildContext context) {
    final h = AppSizeHorizontal.instance;
    final v = AppSizeVertical.instance;
    final t = TextSizeApp.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(h.s16),
      decoration: BoxDecoration(
        color: isDark ? ColorsManager.surfaceDarkCard : ColorsManager.inputSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorsManager.inputBorder.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${items.length} ${'orders.items_count'.tr()}',
                style: const TextStyle(
                  fontSize: 12,
                  color: ColorsManager.defaultTextSecondary,
                ),
              ),
              Text(
                'orders.products.title'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorsManager.defaultText,
                ),
              ),
            ],
          ),
          SizedBox(height: v.s16),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: v.s12),
              child: OrderProductItem(item: item),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHIPPING INFO CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _ShippingInfoCard extends StatelessWidget {
  final OrderEntity order;

  const _ShippingInfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final h = AppSizeHorizontal.instance;
    final v = AppSizeVertical.instance;
    final t = TextSizeApp.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(h.s16),
      decoration: BoxDecoration(
        color: isDark ? ColorsManager.surfaceDarkCard : ColorsManager.inputSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorsManager.inputBorder.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'orders.shipping_info.title'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorsManager.defaultText,
            ),
          ),
          SizedBox(height: v.s16),
          _ShippingRow(
            icon: Icons.location_on_outlined,
            title: 'orders.shipping_info.address'.tr(),
            value: order.shippingAddress,
          ),
          SizedBox(height: v.s12),
          _ShippingRow(
            icon: Icons.phone_outlined,
            title: 'orders.shipping_info.phone'.tr(),
            value: order.phone,
          ),
          SizedBox(height: v.s12),
          _ShippingRow(
            icon: Icons.payment_outlined,
            title: 'orders.shipping_info.payment'.tr(),
            value: order.paymentMethod,
          ),
        ],
      ),
    );
  }
}

class _ShippingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ShippingRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final h = AppSizeHorizontal.instance;
    final v = AppSizeVertical.instance;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(h.s8),
          decoration: BoxDecoration(
            color: ColorsManager.primaryColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: ColorsManager.primaryColor,
          ),
        ),
        SizedBox(width: h.s12),
        Expanded(
          child: Selectable(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ColorsManager.defaultTextSecondary,
                  ),
                ),
                SizedBox(height: v.s2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ColorsManager.defaultText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SPLIT ORDER BANNER
// Shown when this order is part of a multi-group (split) shipment.
// ═══════════════════════════════════════════════════════════════════════════════

class _SplitOrderBanner extends StatelessWidget {
  final List<String> relatedOrders;
  /// Ids matching [relatedOrders] by index. The chip shows the order_number but
  /// must route by id — GET /orders/{id} resolves the primary key, not the number.
  final List<String>? relatedOrderIds;

  const _SplitOrderBanner({required this.relatedOrders, this.relatedOrderIds});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final h = AppSizeHorizontal.instance;
    final v = AppSizeVertical.instance;

    return Container(
      margin: EdgeInsets.only(bottom: v.s16),
      padding: EdgeInsets.all(h.s14),
      decoration: BoxDecoration(
        color: ColorsManager.primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: ColorsManager.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.call_split_rounded,
                  size: 16, color: ColorsManager.primaryColor),
              SizedBox(width: h.s8),
              Expanded(
                child: Text(
                  'orders.split_order_notice'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: v.s8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: relatedOrders
                .asMap()
                .entries
                .map(
                  (e) {
                    final orderNum = e.value;
                    final id = (relatedOrderIds != null &&
                            e.key < relatedOrderIds!.length)
                        ? relatedOrderIds![e.key]
                        : null;
                    return GestureDetector(
                    onTap: id == null
                        ? null
                        : () => Navigator.pushNamed(
                              context,
                              '${Routes.orderDetails}/$id',
                            ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: h.s10, vertical: v.s4),
                      decoration: BoxDecoration(
                        color: ColorsManager.primaryColor
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: ColorsManager.primaryColor
                                .withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        orderNum,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ColorsManager.primaryColor,
                        ),
                      ),
                    ),
                  );
                  },
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DRIVER INFO CARD
// Shown when a delivery driver has been assigned to this order.
// ═══════════════════════════════════════════════════════════════════════════════

class _DriverInfoCard extends StatelessWidget {
  final String driverName;
  final String? driverPhone;

  const _DriverInfoCard({required this.driverName, this.driverPhone});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final h = AppSizeHorizontal.instance;
    final v = AppSizeVertical.instance;

    return Container(
      padding: EdgeInsets.all(h.s16),
      decoration: BoxDecoration(
        color: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: ColorsManager.primaryColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ColorsManager.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delivery_dining_rounded,
                color: ColorsManager.primaryColor, size: 24),
          ),
          SizedBox(width: h.s14),
          Expanded(
            child: Selectable(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'orders.tracking.your_driver'.tr(),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: v.s2),
                  Text(
                    driverName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (driverPhone != null)
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: h.s12, vertical: v.s8),
              decoration: BoxDecoration(
                color: ColorsManager.primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone_rounded,
                      size: 14, color: Colors.white),
                  SizedBox(width: h.s6),
                  Text(
                    driverPhone!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CANCELLATION COUNTDOWN (E-23)
// ═══════════════════════════════════════════════════════════════════════════════

class _CancellationCountdown extends StatefulWidget {
  final DateTime deadline;
  final Widget button;
  const _CancellationCountdown({required this.deadline, required this.button});

  @override
  State<_CancellationCountdown> createState() => _CancellationCountdownState();
}

class _CancellationCountdownState extends State<_CancellationCountdown> {
  Duration _remaining = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final r = widget.deadline.difference(DateTime.now());
    if (mounted) setState(() => _remaining = r.isNegative ? Duration.zero : r);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expired = _remaining == Duration.zero;
    final hh = _remaining.inHours.toString().padLeft(2, '0');
    final mm = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: expired ? const EdgeInsets.symmetric(vertical: 4) : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: expired ? Colors.transparent : (isDark ? Colors.orange.shade900.withValues(alpha: 0.3) : Colors.orange.shade50),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: expired ? Colors.transparent : Colors.orange.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Icon(
                expired ? Icons.info_outline : Icons.timer_outlined,
                size: 18,
                color: expired ? Colors.grey.shade500 : Colors.orange.shade800,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: expired
                    ? Text(
                        'orders.cancellationWindowClosed'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                        ),
                      )
                    : RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: 'orders.cancelWithin'.tr(),
                            style: TextStyle(fontSize: 13, color: Colors.orange.shade800),
                          ),
                          TextSpan(
                            text: ' $hh:$mm:$ss',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ]),
                      ),
              ),
            ],
          ),
        ),
        if (!expired) widget.button,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Invoice Button — opens a native, localized invoice view (no PDF/HTML).
// ─────────────────────────────────────────────────────────────────────────────

class _InvoiceButton extends StatelessWidget {
  final OrderEntity order;

  const _InvoiceButton({required this.order});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InvoiceScreen(order: order),
          ),
        ),
        icon: const Icon(Icons.receipt_long_rounded, size: 18),
        label: Text(
          'orders.view_invoice'.tr(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: ColorsManager.primaryColor.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          foregroundColor: ColorsManager.primaryColor,
        ),
      ),
    );
  }
}


