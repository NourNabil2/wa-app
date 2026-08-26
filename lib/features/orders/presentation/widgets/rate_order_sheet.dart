// lib/features/orders/presentation/widgets/rate_order_sheet.dart
//
// Post-delivery 3-way review sheet: store + shipment + per-item ratings in a
// single scrollable bottom sheet with one submit. Only renders sections the
// user hasn't reviewed yet; submitted sections show a "pending approval" chip.
//
// Locked decisions: all sections optional, ≥1 required; carrier name from order
// data; partial-failure reported per-section (see OrdersCubit.submitOrderReviews).

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/custom_snack_bar.dart';
import '../../../../core/widgets/star_rating_input.dart';
import '../../domain/entities/order_entity.dart';
import '../cubit/orders_cubit.dart';
import '../cubit/orders_state.dart';

class RateOrderSheet extends StatefulWidget {
  final OrderEntity order;
  const RateOrderSheet({super.key, required this.order});

  static Future<void> show(BuildContext context, OrderEntity order) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<OrdersCubit>(),
        child: RateOrderSheet(order: order),
      ),
    );
  }

  @override
  State<RateOrderSheet> createState() => _RateOrderSheetState();
}

class _RateOrderSheetState extends State<RateOrderSheet> {
  int _storeRating = 0;
  final _storeComment = TextEditingController();

  int _shipmentRating = 0;
  final _shipmentComment = TextEditingController();

  // keyed by productId
  final Map<String, int> _itemRatings = {};
  final Map<String, TextEditingController> _itemComments = {};

  bool _submitting = false;

  @override
  void dispose() {
    _storeComment.dispose();
    _shipmentComment.dispose();
    for (final c in _itemComments.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _hasAtLeastOne {
    if (_storeRating > 0) return true;
    if (_shipmentRating > 0) return true;
    return _itemRatings.values.any((r) => r > 0);
  }

  String? _trimmed(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  void _submit() {
    if (!_hasAtLeastOne) {
      CustomSnackBar.show(
        context,
        message: 'orders.rate_order.validation_min_one'.tr(),
        type: SnackBarType.error,
      );
      return;
    }

    final order = widget.order;

    ({int rating, String? comment})? store;
    if (!order.storeReviewed && _storeRating > 0) {
      store = (rating: _storeRating, comment: _trimmed(_storeComment));
    }

    ({int rating, String? comment})? shipment;
    if (!order.shipmentReviewed && _shipmentRating > 0) {
      shipment = (rating: _shipmentRating, comment: _trimmed(_shipmentComment));
    }

    final items = <String, ({int rating, String? comment})>{};
    _itemRatings.forEach((productId, rating) {
      if (rating > 0) {
        items[productId] = (rating: rating, comment: _trimmed(_itemComments[productId]!));
      }
    });

    context.read<OrdersCubit>().submitOrderReviews(
          orderId: order.id,
          store: store,
          shipment: shipment,
          items: items,
        );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final unreviewedItems = order.items.where((i) => !i.reviewed && i.productId.isNotEmpty).toList();

    return BlocListener<OrdersCubit, OrdersState>(
      listenWhen: (_, c) =>
          c is OrderReviewsSubmitting ||
          c is OrderReviewsSubmitted ||
          c is OrderReviewsSubmitError,
      listener: (context, state) {
        if (state is OrderReviewsSubmitting) {
          setState(() => _submitting = true);
        } else if (state is OrderReviewsSubmitError) {
          setState(() => _submitting = false);
          CustomSnackBar.show(context, message: state.failure.message, type: SnackBarType.error);
        } else if (state is OrderReviewsSubmitted) {
          setState(() => _submitting = false);
          if (state.failedSections.isEmpty) {
            CustomSnackBar.show(context, message: 'orders.rate_order.success'.tr());
            Navigator.of(context).pop();
          } else {
            CustomSnackBar.show(
              context,
              message: 'orders.rate_order.partial_error'.tr(),
              type: SnackBarType.error,
            );
            // Keep the sheet open so the user can retry the failed sections.
          }
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'orders.rate_order.title'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Store ──
                      _Section(
                        title: 'orders.rate_order.store'.tr(),
                        reviewed: order.storeReviewed,
                        child: _RatingBlock(
                          rating: _storeRating,
                          onRating: (v) => setState(() => _storeRating = v),
                          controller: _storeComment,
                        ),
                      ),

                      // ── Shipment ──
                      _Section(
                        title: 'orders.rate_order.shipment'.tr(),
                        subtitle: (order.shipmentProvider != null && order.shipmentProvider!.isNotEmpty)
                            ? '${'orders.rate_order.carrier_label'.tr()}: ${order.shipmentProvider}'
                            : null,
                        reviewed: order.shipmentReviewed,
                        child: _RatingBlock(
                          rating: _shipmentRating,
                          onRating: (v) => setState(() => _shipmentRating = v),
                          controller: _shipmentComment,
                        ),
                      ),

                      // ── Items ──
                      if (unreviewedItems.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Text(
                            'orders.rate_order.items'.tr(),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                        ...unreviewedItems.map((item) {
                          _itemComments.putIfAbsent(item.productId, () => TextEditingController());
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? ColorsManager.surfaceDarkCard : ColorsManager.inputSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: ColorsManager.inputBorder.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        item.imageUrl,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 44,
                                          height: 44,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.image_not_supported_outlined, size: 20),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _RatingBlock(
                                  rating: _itemRatings[item.productId] ?? 0,
                                  onRating: (v) => setState(() => _itemRatings[item.productId] = v),
                                  controller: _itemComments[item.productId]!,
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  child: _submitting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('orders.rate_order.submit'.tr(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled section that either shows its [child] form or a locked
/// "pending approval" chip when [reviewed] is true.
class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool reviewed;
  final Widget child;

  const _Section({
    required this.title,
    this.subtitle,
    required this.reviewed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
          const SizedBox(height: 8),
          if (reviewed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_top_rounded, size: 16, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  Text(
                    'orders.rate_order.pending_approval'.tr(),
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          else
            child,
        ],
      ),
    );
  }
}

class _RatingBlock extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRating;
  final TextEditingController controller;

  const _RatingBlock({
    required this.rating,
    required this.onRating,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StarRatingInput(value: rating, onChanged: onRating),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 2,
          maxLength: 1000,
          decoration: InputDecoration(
            hintText: 'orders.rate_order.comment_placeholder'.tr(),
            counterText: '',
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
