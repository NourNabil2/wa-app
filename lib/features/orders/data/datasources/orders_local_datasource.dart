// lib/features/orders/data/datasources/orders_local_datasource.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';
import 'package:easy_localization/easy_localization.dart';

abstract class OrdersLocalDataSource {
  Future<List<OrderModel>> getOrders();
  Future<OrderModel?> getOrderById(String orderId);
  Future<OrderModel> trackOrder(String orderId);
  Future<void> saveOrder(OrderModel order);
  Future<void> updateOrderStatus(String orderId, String status);
}

class OrdersLocalDataSourceImpl implements OrdersLocalDataSource {
  final SharedPreferences _prefs;
  static const String _ordersKey = 'orders_data';

  OrdersLocalDataSourceImpl(this._prefs);

  // Mock orders data for demonstration
  List<OrderModel> get _mockOrders => [
    OrderModel(
      id: '1',
      orderNumber: 'ORD-2024001',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      total: 545.0,
      status: 'delivered',
      items: const [
        OrderItemModel(
          id: 'item_1',
          productId: 'prod_1',
          name: 'واي بروتين جولد ستاندرد',
          imageUrl: 'https://th.bing.com/th/id/OIP.K75A4VUDe5bOKkMzDEpeJAHaHa?w=154&h=198',
          price: 189.0,
          quantity: 2,
        ),
        OrderItemModel(
          id: 'item_2',
          productId: 'prod_2',
          name: 'كرياتين مونوهيدرات',
          imageUrl: 'https://egyfitness.com/wp-content/uploads/2014/07/url.jpg',
          price: 120.0,
          quantity: 1,
        ),
      ],
      shippingAddress: 'الرياض، حي النرجس، شارع الخصخصي',
      phone: '0501234567',
      paymentMethod: 'الدفع عند الاستلام',
      shippingCost: 25.0,
      subtotal: 520.0,
      timeline: [
        OrderTimelineModel(
          status: 'order_placed',
          title: 'orders.timeline.placed'.tr(),
          description: 'تم استلام طلبك بنجاح',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          isCompleted: true,
        ),
        OrderTimelineModel(
          status: 'processing',
          title: 'orders.status.processing'.tr(),
          description: 'جاري تجهيز طلبك',
          timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 20)),
          isCompleted: true,
        ),
        OrderTimelineModel(
          status: 'shipped',
          title: 'orders.status.shipped'.tr(),
          description: 'طلبك في الطريق إليك',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          isCompleted: true,
        ),
        OrderTimelineModel(
          status: 'delivered',
          title: 'orders.status.delivered'.tr(),
          description: 'تم توصيل طلبك بنجاح',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          isCompleted: true,
        ),
      ],
    ),
    OrderModel(
      id: '2',
      orderNumber: 'ORD-2024002',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      total: 320.0,
      status: 'shipped',
      items: const [
        OrderItemModel(
          id: 'item_3',
          productId: 'prod_3',
          name: 'BCAA أمينو',
          imageUrl: 'https://i.imgur.com/BCAA.jpg',
          price: 150.0,
          quantity: 1,
        ),
        OrderItemModel(
          id: 'item_4',
          productId: 'prod_4',
          name: 'مولتي فيتامين',
          imageUrl: 'https://i.imgur.com/multi.jpg',
          price: 145.0,
          quantity: 1,
        ),
      ],
      shippingAddress: 'جدة، حي الشاطئ، شارع الكورنيش',
      phone: '0559876543',
      paymentMethod: 'بطاقة ائتمان',
      shippingCost: 25.0,
      subtotal: 295.0,
      timeline: [
        OrderTimelineModel(
          status: 'order_placed',
          title: 'orders.timeline.placed'.tr(),
          description: 'تم استلام طلبك بنجاح',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          isCompleted: true,
        ),
        OrderTimelineModel(
          status: 'processing',
          title: 'orders.status.processing'.tr(),
          description: 'جاري تجهيز طلبك',
          timestamp: DateTime.now().subtract(const Duration(hours: 20)),
          isCompleted: true,
        ),
        OrderTimelineModel(
          status: 'shipped',
          title: 'orders.status.shipped'.tr(),
          description: 'طلبك في الطريق إليك',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isCompleted: true,
        ),
        OrderTimelineModel(
          status: 'delivered',
          title: 'orders.status.delivered'.tr(),
          description: 'سيتم توصيل طلبك قريباً',
          timestamp: null,
          isCompleted: false,
        ),
      ],
    ),
    OrderModel(
      id: '3',
      orderNumber: 'ORD-2024003',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      total: 189.0,
      status: 'processing',
      items: const [
        OrderItemModel(
          id: 'item_5',
          productId: 'prod_5',
          name: 'بري وركاوت C4',
          imageUrl: 'https://i.imgur.com/c4.jpg',
          price: 164.0,
          quantity: 1,
        ),
      ],
      shippingAddress: 'الدمام، حي الفيصلية، شارع الملك فهد',
      phone: '0541112223',
      paymentMethod: 'آبل باي',
      shippingCost: 25.0,
      subtotal: 164.0,
      timeline: [
        OrderTimelineModel(
          status: 'order_placed',
          title: 'orders.timeline.placed'.tr(),
          description: 'تم استلام طلبك بنجاح',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          isCompleted: true,
        ),
        OrderTimelineModel(
          status: 'processing',
          title: 'orders.status.processing'.tr(),
          description: 'جاري تجهيز طلبك',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          isCompleted: true,
        ),
        OrderTimelineModel(
          status: 'shipped',
          title: 'orders.status.shipped'.tr(),
          description: 'سيتم شحن طلبك قريباً',
          timestamp: null,
          isCompleted: false,
        ),
        OrderTimelineModel(
          status: 'delivered',
          title: 'orders.status.delivered'.tr(),
          description: 'سيتم توصيل طلبك قريباً',
          timestamp: null,
          isCompleted: false,
        ),
      ],
    ),
    OrderModel(
      id: '4',
      orderNumber: 'ORD-2024004',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      total: 450.0,
      status: 'pending',
      items: const [
        OrderItemModel(
          id: 'item_6',
          productId: 'prod_6',
          name: 'ماس جينر',
          imageUrl: 'https://i.imgur.com/mass.jpg',
          price: 425.0,
          quantity: 1,
        ),
      ],
      shippingAddress: 'مكة المكرمة، حي العزيزية، شارع إبراهيم الخليل',
      phone: '0563334445',
      paymentMethod: 'الدفع عند الاستلام',
      shippingCost: 25.0,
      subtotal: 425.0,
      timeline: [
        OrderTimelineModel(
          status: 'order_placed',
          title: 'orders.timeline.placed'.tr(),
          description: 'تم استلام طلبك بنجاح',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          isCompleted: true,
        ),
        OrderTimelineModel(
          status: 'processing',
          title: 'orders.status.processing'.tr(),
          description: 'سيتم البدء في تجهيز طلبك',
          timestamp: null,
          isCompleted: false,
        ),
        OrderTimelineModel(
          status: 'shipped',
          title: 'orders.status.shipped'.tr(),
          description: 'سيتم شحن طلبك قريباً',
          timestamp: null,
          isCompleted: false,
        ),
        OrderTimelineModel(
          status: 'delivered',
          title: 'orders.status.delivered'.tr(),
          description: 'سيتم توصيل طلبك قريباً',
          timestamp: null,
          isCompleted: false,
        ),
      ],
    ),
  ];

  @override
  Future<List<OrderModel>> getOrders() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final ordersJson = _prefs.getString(_ordersKey);
    if (ordersJson != null) {
      final List<dynamic> decoded = jsonDecode(ordersJson);
      return decoded.map((e) => OrderModel.fromJson(e)).toList();
    }
    
    // Return mock data if no saved orders
    return _mockOrders;
  }

  @override
  Future<OrderModel?> getOrderById(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final orders = await getOrders();
    try {
      return orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<OrderModel> trackOrder(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    final order = await getOrderById(orderId);
    if (order == null) {
      throw Exception('Order not found');
    }
    
    return order;
  }

  @override
  Future<void> saveOrder(OrderModel order) async {
    final orders = await getOrders();
    final existingIndex = orders.indexWhere((o) => o.id == order.id);
    
    if (existingIndex != -1) {
      orders[existingIndex] = order;
    } else {
      orders.add(order);
    }
    
    await _prefs.setString(
      _ordersKey,
      jsonEncode(orders.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    final order = await getOrderById(orderId);
    if (order == null) return;
    
    final updatedOrder = order.copyWith(status: status);
    await saveOrder(updatedOrder);
  }
}
