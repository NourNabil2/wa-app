// lib/features/orders/presentation/screens/order_tracking_screen.dart

import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/layout/simple_web_shell.dart';
import 'package:fastway/core/responsive/responsive_layout.dart';
import 'package:fastway/core/services/app_settings_service.dart';
import 'package:fastway/core/widgets/app_buton.dart';
import 'package:fastway/core/widgets/sar_symbol.dart';
import 'package:fastway/core/widgets/skeletons.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fastway/core/widgets/selectable.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_snack_bar.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../domain/entities/order_entity.dart';
import '../cubit/orders_cubit.dart';
import '../cubit/orders_state.dart';
import '../widgets/order_product_item.dart';
import '../widgets/order_summary_section.dart';
import '../widgets/return_request_sheet.dart';
import '../widgets/return_status_modal.dart';
import '../widgets/rate_order_sheet.dart';
import '../widgets/my_order_reviews_card.dart';
import '../widgets/order_payment_recovery_card.dart';

bool _canRateOrderTracking(OrderEntity order) {
  if (order.status != 'delivered') return false;
  return !order.storeReviewed ||
      !order.shipmentReviewed ||
      order.items.any((i) => !i.reviewed && i.productId.isNotEmpty);
}

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrdersCubit>().trackOrder(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0C) : const Color(0xFFF4F6F9),
      appBar: kIsWeb
          ? null
          : CustomAppBar(
        title: 'orders.tracking.title'.tr(),
        centerTitle: true,
        showBackIcon: true,
        isTransparent: true,
      ),
      extendBodyBehindAppBar: !kIsWeb,
      body: BlocConsumer<OrdersCubit, OrdersState>(
        listener: (context, state) {
          if (state is OrderTrackingError) {
            CustomSnackBar.show(context, message: state.failure.message, type: SnackBarType.error);
          } else if (state is OrderCanceled) {
            CustomSnackBar.show(context, message: 'orders.cancel_success'.tr());
            context.read<OrdersCubit>().trackOrder(widget.orderId);
          } else if (state is OrderCancelError) {
            CustomSnackBar.show(context, message: state.failure.message, type: SnackBarType.error);
          }
        },
        builder: (context, state) {
          if (state is OrderTrackingLoading) return const Center(child: GenericPageSkeleton());

          if (state is OrderTrackingError) {
            return ErrorStateWidget(
              failure: state.failure,
              onRetry: () => context.read<OrdersCubit>().trackOrder(widget.orderId),
            );
          }

          if (state is OrderTrackingLoaded) {
            if (kIsWeb) {
              return SimpleWebShell(content: _WebTrackingContent(order: state.order));
            }
            return _MobileTrackingContent(order: state.order);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOBILE TRACKING CONTENT — Map + DraggableScrollableSheet
// ═══════════════════════════════════════════════════════════════════════════════

class _MobileTrackingContent extends StatefulWidget {
  final OrderEntity order;

  const _MobileTrackingContent({required this.order});

  @override
  State<_MobileTrackingContent> createState() => _MobileTrackingContentState();
}

class _MobileTrackingContentState extends State<_MobileTrackingContent> {
  // Default center: Riyadh. Replace with real coords when the API exposes them.
  static const LatLng _defaultCenter = LatLng(24.7136, 46.6753);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.paddingOf(context).top + kToolbarHeight;

    final LatLng deliveryPos = widget.order.deliveryLat != null && widget.order.deliveryLng != null
        ? LatLng(widget.order.deliveryLat!, widget.order.deliveryLng!)
        : _defaultCenter;

    final LatLng? warehousePos = widget.order.warehouseLat != null && widget.order.warehouseLng != null
        ? LatLng(widget.order.warehouseLat!, widget.order.warehouseLng!)
        : null;

    return Stack(
      children: [
        // ── 1. FlutterMap (full-screen background) ─────────────────────────
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: deliveryPos,
              zoom: 13,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('delivery'),
                position: deliveryPos,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              ),
              if (warehousePos != null)
                Marker(
                  markerId: const MarkerId('warehouse'),
                  position: warehousePos,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                ),
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
        ),



        // ── 3. DraggableScrollableSheet ────────────────────────────────────
        DraggableScrollableSheet(
          initialChildSize: 0.48,
          minChildSize: 0.28,
          maxChildSize: 0.92,
          snap: true,
          snapSizes: const [0.28, 0.48, 0.72, 0.92],
          builder: (ctx, scrollController) {
            return _TrackingBottomSheet(
              order: widget.order,
              scrollController: scrollController,
            );
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BOTTOM SHEET CONTENT
// ═══════════════════════════════════════════════════════════════════════════════

class _TrackingBottomSheet extends StatelessWidget {
  final OrderEntity order;
  final ScrollController scrollController;

  const _TrackingBottomSheet({
    required this.order,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.locale.languageCode == 'ar';

    final String currentStatusTitle = _resolveStatusTitle(order, isArabic);
    final Color statusColor = _statusColor(order.status);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F12) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          children: [
            // ── Drag handle ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            // ── Status headline + order number ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_statusIcon(order.status), color: statusColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentStatusTitle,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0D0D14),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.tag_rounded, size: 13, color: isDark ? Colors.grey[400] : Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              order.orderNumber,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Horizontal Stepper ────────────────────────────────────────────
            if (order.timeline != null && order.timeline!.isNotEmpty)
              _HorizontalOrderStepper(timeline: order.timeline!, isArabic: isArabic),

            // ── Scrollable body ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Driver badge
                  if (order.driverName != null) ...[
                    _DriverBadgeCard(
                      driverName: order.driverName!,
                      driverPhone: order.driverPhone,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Split order alert
                  if (order.relatedOrders?.isNotEmpty == true) ...[
                    _SplitOrderAlert(relatedOrders: order.relatedOrders!),
                    const SizedBox(height: 16),
                  ],

                  // Products section
                  _SheetProductsSection(items: order.items),
                  const SizedBox(height: 16),

                  // Order Summary
                  OrderSummarySection(order: order),
                const SizedBox(height: 16),

                // ── Action buttons ─────────────────────────────────────────

                // Reorder (delivered)
                if (order.status == 'delivered') ...[
                  AppButton(
                    text: 'orders.reorder'.tr(),
                    onPressed: () => context.read<OrdersCubit>().reorderOrder(order.id),
                    horizontalPadding: 0,
                    verticalPadding: 0,
                    backgroundColor: ColorsManager.primaryColor.withValues(alpha: 0.1),
                    textColor: ColorsManager.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  // Rate order
                  if (_canRateOrderTracking(order)) ...[
                    SizedBox(
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
                    ),
                    const SizedBox(height: 12),
                  ],
                  MyOrderReviewsCard(order: order),
                  const SizedBox(height: 12),
                  // Return
                  if (!order.fullyReturned &&
                      AppSettingsService.instance.canReturn(order.deliveredAt ?? order.createdAt))
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => ReturnRequestSheet.show(context, order),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          foregroundColor: Colors.red,
                        ),
                        child: Text('orders.request_return'.tr(),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  if (order.returns.isNotEmpty)
                    ...order.returns.asMap().entries.map((e) {
                      final ret = e.value;
                      final label = order.returns.length > 1
                          ? (e.key == 0
                              ? '${'orders.view_return'.tr()} (Latest)'
                              : '#${order.returns.length - e.key} ${'orders.view_return'.tr()}')
                          : 'orders.view_return'.tr();
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
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
                            child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                          ),
                        ),
                      );
                    }),
                ],

                // Cancel (pending)
                if (order.status == 'pending') ...[
                  const SizedBox(height: 12),
                  BlocBuilder<OrdersCubit, OrdersState>(
                    builder: (context, state) {
                      final isCanceling = state is OrderCanceling;
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: isCanceling ? null : () => _showCancelDialog(context, order.id),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            foregroundColor: Colors.red,
                          ),
                          child: isCanceling
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                              : Text('orders.cancel'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      );
                    },
                  ),
                ],

                // Request cancellation (processing)
                if (order.status == 'processing') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => _showRequestCancellationSheet(context, order),
                      icon: const Icon(Icons.pending_actions_rounded, size: 20),
                      label: Text('orders.request_cancellation'.tr(),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.orange.shade700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        foregroundColor: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],

                // Cancellation requested banner
                if (order.status == 'cancellation_requested') ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.hourglass_top_rounded, color: Colors.orange.shade700, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('orders.cancellation_requested'.tr(),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.orange.shade800)),
                          const SizedBox(height: 4),
                          Text('orders.cancellation_under_review'.tr(),
                              style: TextStyle(fontSize: 12, color: Colors.orange.shade700, height: 1.4)),
                        ]),
                      ),
                    ]),
                  ),
                ],

                // Returns section
                if (order.returns.isNotEmpty && order.status != 'delivered')
                  ...order.returns.asMap().entries.map((e) {
                    final idx = e.key;
                    final ret = e.value;
                    final label = order.returns.length > 1
                        ? '${idx == 0 ? 'Latest' : '#${order.returns.length - idx}'} Return'
                        : null;
                    return Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: _ReturnStatusCard(returnRequest: ret, label: label),
                    );
                  }),

                // Awaiting payment
                if (order.isAwaitingPayment) ...[
                  const SizedBox(height: 12),
                  OrderPaymentRecoveryCard(order: order),
                ],

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/orders/${order.id}'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      foregroundColor: isDark ? Colors.white : Colors.black,
                    ),
                    child: Text('orders.view_details'.tr(),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
     ),
    );
  }

  String _resolveStatusTitle(OrderEntity order, bool isArabic) {
    final hasEstimate = order.deliveryEstimate != null && order.deliveryEstimate!.isNotEmpty;
    String title = order.statusDisplayName.tr();
    if (!hasEstimate && order.timeline != null && order.timeline!.isNotEmpty) {
      final done = order.timeline!.where((s) => s.isCompleted).toList();
      if (done.isNotEmpty) {
        final last = done.last;
        title = (isArabic && last.titleAr != null) ? last.titleAr! : last.title;
      }
    }
    return title;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered': return const Color(0xFF059669);
      case 'cancelled': return Colors.red;
      case 'cancellation_requested': return Colors.orange;
      default: return ColorsManager.primary2Color;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'delivered': return Icons.check_circle_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      case 'cancellation_requested': return Icons.pending_actions_rounded;
      case 'out_for_delivery': return Icons.delivery_dining_rounded;
      case 'shipped': return Icons.local_shipping_rounded;
      case 'processing': return Icons.inventory_2_rounded;
      default: return Icons.receipt_long_rounded;
    }
  }

  void _showCancelDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('orders.cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showRequestCancellationSheet(BuildContext context, OrderEntity order) {
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
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 20),
            Text('orders.request_cancellation'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('orders.cancellation_reason_hint'.tr(), style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'orders.cancellation_reason_placeholder'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
// HORIZONTAL ORDER STEPPER — matches the screenshot design
// ═══════════════════════════════════════════════════════════════════════════════

class _HorizontalOrderStepper extends StatelessWidget {
  final List<OrderTimelineEntity> timeline;
  final bool isArabic;

  const _HorizontalOrderStepper({required this.timeline, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (timeline.isEmpty) return const SizedBox.shrink();

    // Find the active index (first incomplete, or last if all done)
    int activeIndex = timeline.indexWhere((s) => !s.isCompleted);
    if (activeIndex == -1) activeIndex = timeline.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // ── Progress line + dots row ─────────────────────────────────────
          SizedBox(
            height: 48,
            child: Row(
              children: List.generate(timeline.length, (i) {
                final step = timeline[i];
                final isFirst = i == 0;
                final isLast = i == timeline.length - 1;
                final isCompleted = step.isCompleted;
                final isActive = i == activeIndex;

                final dotColor = isCompleted || isActive
                    ? ColorsManager.primary2Color
                    : (isDark ? Colors.white12 : Colors.grey.shade300);

                return Expanded(
                  child: Row(
                    children: [
                      // Left line segment
                      if (!isFirst)
                        Expanded(
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: timeline[i - 1].isCompleted
                                  ? ColorsManager.primary2Color.withValues(alpha: 0.7)
                                  : (isDark ? Colors.white12 : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),

                      // Dot
                      Container(
                        width: isActive ? 28 : 22,
                        height: isActive ? 28 : 22,
                        decoration: BoxDecoration(
                          color: isActive
                              ? ColorsManager.primary2Color
                              : (isCompleted
                                  ? ColorsManager.primary2Color.withValues(alpha: 0.18)
                                  : (isDark ? const Color(0xFF2A2A2E) : Colors.grey.shade100)),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: dotColor,
                            width: isActive ? 0 : 2,
                          ),
                        ),
                        child: Icon(
                          _iconForStatus(step.status),
                          size: isActive ? 16 : 12,
                          color: isActive
                              ? Colors.white
                              : (isCompleted
                                  ? ColorsManager.primary2Color
                                  : (isDark ? Colors.grey[600] : Colors.grey[400])),
                        ),
                      ),

                      // Right line segment
                      if (!isLast)
                        Expanded(
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? ColorsManager.primary2Color.withValues(alpha: 0.7)
                                  : (isDark ? Colors.white12 : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),

          // ── Labels row ────────────────────────────────────────────────────
          Row(
            children: List.generate(timeline.length, (i) {
              final step = timeline[i];
              final isActive = i == activeIndex;
              final label = (isArabic && step.titleAr != null) ? step.titleAr! : step.title;

              // Timestamp
              String timeStr = '';
              if (step.timestamp != null) {
                timeStr = DateFormat('hh:mm a').format(step.timestamp!);
              }

              return Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                        color: isActive
                            ? ColorsManager.primary2Color
                            : (step.isCompleted
                                ? (isDark ? Colors.white70 : Colors.black87)
                                : (isDark ? Colors.grey[600] : Colors.grey[400])),
                      ),
                    ),
                    if (timeStr.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        timeStr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  IconData _iconForStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
      case 'order_placed':
        return Icons.receipt_long_rounded;
      case 'processing':
        return Icons.inventory_2_rounded;
      case 'shipped':
        return Icons.local_shipping_rounded;
      case 'out_for_delivery':
        return Icons.delivery_dining_rounded;
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.radio_button_unchecked_rounded;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHEET PRODUCTS SECTION
// ═══════════════════════════════════════════════════════════════════════════════

class _SheetProductsSection extends StatelessWidget {
  final List<OrderItemEntity> items;
  const _SheetProductsSection({required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A20) : const Color(0xFFF9F9FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${items.length} ${'orders.items_count'.tr()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  'orders.products.title'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0D0D14),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OrderProductItem(item: item),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
// CREATIVE ORDER STEPPER (TIMELINE) 🔥
// ═══════════════════════════════════════════════════════════════════════════════

class _CreativeOrderStepper extends StatelessWidget {
  final List<OrderTimelineEntity> timeline;

  const _CreativeOrderStepper({required this.timeline});

  IconData _getIconForStatus(String? status, bool isCompleted) {
    switch (status?.toLowerCase()) {
      case 'pending':
      case 'order_placed':
        return Icons.receipt_long_rounded;
      case 'processing':
        return Icons.inventory_2_rounded;
      case 'shipped':
        return Icons.local_shipping_rounded;
      case 'out_for_delivery':
        return Icons.delivery_dining_rounded;
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'cancellation_requested':
        return Icons.pending_actions_rounded;
      case 'return_requested':
      case 'return_approved':
      case 'return_picked_up':
        return Icons.assignment_return_rounded;
      case 'refunded':
        return Icons.savings_rounded;
      default:
        return isCompleted ? Icons.check_rounded : Icons.radio_button_unchecked_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.locale.languageCode == 'ar';

    // نجيب النقطة النشطة حالياً (أول نقطة لم تكتمل، أو الأخيرة لو كله اكتمل)
    int activeIndex = timeline.indexWhere((step) => step.isCompleted == false);
    if (activeIndex == -1) activeIndex = timeline.length - 1;

    return Container(
      padding: EdgeInsets.all(kIsWeb ? 20 : 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13131F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'orders.tracking.title'.tr(),
            style: TextStyle(
              fontSize: kIsWeb ? 18 : 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0D0D14),
            ),
          ),
          SizedBox(height: kIsWeb ? 20 : 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: timeline.length,
            itemBuilder: (context, index) {
              final step = timeline[index];
              final isLast = index == timeline.length - 1;
              final isCompleted = step.isCompleted;
              final isActive = index == activeIndex;

              // قراءة التاريخ من المتغير الصحيح `timestamp`
              String timeStr = '--:--';
              String dateStr = '';
              if (step.timestamp != null) {
                final dt = step.timestamp!;
                timeStr = DateFormat('hh:mm a').format(dt);
                dateStr = DateFormat('dd MMM').format(dt);
              }

              // تحديد النص حسب اللغة
              final title = (isArabic && step.titleAr != null) ? step.titleAr! : step.title;
              final desc = (isArabic && step.descriptionAr != null) ? step.descriptionAr! : step.description;

              final double timeWidth = kIsWeb ? 65.0 : 55;
              final double nodeSize = 34;
              final double lineStart = timeWidth + 8 + (nodeSize / 2) - (2.5 / 2);

              return Stack(
                children: [
                  if (!isLast)
                    Positioned(
                      top: nodeSize,
                      bottom: 0,
                      left: isArabic ? null : lineStart,
                      right: isArabic ? lineStart : null,
                      child: Container(
                        width: 2.5,
                        margin: EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? ColorsManager.primary2Color.withValues(alpha: 0.5)
                              : (isDark ? Colors.white12 : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Time Column
                      SizedBox(
                        width: timeWidth,
                        child: Selectable(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: kIsWeb ? 12 : 12,
                                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                                color: isActive ? ColorsManager.primary2Color : (isDark ? Colors.grey[400] : Colors.grey[500]),
                              ),
                            ),
                            if (dateStr.isNotEmpty)
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: kIsWeb ? 10 : 10,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                                ),
                              ),
                          ],
                        ),
                        ),
                      ),

                      SizedBox(width: 8),

                      // 2. Visual Node
                      SizedBox(
                        width: nodeSize,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: _TimelineNode(
                            icon: _getIconForStatus(step.status, isCompleted),
                            isCompleted: isCompleted,
                            isActive: isActive,
                          ),
                        ),
                      ),

                      SizedBox(width: kIsWeb ? 12 : 16),

                      // 3. Content Details
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : (kIsWeb ? 28 : 36)),
                          child: Selectable(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 10,
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: kIsWeb ? 14 : 15,
                                  fontWeight: isActive || isCompleted ? FontWeight.w800 : FontWeight.w600,
                                  color: isActive
                                      ? ColorsManager.primary2Color
                                      : (isCompleted
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : (isDark ? Colors.grey[600] : Colors.grey[400])),
                                ),
                              ),
                              if (desc.isNotEmpty) ...[
                              SizedBox(height: kIsWeb ? 4 : 4),
                              Text(
                                desc,
                                maxLines: 10,
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: kIsWeb ? 12 : 12,
                                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                                  height: 1.4,
                                ),
                              ),
                            ]
                            ],
                          ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final IconData icon;
  final bool isCompleted;
  final bool isActive;

  const _TimelineNode({required this.icon, required this.isCompleted, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isActive) {
      // 🌟 Active Node (Pulsing Glow)
      return Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: ColorsManager.primary2Color,
          shape: BoxShape.circle,
          // BoxShadow removed from step icon
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      );
    }

    if (isCompleted) {
      // ✅ Completed Node
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: ColorsManager.primary2Color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: ColorsManager.primary2Color, size: 16),
      );
    }

    // ⚪ Future Node
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
        shape: BoxShape.circle,
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!, width: 2),
      ),
      child: Icon(icon, color: isDark ? Colors.grey[700] : Colors.grey[300], size: 16),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HERO STATUS CARD — Dynamic based on Delivery Estimate
// ═══════════════════════════════════════════════════════════════════════════════

class _HeroStatusCard extends StatelessWidget {
  final OrderEntity order;

  const _HeroStatusCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // On mobile the AppBar is present + extendBodyBehindAppBar, so we need the full top offset.
    // On web (no AppBar), just use the safe area top padding.
    final hasMobileAppBar = isMobileLayout(context);
    final topPad = MediaQuery.paddingOf(context).top + (hasMobileAppBar ? kToolbarHeight : 0);
    final isArabic = context.locale.languageCode == 'ar';

    // إزالة "جاري الحساب": نعتمد فقط على البيانات الحقيقية من السيرفر
    final hasEstimate = order.deliveryEstimate != null && order.deliveryEstimate!.isNotEmpty;

    // في حالة عدم وجود وقت، نعرض عنوان آخر خطوة اكتملت
    String currentStatusTitle = order.statusDisplayName.tr();
    if (!hasEstimate && order.timeline != null && order.timeline!.isNotEmpty) {
      final activeSteps = order.timeline!.where((s) => s.isCompleted).toList();
      if (activeSteps.isNotEmpty) {
        final lastStep = activeSteps.last;
        currentStatusTitle = (isArabic && lastStep.titleAr != null) ? lastStep.titleAr! : lastStep.title;
      }
    }

    // Status-specific colour and icon overrides
    final isOutForDelivery = order.status == 'out_for_delivery';
    final isCancellationRequested = order.status == 'cancellation_requested';
    final isCancelled = order.status == 'cancelled';
    final isDelivered = order.status == 'delivered';

    // Gradient colours per status
    final List<Color> gradientColors = isCancellationRequested
        ? (isDark
            ? [const Color(0xFF1A0E00), Colors.orange.withValues(alpha: 0.65)]
            : [Colors.orange.shade700, Colors.amber.shade600])
        : isCancelled
            ? (isDark
                ? [const Color(0xFF1A0000), Colors.red.withValues(alpha: 0.55)]
                : [const Color(0xFFDC2626), const Color(0xFFEF4444)])
            : isDelivered
                ? (isDark
                    ? [const Color(0xFF001A0E), const Color(0xFF10B981).withValues(alpha: 0.6)]
                    : [const Color(0xFF059669), const Color(0xFF10B981)])
                : isDark
                    ? [const Color(0xFF0E0E18), ColorsManager.primary2Color.withValues(alpha: 0.55)]
                    : [ColorsManager.primary2Color, ColorsManager.primary2Color.withValues(alpha: 0.85)];



    final IconData bgIcon = isCancellationRequested
        ? Icons.pending_actions_rounded
        : isCancelled
            ? Icons.cancel_rounded
            : isDelivered
                ? Icons.check_circle_rounded
                : isOutForDelivery || hasEstimate
                    ? Icons.delivery_dining_rounded
                    : Icons.inventory_2_rounded;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 24, 24, 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -8,
            bottom: -8,
            child: Icon(
              bgIcon,
              size: 130,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Text(
                  'orders.tracking.current_status'.tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 14),

              Text(
                currentStatusTitle,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),

              SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.tag_rounded, color: Colors.white70, size: 14),
                  ),
                  SizedBox(width: 8),
                  Text(
                    order.orderNumber,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DRIVER BADGE CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _DriverBadgeCard extends StatelessWidget {
  final String driverName;
  final String? driverPhone;

  const _DriverBadgeCard({required this.driverName, this.driverPhone});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13131F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      ColorsManager.primary2Color.withValues(alpha: 0.15),
                      ColorsManager.primary2Color.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: ColorsManager.primary2Color.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Icon(Icons.electric_moped_rounded, color: ColorsManager.primary2Color, size: 26),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? const Color(0xFF13131F) : Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'orders.tracking.your_driver'.tr(),
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[500], fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 3),
                Text(
                  driverName,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0D0D14)),
                ),
              ],
            ),
          ),
          if (driverPhone != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: driverPhone!));
                  CustomSnackBar.show(context, message: 'orders.tracking.driver_copied'.tr(), type: SnackBarType.success);
                },
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  padding: EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary2Color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.phone_in_talk_rounded, color: ColorsManager.primary2Color, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SPLIT ORDER ALERT
// ═══════════════════════════════════════════════════════════════════════════════

class _SplitOrderAlert extends StatelessWidget {
  final List<String> relatedOrders;

  const _SplitOrderAlert({required this.relatedOrders});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1608) : const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.call_split_rounded, color: const Color(0xFFFF9800), size: 16),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'orders.split_order_notice'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFFFCC80) : const Color(0xFF7A4500),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: relatedOrders.map((num) => InkWell(
              onTap: () => Clipboard.setData(ClipboardData(text: num)),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tag_rounded, size: 11, color: const Color(0xFFFF9800)),
                    SizedBox(width: 3),
                    Text(
                      num,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFFFCC80) : const Color(0xFF7A4500)),
                    ),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WEB TRACKING CONTENT
// ═══════════════════════════════════════════════════════════════════════════════

class _WebTrackingContent extends StatelessWidget {
  final OrderEntity order;

  const _WebTrackingContent({required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: (MediaQuery.sizeOf(context).width * 0.95).clamp(0.0, 1100.0)),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0E0E18) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WebHeaderStrip(order: order),
                LayoutBuilder(builder: (context, cs) {
                  final isNarrow = cs.maxWidth < 650;
                  if (isNarrow) {
                    // Override MediaQuery so ScreenUtil (.sp/.w/.h/.r) inside
                    // child widgets compute readable sizes on narrow web screens.
                    // This is applied AFTER LayoutBuilder has decided the path.
                    final mq = MediaQuery.of(context);
                    return MediaQuery(
                      data: mq.copyWith(size: Size(414, mq.size.height)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _WebStatusBanner(order: order),
                            const SizedBox(height: 16),
                            _OrderTrackingMap(order: order, height: 200),
                            if (order.driverName != null) ...[
                              const SizedBox(height: 16),
                              _DriverBadgeCard(driverName: order.driverName!, driverPhone: order.driverPhone),
                            ],
                            if (order.relatedOrders?.isNotEmpty == true) ...[
                              const SizedBox(height: 16),
                              _SplitOrderAlert(relatedOrders: order.relatedOrders!),
                            ],
                            if (order.timeline != null && order.timeline!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _CreativeOrderStepper(timeline: order.timeline!),
                            ],
                            const SizedBox(height: 16),
                            _SheetProductsSection(items: order.items),
                            const SizedBox(height: 16),
                            OrderSummarySection(order: order),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pushNamed(context, '/orders/${order.id}'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                  foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                ),
                                child: Text('orders.view_details'.tr(),
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            if (order.status == 'pending') ...[
                              const SizedBox(height: 16),
                              BlocBuilder<OrdersCubit, OrdersState>(
                                builder: (context, state) {
                                  final isCanceling = state is OrderCanceling;
                                  return SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: OutlinedButton(
                                      onPressed: isCanceling ? null : () => _showWebCancelDialog(context, order.id),
                                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), foregroundColor: Colors.red),
                                      child: isCanceling ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)) : Text('orders.cancel'.tr(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                    ),
                                  );
                                },
                              ),
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    );
                  }
                  // Wide: original two-column Row
                  return Padding(
                    padding: const EdgeInsets.all(36),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              if (order.timeline != null && order.timeline!.isNotEmpty)
                                _CreativeOrderStepper(timeline: order.timeline!),
                              const SizedBox(height: 24),
                              _SheetProductsSection(items: order.items),
                              const SizedBox(height: 24),
                              OrderSummarySection(order: order),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pushNamed(context, '/orders/${order.id}'),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                    foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                  ),
                                  child: Text('orders.view_details'.tr(),
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 36),
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              _HeroStatusCard(order: order),
                              const SizedBox(height: 20),
                              _OrderTrackingMap(order: order, height: 250),
                              const SizedBox(height: 20),
                              if (order.driverName != null) ...[
                                _DriverBadgeCard(driverName: order.driverName!, driverPhone: order.driverPhone),
                                const SizedBox(height: 20),
                              ],
                              if (order.relatedOrders?.isNotEmpty == true)
                                _SplitOrderAlert(relatedOrders: order.relatedOrders!),
                              if (order.status == 'pending') ...[
                                const SizedBox(height: 20),
                                BlocBuilder<OrdersCubit, OrdersState>(
                                  builder: (context, state) {
                                    final isCanceling = state is OrderCanceling;
                                    return SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: OutlinedButton(
                                        onPressed: isCanceling ? null : () => _showWebCancelDialog(context, order.id),
                                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), foregroundColor: Colors.red),
                                        child: isCanceling ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)) : Text('orders.cancel'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showWebCancelDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              shape:  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('orders.cancel'.tr()),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WEB STATUS BANNER — compact flat card for the narrow web layout
// ═══════════════════════════════════════════════════════════════════════════════

class _WebStatusBanner extends StatelessWidget {
  final OrderEntity order;
  const _WebStatusBanner({required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.locale.languageCode == 'ar';
    final hasEstimate = order.deliveryEstimate != null && order.deliveryEstimate!.isNotEmpty;

    String statusTitle = order.statusDisplayName.tr();
    if (!hasEstimate && order.timeline != null && order.timeline!.isNotEmpty) {
      final done = order.timeline!.where((s) => s.isCompleted).toList();
      if (done.isNotEmpty) {
        final last = done.last;
        statusTitle = (isArabic && last.titleAr != null) ? last.titleAr! : last.title;
      }
    }

    final isCancelled = order.status == 'cancelled';
    final isDelivered = order.status == 'delivered';
    final isCancellationRequested = order.status == 'cancellation_requested';

    final Color accentColor = isCancellationRequested
        ? Colors.orange.shade700
        : isCancelled
            ? Colors.red
            : isDelivered
                ? const Color(0xFF059669)
                : ColorsManager.primary2Color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(
              isCancelled ? Icons.cancel_rounded : isDelivered ? Icons.check_circle_rounded : isCancellationRequested ? Icons.pending_actions_rounded : Icons.local_shipping_rounded,
              color: accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'orders.tracking.current_status'.tr(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accentColor.withValues(alpha: 0.75)),
                ),
                const SizedBox(height: 3),
                Text(
                  statusTitle,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0D0D14)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.tag_rounded, size: 13, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(order.orderNumber, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WebHeaderStrip extends StatelessWidget {
  final OrderEntity order;

  const _WebHeaderStrip({required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;

        final iconBadge = Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ColorsManager.primary2Color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.local_shipping_rounded, color: ColorsManager.primary2Color, size: 20),
        );

        final textColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'orders.tracking.title'.tr(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0D0D14), letterSpacing: -0.5),
            ),
            const SizedBox(height: 2),
            Text(
              'orders.tracking.subtitle'.tr(),
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[600]),
              maxLines: 5,
              overflow: TextOverflow.visible,
            ),
          ],
        );

        final orderTag = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: ColorsManager.primary2Color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorsManager.primary2Color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tag_rounded, size: 12, color: ColorsManager.primary2Color),
              const SizedBox(width: 3),
              Selectable(
                child: Text(order.orderNumber, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ColorsManager.primary2Color)),
              ),
            ],
          ),
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorsManager.primary2Color.withValues(alpha: isDark ? 0.25 : 0.08),
                Colors.transparent,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border(
              bottom: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05)),
            ),
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        iconBadge,
                        const SizedBox(width: 12),
                        orderTag,
                      ],
                    ),
                    const SizedBox(height: 12),
                    textColumn,
                  ],
                )
              : Row(
                  children: [
                    iconBadge,
                    const SizedBox(width: 12),
                    Expanded(child: textColumn),
                    const SizedBox(width: 8),
                    orderTag,
                  ],
                ),
        );
      },
    );
  }
}
// ═══════════════════════════════════════════════════════════════════════════════
// RETURN & REFUND STATUS CARD  (Noon/Amazon style — separate track from delivery)
// ═══════════════════════════════════════════════════════════════════════════════

class _ReturnStatusCard extends StatelessWidget {
  final OrderReturnEntity returnRequest;
  final String? label; // e.g. 'Latest Return', '#1 Return' for multi-return orders

  const _ReturnStatusCard({required this.returnRequest, this.label});


  Color get _color => switch (returnRequest.status) {
    'rejected'             => const Color(0xFFDC2626),
    'refunded' || 'closed' => const Color(0xFF059669),
    'approved'             => const Color(0xFF2563EB),
    _                      => const Color(0xFFD97706),
  };

  IconData get _icon => switch (returnRequest.status) {
    'rejected'             => Icons.cancel_rounded,
    'refunded' || 'closed' => Icons.check_circle_rounded,
    'approved'             => Icons.thumb_up_rounded,
    _                      => Icons.swap_horiz_rounded,
  };

  String _statusLabel(bool isAr) => switch (returnRequest.status) {
    'requested' => 'orders.status.requested'.tr(),
    'approved'  => 'orders.status.approved'.tr(),
    'rejected'  => 'orders.status.rejected'.tr(),
    'picked_up' => 'orders.status.picked_up'.tr(),
    'refunded'  => 'orders.status.refunded'.tr(),
    'closed'    => 'orders.status.closed'.tr(),
    _           => returnRequest.status,
  };

  @override
  Widget build(BuildContext context) {
    final isAr  = Localizations.localeOf(context).languageCode == 'ar';
    final color = _color;
    final steps = [
      ('requested', 'orders.steps.requested.title'.tr(), 'orders.steps.requested.title'.tr()),
      ('approved',  'orders.steps.approved.title'.tr(),  'orders.steps.approved.title'.tr()),
      ('picked_up', 'orders.steps.picked_up.title'.tr(), 'orders.steps.picked_up.title'.tr()),
      ('refunded',  'orders.steps.refunded.title'.tr(),  'orders.steps.refunded.title'.tr()),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        // BoxShadow removed
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.zero),
            ),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(_icon, color: Colors.white, size: 22),
              ),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('orders.tracking.return_and_refund'.tr(),
                      style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
                  if (label != null) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                      child: Text(label!, style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ]),
                Text(_statusLabel(isAr),
                    style: TextStyle(fontSize: 15, color: color, fontWeight: FontWeight.bold)),
              ])),
            ]),
          ),

          Padding(
            padding: EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Mini Timeline
              if (returnRequest.status != 'rejected') ...[
                _MiniReturnTimeline(status: returnRequest.status, color: color, steps: steps),
                SizedBox(height: 20),
              ],

              // Rejection Reason
              if (returnRequest.status == 'rejected' && returnRequest.rejectionReason != null) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.2)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('orders.tracking.rejection_reason'.tr(),
                        style: TextStyle(fontSize: 12, color: const Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(returnRequest.rejectionReason!, style: TextStyle(fontSize: 13)),
                  ]),
                ),
                SizedBox(height: 20),
              ],

              // Returned Items
              if (returnRequest.items.isNotEmpty) ...[
                Text('orders.tracking.returned_items'.tr(),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                SizedBox(height: 10),
                ...returnRequest.items.map((item) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                          ? CachedNetworkImage(imageUrl: item.imageUrl!, width: 44, height: 44, fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _imgPlaceholder())
                          : _imgPlaceholder(),
                    ),
                    SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(isAr ? (item.productNameAr ?? item.productName ?? '—') : (item.productName ?? '—'),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (item.condition != null)
                        Text(item.condition!, style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ])),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text('× ${item.quantity}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                    ),
                  ]),
                )),
                SizedBox(height: 12),
              ],

              // Refund Amount
              if (returnRequest.refundAmount != null) ...[
                Divider(height: 1, color: Colors.grey.shade200),
                SizedBox(height: 14),
                Row(children: [
                  const Icon(Icons.currency_exchange_rounded, size: 18, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Text('orders.tracking.refund_amount'.tr(),
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const Spacer(),
                  SarText(
                    price: returnRequest.refundAmount!.toStringAsFixed(2),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
                  ),
                ]),
                if (returnRequest.refundMethod != null) ...[
                  SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(_methodLabel(returnRequest.refundMethod!, isAr),
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                ],
              ],

              // Date
              if (returnRequest.createdAt != null) ...[
                SizedBox(height: 12),
                Text('${'orders.tracking.submitted'.tr()}: ${_fmt(returnRequest.createdAt!)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
    width: 44, height: 44,
    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
    child: const Icon(Icons.inventory_2_outlined, size: 20, color: Colors.grey),
  );

  String _methodLabel(String m, bool isAr) => switch (m) {
    'original_payment' => 'orders.methods.original_payment'.tr(),
    'store_credit'     => 'orders.methods.store_credit'.tr(),
    'bank_transfer'    => 'orders.methods.bank_transfer'.tr(),
    _                  => m,
  };

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

// Horizontal mini-timeline dots for the return card
class _MiniReturnTimeline extends StatelessWidget {
  final String status;
  final Color color;
  final List<(String, String, String)> steps;

  const _MiniReturnTimeline({required this.status, required this.color, required this.steps});

  @override
  Widget build(BuildContext context) {
    final isAr       = Localizations.localeOf(context).languageCode == 'ar';
    final currentIdx = steps.indexWhere((s) => s.$1 == status);

    return Row(
      children: List.generate(steps.length, (i) {
        final isDone   = i <= currentIdx;
        final isActive = i == currentIdx;
        final dotColor = isDone ? color : Colors.grey.shade300;

        return Expanded(
          child: Row(children: [
            Expanded(child: Column(children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: isDone ? dotColor : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: dotColor, width: isActive ? 2.5 : 1.5),
                ),
                child: isDone ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
              ),
              SizedBox(height: 4),
              Text(
                isAr ? steps[i].$3 : steps[i].$2,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? color : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ])),
            if (i < steps.length - 1)
              Container(height: 2, width: 10, color: i < currentIdx ? color : Colors.grey.shade200),
          ]),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ORDER TRACKING MAP — used in Web layout to display locations
// ═══════════════════════════════════════════════════════════════════════════════

class _OrderTrackingMap extends StatefulWidget {
  final OrderEntity order;
  final double height;
  const _OrderTrackingMap({required this.order, this.height = 300});

  @override
  State<_OrderTrackingMap> createState() => _OrderTrackingMapState();
}

class _OrderTrackingMapState extends State<_OrderTrackingMap> {
  static const LatLng _defaultCenter = LatLng(24.7136, 46.6753);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final LatLng deliveryPos = widget.order.deliveryLat != null && widget.order.deliveryLng != null
        ? LatLng(widget.order.deliveryLat!, widget.order.deliveryLng!)
        : _defaultCenter;

    final LatLng? warehousePos = widget.order.warehouseLat != null && widget.order.warehouseLng != null
        ? LatLng(widget.order.warehouseLat!, widget.order.warehouseLng!)
        : null;

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white24 : Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11), // 1px less than container to avoid clipping issues
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: deliveryPos,
            zoom: 13,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('delivery'),
              position: deliveryPos,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
            if (warehousePos != null)
              Marker(
                markerId: const MarkerId('warehouse'),
                position: warehousePos,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              ),
          },
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }
}
