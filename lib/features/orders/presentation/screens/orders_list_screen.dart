// lib/features/orders/presentation/screens/orders_list_screen.dart

import 'package:fastway/core/theme/colors.dart';
import 'package:fastway/core/routes/app_navigator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/layout/simple_web_shell.dart';
import 'package:fastway/core/layout/web_nav_controller.dart'; // 👈 استدعاء الكنترولر
import 'package:fastway/core/responsive/hoverable_card.dart';
import 'package:fastway/core/responsive/responsive_layout.dart';
import 'package:fastway/core/widgets/sar_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/skeletons.dart';
import '../../../../core/widgets/custom_network_image.dart';
import '../../domain/entities/order_entity.dart';
import '../cubit/orders_cubit.dart';
import '../cubit/orders_state.dart';
import '../widgets/order_card.dart';
import '../widgets/order_status_badge.dart';

class OrdersListScreen extends StatefulWidget {
  final bool isTab; // 👈 لمعرفة هل الشاشة مفتوحة كـ Tab ولا صفحة منفصلة
  const OrdersListScreen({super.key, this.isTab = false});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrdersCubit>().loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {

        // ── 1. حالة الزائر ──
        if (state is OrdersGuest) {
          final guestView = _GuestOrdersView(isTab: widget.isTab);
          if (widget.isTab) return guestView; // لو Tab نرجع الفيو بدون WebShell
          return isWebLayout(context) ? SimpleWebShell(content: guestView) : Scaffold(body: guestView);
        }

        // ── 2. حالة التحميل ──
        if (state is OrdersLoading) {
          const loader = OrdersListSkeleton();
          if (widget.isTab) return loader;
          return isWebLayout(context)
              ? const SimpleWebShell(content: loader)
              : const Scaffold(
            body: OrdersListSkeleton(),
          );
        }

        // ── 3. حالة الخطأ ──
        if (state is OrdersError) {
          final errorBody = ErrorStateWidget(
            failure: state.failure,
            onRetry: () => context.read<OrdersCubit>().loadOrders(),
          );
          if (widget.isTab) return errorBody;
          return isWebLayout(context) ? SimpleWebShell(content: errorBody) : Scaffold(body: errorBody);
        }

        // ── 4. حالة نجاح التحميل ──
        if (state is OrdersLoaded) {
          // أ. حالة القائمة فارغة
          if (state.orders.isEmpty) {
            final emptyBody = EmptyStateWidget(
              icon: Icons.shopping_bag_outlined,
              title: 'orders.empty_title'.tr(),
              subtitle: 'orders.empty_subtitle'.tr(),
              actionLabel: 'orders.start_shopping'.tr(),
              onActionPressed: () {
                // توجيه ذكي حسب المنصة
                if (widget.isTab && isWebLayout(context)) {
                  context.read<WebNavController>().navigateTo(0); // للرئيسية
                } else {
                  Navigator.popUntil(context, (route) => route.settings.name == Routes.dashBoard || route.isFirst);
                  WebNavController.instance.navigateTo(0);
                }
              },
              enableBackButton: false,
            );
            if (widget.isTab) return emptyBody;
            return isWebLayout(context) ? SimpleWebShell(content: emptyBody) : Scaffold(body: emptyBody);
          }

          // ب. حالة وجود طلبات
          if (isWebLayout(context)) {
            final webView = _WebOrdersView(orders: state.orders, isTab: widget.isTab);
            // When opened as a standalone page (not a dashboard tab), wrap in
            // SimpleWebShell so the top header and footer are rendered.
            return widget.isTab ? webView : SimpleWebShell(content: webView);
          }

          return _MobileOrdersView(orders: state.orders);
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
List<({String key, String label, IconData icon})> _kStatusFilters() => [
  (key: 'all',        label: 'orders.list.all'.tr(),       icon: Icons.receipt_long_rounded),
  (key: 'active',     label: 'orders.list.active'.tr(),    icon: Icons.local_shipping_rounded),
  (key: 'delivered',  label: 'orders.list.delivered'.tr(), icon: Icons.check_circle_rounded),
  (key: 'cancelled',  label: 'orders.list.cancelled'.tr(), icon: Icons.cancel_rounded),
];

List<OrderEntity> _applyStatusFilter(List<OrderEntity> orders, String key) {
  switch (key) {
    case 'active':
      return orders.where((o) => !['delivered', 'cancelled'].contains(o.status)).toList();
    case 'delivered':
      return orders.where((o) => o.status == 'delivered').toList();
    case 'cancelled':
      return orders.where((o) => o.status == 'cancelled').toList();
    default:
      return orders;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
class _MobileOrdersView extends StatefulWidget {
  final List<OrderEntity> orders;

  const _MobileOrdersView({required this.orders});

  @override
  State<_MobileOrdersView> createState() => _MobileOrdersViewState();
}

class _MobileOrdersViewState extends State<_MobileOrdersView> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _applyStatusFilter(widget.orders, _selectedFilter);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0C) : const Color(0xFFF4F6F9),
      appBar: CustomAppBar(
        title: 'orders.title'.tr(),
        centerTitle: true,
        showBackIcon: true,
        onBackPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            AppNavigator.pushNamedAndRemoveAll(context, Routes.dashBoard);
          }
        },
        isTransparent: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'orders.list.history'.tr(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'orders.list.previous_orders'.tr(args: [widget.orders.length.toString()]),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Status Filter Tabs ──
          Padding(
            padding: EdgeInsets.only(top: 16, bottom: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _kStatusFilters().map((f) {
                  final isActive = _selectedFilter == f.key;
                  final count = f.key == 'all'
                      ? widget.orders.length
                      : _applyStatusFilter(widget.orders, f.key).length;
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = f.key),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? ColorsManager.primary2Color
                              : (isDark ? ColorsManager.surfaceDarkCard : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isActive
                                ? ColorsManager.primary2Color
                                : (isDark ? Colors.white.withAlpha(15) : Colors.grey.shade200),
                          ),
                          // BoxShadow removed — changes on active = GPU repaint per tab
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              f.icon,
                              size: 14,
                              color: isActive ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                            SizedBox(width: 6),
                            Text(
                              f.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                color: isActive ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]),
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isActive ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Orders List ──
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_rounded, size: 56, color: Colors.grey[400]),
                        SizedBox(height: 12),
                        Text(
                          'orders.list.no_orders'.tr(),
                          style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() => _selectedFilter = 'all'),
                          child: Text('orders.list.view_all'.tr(),
                            style: TextStyle(color: ColorsManager.primary2Color, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => context.read<OrdersCubit>().refreshOrders(),
                    color: ColorsManager.primary2Color,
                    backgroundColor: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
                    displacement: 20,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final order = filtered[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: OrderCard(
                            order: order,
                            onTap: () => AppNavigator.pushNamed(context, '${Routes.orderDetails}/${order.id}'),
                            onTrackOrder: () => AppNavigator.pushNamed(context, '${Routes.orderTracking}/${order.id}/track'),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WEB ORDERS VIEW — Clean SaaS List Layout
// ═══════════════════════════════════════════════════════════════════════════════

class _WebOrdersView extends StatelessWidget {
  final List<OrderEntity> orders;
  final bool isTab;

  const _WebOrdersView({required this.orders, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 900;
      final hPad = isNarrow ? constraints.maxWidth * 0.04 : 32.0;

      return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'orders.title'.tr(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'orders.you_have_items'.tr(args: [orders.length.toString(), 'orders.items_count'.tr()]),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // 👈 التوجيه الذكي لو ضغط على تسوق المزيد
                      if (isTab) {
                        context.read<WebNavController>().navigateTo(0); // للرئيسية
                      } else {
                        Navigator.popUntil(context, (route) => route.settings.name == Routes.dashBoard || route.isFirst);
                        WebNavController.instance.navigateTo(0);
                      }
                    },
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                    label: Text('orders.shop_more'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.primary2Color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── Orders List ──
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final bool canTrack = order.status != 'delivered' && order.status != 'cancelled';

                  return HoverableCard(
                    onTap: () => AppNavigator.pushNamed(context, '${Routes.orderDetails}/${order.id}'),
                    hoverLift: -2,
                    hoverShadowBlur: 15,
                    child: LayoutBuilder(builder: (context, cs) {
                      final isNarrow = cs.maxWidth < 650;
                      final cardDecoration = BoxDecoration(
                        color: isDark ? ColorsManager.surfaceDarkCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
                      );

                      if (isNarrow) {
                        // ── Narrow / mobile viewport: stacked card ───────────
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: cardDecoration,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('#${order.orderNumber}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                                  OrderStatusBadge(status: order.status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(DateFormat('dd MMM yyyy • hh:mm a').format(order.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  SarText(price: order.total.toStringAsFixed(2), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ColorsManager.primary2Color)),
                                  Text('orders.elements'.tr(args: [order.itemCount.toString()]), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: canTrack
                                    ? OutlinedButton(
                                        onPressed: () => AppNavigator.pushNamed(context, '${Routes.orderTracking}/${order.id}/track'),
                                        style: OutlinedButton.styleFrom(foregroundColor: ColorsManager.primary2Color, side: const BorderSide(color: ColorsManager.primary2Color), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                                        child: Text('orders.track'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      )
                                    : TextButton(
                                        onPressed: () => AppNavigator.pushNamed(context, '${Routes.orderDetails}/${order.id}'),
                                        style: TextButton.styleFrom(foregroundColor: isDark ? Colors.white70 : Colors.black87, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                                        child: Text('orders.view_details'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                              ),
                            ],
                          ),
                        );
                      }

                      // ── Wide viewport: original horizontal row ──────────────
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: cardDecoration,
                        child: Row(
                          children: [
                            // 1. Overlapping Images
                            if (order.items.isNotEmpty)
                              SizedBox(width: 120, child: _WebOverlappingProducts(items: order.items)),
                            const SizedBox(width: 24),

                            // 2. Order Info
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('#${order.orderNumber}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                                  const SizedBox(height: 6),
                                  Text(DateFormat('dd MMM yyyy • hh:mm a').format(order.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),

                            // 3. Status
                            Expanded(child: Align(alignment: Alignment.centerLeft, child: OrderStatusBadge(status: order.status))),

                            // 4. Total Price
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  SarText(price: order.total.toStringAsFixed(2), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ColorsManager.primary2Color)),
                                  const SizedBox(height: 4),
                                  Text('orders.elements'.tr(args: [order.itemCount.toString()]), style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),

                            // 5. Action Button
                            SizedBox(
                              width: 120,
                              child: canTrack
                                  ? OutlinedButton(
                                      onPressed: () => AppNavigator.pushNamed(context, '${Routes.orderTracking}/${order.id}/track'),
                                      style: OutlinedButton.styleFrom(foregroundColor: ColorsManager.primary2Color, side: const BorderSide(color: ColorsManager.primary2Color), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                                      child: Text('orders.track'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    )
                                  : TextButton(
                                      onPressed: () => AppNavigator.pushNamed(context, '${Routes.orderDetails}/${order.id}'),
                                      style: TextButton.styleFrom(foregroundColor: isDark ? Colors.white70 : Colors.black87, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                                      child: Text('orders.view_details'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                            ),
                          ],
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
    }); // end LayoutBuilder
  }
}

class _WebOverlappingProducts extends StatelessWidget {
  final List<OrderItemEntity> items;

  const _WebOverlappingProducts({required this.items});

  @override
  Widget build(BuildContext context) {
    final displayItems = items.take(3).toList();
    final remainingCount = items.length - displayItems.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          ...displayItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Positioned(
              left: index * 32.0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? ColorsManager.surfaceDarkCard : Colors.white, width: 3),
                ),
                child: CustomNetworkImage.rounded(
                  imageUrl: item.imageUrl,
                  width: 42,
                  height: 42,
                  borderRadius: 100,
                ),
              ),
            );
          }),
          if (remainingCount > 0)
            Positioned(
              left: displayItems.length * 32.0,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? ColorsManager.surfaceDarkCard : Colors.white, width: 3),
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GUEST ORDERS VIEW
// ═══════════════════════════════════════════════════════════════════════════════

class _GuestOrdersView extends StatelessWidget {
  final bool isTab;
  const _GuestOrdersView({this.isTab = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F6FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: ColorsManager.primary2Color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.receipt_long_rounded, size: 54, color: ColorsManager.primary2Color),
              ),
              SizedBox(height: 32),
              Text(
                'orders.guest.title'.tr(),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1A1A1A)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'orders.guest.subtitle'.tr(),
                style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600], height: 1.6),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => AppNavigator.pushNamed(context, Routes.auth),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.primary2Color,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    elevation: 0,
                  ),
                  child: Text('orders.guest.loginBtn'.tr(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // 👈 التوجيه الذكي للزائر
                  if (isTab && isWebLayout(context)) {
                    context.read<WebNavController>().navigateTo(0);
                  } else {
                    Navigator.popUntil(context, (route) => route.settings.name == Routes.dashBoard || route.isFirst);
                    WebNavController.instance.navigateTo(0);
                  }
                },
                child: Text('orders.guest.continueShopping'.tr(), style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

