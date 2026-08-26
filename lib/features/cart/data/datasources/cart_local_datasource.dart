import 'dart:convert';
import 'package:fastway/features/cart/domain/entities/cart_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_model.dart';


abstract class CartLocalDataSource {
  Future<CartModel> getCart();
  Future<CartModel> saveCart(CartModel cart);
  Future<CartModel> addItem(CartItemModel item);
  Future<CartModel> updateItem(String itemId, int quantity);
  Future<CartModel> removeItem(String itemId);
  Future<CartModel> clearCart();
  Future<CartModel> applyCoupon(String couponCode);
  Future<CartModel> removeCoupon();
}

class CartLocalDataSourceImpl implements CartLocalDataSource {
  final SharedPreferences _prefs;
  static const String _cartKey = 'cart_data';

  CartLocalDataSourceImpl(this._prefs);

  @override
  Future<CartModel> getCart() async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate delay
    
    final cartJson = _prefs.getString(_cartKey);
    if (cartJson != null) {
      return CartModel.fromJson(jsonDecode(cartJson));
    }
    
    // Return empty cart
    return const CartModel(
      items: [],
      subtotal: 0,
      discount: 0,
      shippingCost: 0,
      total: 0,
    );
  }

  @override
  Future<CartModel> saveCart(CartModel cart) async {
    await _prefs.setString(_cartKey, jsonEncode(cart.toJson()));
    return cart;
  }

  @override
  Future<CartModel> addItem(CartItemModel newItem) async {
    final cart = await getCart();
    final items = List<CartItemEntity>.from(cart.items);
    
    // Check if item already exists
    final existingIndex = items.indexWhere(
      (item) => item.productId == newItem.productId,
    );
    
    if (existingIndex != -1) {
      // Update quantity if exists
      final existingItem = items[existingIndex] as CartItemModel;
      items[existingIndex] = existingItem.copyWithModel(
        quantity: existingItem.quantity + newItem.quantity,
      );
    } else {
      // Add new item
      items.add(newItem);
    }
    
    final updatedCart = _calculateTotals(
      cart.copyWithModel(items: items),
    );
    
    return saveCart(updatedCart);
  }

  @override
  Future<CartModel> updateItem(String itemId, int quantity) async {
    final cart = await getCart();
    final items = List<CartItemEntity>.from(cart.items);
    
    final index = items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      if (quantity <= 0) {
        items.removeAt(index);
      } else {
        final item = items[index] as CartItemModel;
        items[index] = item.copyWithModel(quantity: quantity);
      }
    }
    
    final updatedCart = _calculateTotals(
      cart.copyWithModel(items: items),
    );
    
    return saveCart(updatedCart);
  }

  @override
  Future<CartModel> removeItem(String itemId) async {
    final cart = await getCart();
    final items = cart.items.where((item) => item.id != itemId).toList();
    
    final updatedCart = _calculateTotals(
      cart.copyWithModel(items: items),
    );
    
    return saveCart(updatedCart);
  }

  @override
  Future<CartModel> clearCart() async {
    const emptyCart = CartModel(
      items: [],
      subtotal: 0,
      discount: 0,
      shippingCost: 0,
      total: 0,
    );
    return saveCart(emptyCart);
  }

  @override
  Future<CartModel> applyCoupon(String couponCode) async {
    final cart = await getCart();
    
    // Mock coupon logic
    double? couponDiscount;
    if (couponCode.toUpperCase() == 'SAVE10') {
      couponDiscount = cart.subtotal * 0.10; // 10% discount
    } else if (couponCode.toUpperCase() == 'SAVE20') {
      couponDiscount = cart.subtotal * 0.20; // 20% discount
    } else if (couponCode.toUpperCase() == 'FIRST') {
      couponDiscount = 50; // 50 SAR flat discount
    }
    
    final updatedCart = _calculateTotals(
      cart.copyWithModel(
        couponCode: couponCode,
        couponDiscount: couponDiscount,
      ),
    );
    
    return saveCart(updatedCart);
  }

  @override
  Future<CartModel> removeCoupon() async {
    final cart = await getCart();
    
    final updatedCart = _calculateTotals(
      cart.copyWithModel(
        couponCode: null,
        couponDiscount: null,
      ),
    );
    
    return saveCart(updatedCart);
  }

  CartModel _calculateTotals(CartModel cart) {
    double subtotal = 0;
    double discount = 0;
    
    for (final item in cart.items) {
      subtotal += item.price * item.quantity;
      if (item.originalPrice != null && item.originalPrice! > item.price) {
        discount += (item.originalPrice! - item.price) * item.quantity;
      }
    }
    
    // Calculate shipping (free if subtotal > 500)
    double shippingCost = subtotal > 500 ? 0 : 50;
    
    // Apply coupon discount
    double couponDiscount = cart.couponDiscount ?? 0;
    
    // Calculate total
    double total = subtotal + shippingCost - couponDiscount - (cart.tierDiscount ?? 0);
    if (total < 0) total = 0;
    
    return cart.copyWithModel(
      subtotal: subtotal,
      discount: discount,
      shippingCost: shippingCost,
      total: total,
    );
  }
}
