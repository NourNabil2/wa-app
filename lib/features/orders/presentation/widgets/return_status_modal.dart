// lib/features/orders/presentation/widgets/return_status_modal.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/widgets/sar_symbol.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/order_entity.dart';

/// Rich return-status bottom-sheet modal — replaces the old ReturnStatusScreen.
/// Call [ReturnStatusModal.show] from anywhere in the order flow.
class ReturnStatusModal {
  /// Show the modal for a specific [ret]. Pass [orderTotal] for financial summary.
  static void show(BuildContext context, OrderEntity order, {OrderReturnEntity? specificReturn}) {
    final ret = specificReturn ?? order.activeReturn;
    if (ret == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReturnStatusSheet(order: order, ret: ret),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ReturnStatusSheet extends StatelessWidget {
  final OrderEntity order;
  final OrderReturnEntity ret;

  const _ReturnStatusSheet({required this.order, required this.ret});

  // ── colour palette per status ──────────────────────────────────────────────
  Color get _color => switch (ret.status) {
    'rejected'             => const Color(0xFFDC2626),
    'refunded' || 'closed' => const Color(0xFF059669),
    'approved'             => const Color(0xFF2563EB),
    _                      => const Color(0xFFD97706),
  };

  IconData get _icon => switch (ret.status) {
    'rejected'             => Icons.cancel_rounded,
    'refunded' || 'closed' => Icons.check_circle_rounded,
    'approved'             => Icons.thumb_up_rounded,
    _                      => Icons.swap_horiz_rounded,
  };

  String _statusLabel(bool isAr) => switch (ret.status) {
    'requested'  => 'orders.status.requested'.tr(),
    'approved'   => 'orders.status.approved'.tr(),
    'rejected'   => 'orders.status.rejected'.tr(),
    'picked_up'  => 'orders.status.picked_up'.tr(),
    'received'   => 'orders.status.received'.tr(),
    'refunded'   => 'orders.status.refunded'.tr(),
    'closed'     => 'orders.status.closed'.tr(),
    _            => ret.status,
  };

  String _methodLabel(String m, bool isAr) => switch (m) {
    'original_payment' => 'orders.methods.original_payment'.tr(),
    'store_credit'     => 'orders.methods.store_credit'.tr(),
    'bank_transfer'    => 'orders.methods.bank_transfer'.tr(),
    _                  => m,
  };

  String _fmt(DateTime d) => DateFormat('d MMM yyyy  •  HH:mm').format(d.toLocal());

  // ── vertical timeline steps ───────────────────────────────────────────────
  List<(String, String, String)> get _steps => [
    ('requested', 'orders.steps.requested.title'.tr(), 'orders.steps.requested.title'.tr()),
    ('approved',  'orders.steps.approved.title'.tr(),  'orders.steps.approved.title'.tr()),
    ('picked_up', 'orders.steps.picked_up.title'.tr(), 'orders.steps.picked_up.title'.tr()),
    ('received',  'orders.steps.received.title'.tr(),  'orders.steps.received.title'.tr()),
    ('refunded',  'orders.steps.refunded.title'.tr(),  'orders.steps.refunded.title'.tr()),
  ];

  int get _stepIndex => _steps.indexWhere((s) => s.$1 == ret.status);

  @override
  Widget build(BuildContext context) {
    final isAr  = Localizations.localeOf(context).languageCode == 'ar';
    final color = _color;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1C1C2E) : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.zero),
        ),
        child: Column(
          children: [
            // drag handle
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w, height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.zero,
              ),
            ),

            // ── Coloured header ────────────────────────────────────────────
            Container(
              margin: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.zero,
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                Container(
                  width: 48.w, height: 48.w,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Icon(_icon, color: Colors.white, size: 26.sp),
                ),
                SizedBox(width: 14.w),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('orders.return_status_title'.tr(),
                      style: TextStyle(fontSize: 12.sp, color: color.withValues(alpha: 0.7))),
                  Text(_statusLabel(isAr),
                      style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold, color: color)),
                  SizedBox(height: 2.h),
                  Text('${'orders.order_number'.tr()}: ${order.orderNumber}',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                ])),
              ]),
            ),

            // ── Scrollable body ────────────────────────────────────────────
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
                children: [

                  // ── Vertical timeline (not shown when rejected) ──────────
                  if (ret.status != 'rejected') ...[
                    _sectionTitle('orders.modal.progress'.tr(), color),
                    SizedBox(height: 12.h),
                    _VerticalTimeline(status: ret.status, color: color, isAr: isAr),
                    SizedBox(height: 24.h),
                  ],

                  // ── Timestamps ───────────────────────────────────────────
                  _sectionTitle('orders.modal.timeline'.tr(), color),
                  SizedBox(height: 12.h),
                  _card(isDark, Column(children: [
                    if (ret.createdAt != null)
                      _dateRow('orders.modal.submitted'.tr(), ret.createdAt!, color),
                    if (ret.approvedAt != null)
                      _dateRow('orders.modal.approved'.tr(), ret.approvedAt!, const Color(0xFF2563EB)),
                    if (ret.refundedAt != null)
                      _dateRow('orders.modal.refunded'.tr(), ret.refundedAt!, const Color(0xFF059669)),
                  ])),
                  SizedBox(height: 24.h),

                  // ── Reason & notes ────────────────────────────────────────
                  _sectionTitle('orders.modal.reason'.tr(), color),
                  SizedBox(height: 12.h),
                  _card(isDark, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _infoRow(
                      'orders.modal.reason_label'.tr(),
                      ['wrong_item', 'damaged', 'not_as_described', 'changed_mind', 'other'].contains(ret.reason)
                          ? 'orders.return_reasons.${ret.reason}'.tr()
                          : ret.reason,
                    ),
                    if (ret.notes != null && ret.notes!.isNotEmpty)
                      _infoRow('orders.modal.notes'.tr(), ret.notes!),
                  ])),
                  SizedBox(height: 24.h),

                  // ── Rejection reason (always shown when rejected) ─────────
                  if (ret.status == 'rejected') ...[
                    _sectionTitle('orders.modal.rejection_reason'.tr(), const Color(0xFFDC2626)),
                    SizedBox(height: 12.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.07),
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 20),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            ret.rejectionReason?.isNotEmpty == true
                                ? ret.rejectionReason!
                                : 'orders.modal.no_reason'.tr(),
                            style: TextStyle(fontSize: 13.sp, height: 1.5),
                          ),
                        ),
                      ]),
                    ),
                    SizedBox(height: 8.h),
                    // Hint: can re-submit
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        'orders.modal.resubmit'.tr(),
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey, height: 1.4),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],

                  // ── Returned items ────────────────────────────────────────
                  if (ret.items.isNotEmpty) ...[
                    _sectionTitle('orders.modal.returned_items'.tr(), color),
                    SizedBox(height: 12.h),
                    _card(isDark, Column(
                      children: ret.items.asMap().entries.map((e) {
                        final i = e.value;
                        final isLast = e.key == ret.items.length - 1;
                        return Column(children: [
                          Row(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.zero,
                              child: (i.imageUrl != null && i.imageUrl!.isNotEmpty)
                                  ? CachedNetworkImage(imageUrl: i.imageUrl!, width: 54.w, height: 54.w, fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => _imgBox())
                                  : _imgBox(),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(isAr ? (i.productNameAr ?? i.productName ?? '—') : (i.productName ?? '—'),
                                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              if (i.condition != null)
                                Text(['unopened', 'damaged', 'used'].contains(i.condition)
                                        ? 'orders.return_conditions.${i.condition}'.tr()
                                        : i.condition!,
                                    style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                            ])),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Text('× ${i.quantity}',
                                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: color)),
                            ),
                          ]),
                          if (!isLast) ...[
                            SizedBox(height: 12.h),
                            Divider(height: 1, color: Colors.grey.shade200),
                            SizedBox(height: 12.h),
                          ],
                        ]);
                      }).toList(),
                    )),
                    SizedBox(height: 24.h),
                  ],

                  // ── T2.6: Return shipment CTA (approved + has return_method) ─
                  if (ret.status == 'approved' && ret.returnMethod != null) ...[ 
                    _sectionTitle('orders.modal.return_shipment'.tr(), color),
                    SizedBox(height: 12.h),
                    _card(isDark, _ReturnShipmentCta(ret: ret, color: color)),
                    SizedBox(height: 24.h),
                  ],

                  // ── Financial summary ─────────────────────────────────────
                  _sectionTitle('orders.modal.financial_summary'.tr(), color),
                  SizedBox(height: 12.h),
                  _card(isDark, Column(children: [
                    _amountRow('orders.modal.order_total'.tr(),
                        SarText(price: order.total.toStringAsFixed(2),
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.grey))),
                    if (ret.refundAmount != null)
                      _amountRow('orders.modal.refund_amount'.tr(),
                          SarText(price: ret.refundAmount!.toStringAsFixed(2),
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF059669))),
                          bold: true),
                    if (ret.refundMethod != null)
                      _infoRow('orders.modal.refund_via'.tr(),
                          _methodLabel(ret.refundMethod!, isAr)),
                  ])),
                  SizedBox(height: 32.h),

                  // ── Close button ──────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        elevation: 0,
                      ),
                      child: Text('orders.modal.close'.tr(),
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionTitle(String text, Color color) => Row(children: [
    Container(width: 3.w, height: 16.h, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.zero)),
    SizedBox(width: 8.w),
    Text(text, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
  ]);

  Widget _card(bool isDark, Widget child) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF252535) : const Color(0xFFF8F9FA),
      borderRadius: BorderRadius.zero,
      border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
    ),
    child: child,
  );

  Widget _dateRow(String label, DateTime dt, Color color) => Padding(
    padding: EdgeInsets.only(bottom: 10.h),
    child: Row(children: [
      Container(width: 8.w, height: 8.w, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      SizedBox(width: 10.w),
      Expanded(child: Text(label, style: TextStyle(fontSize: 13.sp, color: Colors.grey))),
      Text(_fmt(dt), style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$label: ', style: TextStyle(fontSize: 13.sp, color: Colors.grey)),
      Expanded(child: Text(value, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600))),
    ]),
  );

  Widget _amountRow(String label, Widget valueWidget, {bool bold = false}) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Row(children: [
      Expanded(child: Text(label, style: TextStyle(fontSize: 13.sp, color: Colors.grey))),
      valueWidget,
    ]),
  );

  Widget _imgBox() => Container(
    width: 54.w, height: 54.w,
    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.zero),
    child: const Icon(Icons.inventory_2_outlined, size: 24, color: Colors.grey),
  );
}

// ── Vertical timeline widget ──────────────────────────────────────────────────

class _VerticalTimeline extends StatelessWidget {
  final String status;
  final Color color;
  final bool isAr;

  const _VerticalTimeline({required this.status, required this.color, required this.isAr});

  List<List<String>> get _steps => [
    ['requested', 'orders.steps.requested.title'.tr(), 'orders.steps.requested.desc'.tr()],
    ['approved',  'orders.steps.approved.title'.tr(),  'orders.steps.approved.desc'.tr()],
    ['picked_up', 'orders.steps.picked_up.title'.tr(), 'orders.steps.picked_up.desc'.tr()],
    ['received',  'orders.steps.received.title'.tr(),  'orders.steps.received.desc'.tr()],
    ['refunded',  'orders.steps.refunded.title'.tr(),  'orders.steps.refunded.desc'.tr()],
  ];

  @override
  Widget build(BuildContext context) {
    final currentIdx = _steps.indexWhere((s) => s[0] == status);

    return Column(
      children: List.generate(_steps.length, (i) {
        final step     = _steps[i];
        final isDone   = i <= currentIdx;
        final isActive = i == currentIdx;
        final isLast   = i == _steps.length - 1;
        final dotColor = isDone ? color : Colors.grey.shade300;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Dot + line ──────────────────────────────────────────────
            Column(children: [
              Container(
                width: 28.w, height: 28.w,
                decoration: BoxDecoration(
                  color: isDone ? dotColor : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: dotColor, width: isActive ? 2.5 : 1.5),
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Container(width: 2.w, height: 40.h, color: i < currentIdx ? color : Colors.grey.shade200),
            ]),
            SizedBox(width: 14.w),

            // ── Label + description ─────────────────────────────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 2.h, bottom: isLast ? 0 : 28.h),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(step[1],
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          color: isDone ? (isActive ? color : Colors.black87) : Colors.grey)),
                  SizedBox(height: 2.h),
                  Text(step[2],
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey, height: 1.4)),
                ]),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── T2.6: Return shipment CTA widget ─────────────────────────────────────────
// Branches on ret.returnMethod — NEVER on provider strings.
// 'pickup'  → Aramex courier collects from customer's home.
// 'dropoff' → Redbox: customer drops at locker, shows waybill download.
// 'manual'  → Admin will contact the customer.

class _ReturnShipmentCta extends StatelessWidget {
  final OrderReturnEntity ret;
  final Color color;

  const _ReturnShipmentCta({required this.ret, required this.color});

  @override
  Widget build(BuildContext context) {
    return switch (ret.returnMethod) {
      'pickup'  => _PickupCta(ret: ret, color: color),
      'dropoff' => _DropoffCta(ret: ret, color: color),
      _         => _ManualCta(color: color),
    };
  }
}

class _PickupCta extends StatelessWidget {
  final OrderReturnEntity ret;
  final Color color;
  const _PickupCta({required this.ret, required this.color});

  @override
  Widget build(BuildContext context) {
    final pickupDate = ret.returnPickupBookedAt != null
        ? DateFormat('d MMM yyyy').format(ret.returnPickupBookedAt!.toLocal())
        : null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.local_shipping_rounded, color: color, size: 20.sp),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            pickupDate != null
                ? 'orders.return_shipment.pickup_scheduled'.tr(namedArgs: {'date': pickupDate})
                : 'orders.return_shipment.pickup_booked'.tr(),
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
      if (ret.returnTrackingNumber != null) ...[
        SizedBox(height: 8.h),
        Text(
          '${'orders.return_shipment.tracking'.tr()}: ${ret.returnTrackingNumber}',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
        ),
      ],
    ]);
  }
}

class _DropoffCta extends StatelessWidget {
  final OrderReturnEntity ret;
  final Color color;
  const _DropoffCta({required this.ret, required this.color});

  Future<void> _openWaybill() async {
    final url = ret.returnWaybillUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.inventory_2_outlined, color: color, size: 20.sp),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            'orders.return_shipment.dropoff_instructions'.tr(),
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
      SizedBox(height: 6.h),
      Text(
        'orders.return_shipment.dropoff_hint'.tr(),
        style: TextStyle(fontSize: 12.sp, color: Colors.grey, height: 1.4),
      ),
      if (ret.returnTrackingNumber != null) ...[
        SizedBox(height: 6.h),
        Text(
          '${'orders.return_shipment.tracking'.tr()}: ${ret.returnTrackingNumber}',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
        ),
      ],
      if (ret.returnWaybillUrl != null) ...[
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openWaybill,
            icon: Icon(Icons.download_rounded, size: 18.sp),
            label: Text('orders.return_shipment.download_waybill'.tr(),
                style: TextStyle(fontSize: 13.sp)),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              padding: EdgeInsets.symmetric(vertical: 10.h),
            ),
          ),
        ),
      ],
    ]);
  }
}

class _ManualCta extends StatelessWidget {
  final Color color;
  const _ManualCta({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(Icons.support_agent_rounded, color: color, size: 20.sp),
      SizedBox(width: 8.w),
      Expanded(
        child: Text(
          'orders.return_shipment.manual_instructions'.tr(),
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
        ),
      ),
    ]);
  }
}
