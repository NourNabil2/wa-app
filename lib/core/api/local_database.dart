import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDatabase {
  final SharedPreferences prefs;

  LocalDatabase(this.prefs) {
    _initBalances();
  }

  void _initBalances() {
    if (prefs.getDouble('wallet_balance') == null) {
      prefs.setDouble('wallet_balance', 5000.0);
    }
    if (prefs.getInt('points_balance') == null) {
      prefs.setInt('points_balance', 15000);
    }
  }

  double get walletBalance => prefs.getDouble('wallet_balance') ?? 0.0;
  int get pointsBalance => prefs.getInt('points_balance') ?? 0;

  // Cart operations
  List<Map<String, dynamic>> get cartItems {
    final String? cartStr = prefs.getString('cart_items');
    if (cartStr == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(cartStr));
  }

  void saveCart(List<Map<String, dynamic>> items) {
    prefs.setString('cart_items', jsonEncode(items));
  }

  void clearCart() {
    prefs.remove('cart_items');
  }

  // Get current Cart JSON response
  Map<String, dynamic> getCartResponse() {
    final items = cartItems;
    double subtotal = 0;
    for (var item in items) {
      subtotal += (item['price'] * item['quantity']);
    }
    
    double discount = 0;
    double couponDiscount = 0;
    String? couponCode = prefs.getString('applied_coupon');
    String? savingsMessage;

    if (couponCode != null && couponCode.toUpperCase() == 'FAST50') {
      if (subtotal >= 200) {
        discount = 50;
        couponDiscount = 50;
        savingsMessage = "تم تطبيق خصم 50 ر.س بنجاح!";
      } else {
        couponCode = null; // conditions not met, treat as removed
      }
    }

    double total = subtotal - discount;
    if (total < 0) total = 0;

    return {
      "data": {
        "items": items,
        "subtotal": subtotal,
        "discount": discount,
        "coupon_code": couponCode,
        "coupon_discount": couponDiscount,
        "total_savings": discount,
        "savings_message": savingsMessage,
        "shipping_cost": 0,
        "total": total,
      },
      "message": "Success"
    };
  }

  void applyCouponCode(String code) {
    prefs.setString('applied_coupon', code.toUpperCase());
  }

  void removeCouponCode() {
    prefs.remove('applied_coupon');
  }

  // Mock products mapping for getting price and details
  final Map<int, Map<String, dynamic>> mockProducts = {
    101: {
      "id": 101,
      "name": "سبحة كهرمان أصلي 33 حبة",
      "name_ar": "سبحة كهرمان أصلي 33 حبة",
      "price": 450,
      "original_price": 500,
      "image": "assets/images/rosary_amber_1786203630351.jpg",
      "image_url": "assets/images/rosary_amber_1786203630351.jpg",
      "gallery": [
        "assets/images/rosary_amber_1786203630351.jpg"
      ],
      "slug": "kahraman-33",
      "rating": 4.8,
      "review_count": 124,
      "description": "Premium authentic amber rosary consisting of 33 beads. Handcrafted to perfection, offering a warm touch and pleasant natural scent.",
      "description_ar": "سبحة كهرمان طبيعي فاخرة تتكون من 33 حبة. مصنوعة يدوياً بحرفية عالية لتمنحك ملمساً دافئاً ورائحة طبيعية زكية. تأتي مع تغليف فاخر مناسب للهدايا.",
      "brand": "كهرمان أصلي",
      "brand_name": "كهرمان أصلي",
      "category_name": "كهرمان",
      "category_name_ar": "كهرمان",
      "stock": 15,
      "is_available": true,
      "is_wishlisted": false,
      "sku": "ROS-AMB-33",
      "ingredients": ["Natural Amber Stone", "Durable Silk Thread", "925 Silver Tassel"],
      "ingredients_ar": ["حجر كهرمان طبيعي", "خيط حرير متين", "شرابة فضية عيار 925"],
      "benefits": ["Relieves Stress", "Natural Calming Scent"],
      "benefits_ar": ["تخفيف التوتر", "رائحة طبيعية مهدئة"],
      "usage": "Used for daily Tasbeeh and makes a perfect gift for special occasions.",
      "usage_ar": "تستخدم للتسبيح والذكر اليومي، وتعتبر هدية قيمة جداً في المناسبات الخاصة.",
      "variant_group_label": "Choose Size",
      "variant_group_label_ar": "اختر عدد الحبات",
      "variants": [
        {
          "id": 101,
          "name": "33 Beads",
          "name_ar": "33 حبة",
          "price": 450,
          "in_stock": true,
          "image_url": "assets/images/rosary_amber_1786203630351.jpg"
        },
        {
          "id": 104,
          "name": "99 Beads",
          "name_ar": "99 حبة",
          "price": 1250,
          "in_stock": true,
          "image_url": "assets/images/rosary_amber_1786203630351.jpg"
        }
      ],
      "reviews": [
        {
          "id": 1,
          "user_name": "Ahmed Ali",
          "rating": 5,
          "comment": "ممتازة جداً وخامتها أصلية، أنصح بها بشدة.",
          "date": "2023-10-15T10:30:00Z",
          "is_verified_purchase": true
        },
        {
          "id": 2,
          "user_name": "Omar",
          "rating": 4,
          "comment": "سبحة جميلة ولكن السعر مرتفع قليلاً.",
          "date": "2023-11-02T14:15:00Z",
          "is_verified_purchase": true
        }
      ]
    },
    104: {
      "id": 104,
      "name": "سبحة كهرمان أصلي 99 حبة",
      "name_ar": "سبحة كهرمان أصلي 99 حبة",
      "price": 1250,
      "original_price": 1400,
      "image": "assets/images/rosary_amber_1786203630351.jpg",
      "image_url": "assets/images/rosary_amber_1786203630351.jpg",
      "gallery": [
        "assets/images/rosary_amber_1786203630351.jpg"
      ],
      "slug": "kahraman-99",
      "rating": 4.9,
      "review_count": 55,
      "description": "Premium authentic amber rosary consisting of 99 beads.",
      "description_ar": "سبحة كهرمان طبيعي فاخرة تتكون من 99 حبة. تصميم ملكي للاستخدام الطويل.",
      "brand": "كهرمان أصلي",
      "brand_name": "كهرمان أصلي",
      "category_name": "كهرمان",
      "category_name_ar": "كهرمان",
      "stock": 5,
      "is_available": true,
      "is_wishlisted": false,
      "sku": "ROS-AMB-99",
      "ingredients": ["Natural Amber Stone", "Durable Silk Thread", "925 Silver Tassel"],
      "ingredients_ar": ["حجر كهرمان طبيعي", "خيط حرير متين", "شرابة فضية عيار 925"],
      "benefits": ["Relieves Stress", "Natural Calming Scent", "Longer usage"],
      "benefits_ar": ["تخفيف التوتر", "رائحة طبيعية مهدئة", "تسبيح ممتد"],
      "usage_ar": "تستخدم للتسبيح الطويل في صلوات التراويح والتهجد.",
      "variant_group_label": "Choose Size",
      "variant_group_label_ar": "اختر عدد الحبات",
      "variants": [
        {
          "id": 101,
          "name": "33 Beads",
          "name_ar": "33 حبة",
          "price": 450,
          "in_stock": true,
          "image_url": "assets/images/rosary_amber_1786203630351.jpg"
        },
        {
          "id": 104,
          "name": "99 Beads",
          "name_ar": "99 حبة",
          "price": 1250,
          "in_stock": true,
          "image_url": "assets/images/rosary_amber_1786203630351.jpg"
        }
      ],
      "reviews": [
        {
          "id": 5,
          "user_name": "Fahad",
          "rating": 5,
          "comment": "روعة الـ 99 حبة مريحة جدا في اليد.",
          "date": "2023-11-20T10:30:00Z",
          "is_verified_purchase": true
        }
      ]
    },
    102: {
      "id": 102,
      "name": "سبحة خشب كوك أسود بفضة",
      "name_ar": "سبحة خشب كوك أسود بفضة",
      "price": 120,
      "image": "assets/images/rosary_black_wood_1786203639953.jpg",
      "image_url": "assets/images/rosary_black_wood_1786203639953.jpg",
      "gallery": [
        "assets/images/rosary_black_wood_1786203639953.jpg"
      ],
      "slug": "kuka-black",
      "rating": 4.5,
      "review_count": 89,
      "description_ar": "سبحة من خشب الكوك الأسود الفاخر، مطعمة بفواصل من الفضة الإسترليني عيار 925 لتعطي مظهراً أنيقاً وعصرياً. مثالية للاستخدام اليومي.",
      "brand": "ورشة الكوك",
      "brand_name": "ورشة الكوك",
      "stock": 50,
      "is_available": true,
      "sku": "ROS-KUK-BLK",
      "ingredients_ar": ["خشب كوك طبيعي", "فواصل فضة 925"],
      "benefits_ar": ["متانة عالية", "مظهر كلاسيكي عصري", "خفيفة الوزن"],
      "usage_ar": "للاستخدام اليومي والعملي.",
      "variants": [],
      "reviews": [
        {
          "id": 3,
          "user_name": "Mahmoud",
          "rating": 5,
          "comment": "خشب الكوك ممتاز جدا وصوته رائع في التسبيح.",
          "date": "2023-12-01T09:00:00Z",
          "is_verified_purchase": true
        }
      ]
    },
    103: {
      "id": 103,
      "name": "سبحة فضة عيار 925",
      "name_ar": "سبحة فضة عيار 925",
      "price": 850,
      "original_price": 1000,
      "image": "assets/images/rosary_silver_1786203649816.jpg",
      "image_url": "assets/images/rosary_silver_1786203649816.jpg",
      "gallery": [
        "assets/images/rosary_silver_1786203649816.jpg"
      ],
      "slug": "silver-925",
      "rating": 4.9,
      "review_count": 210,
      "description_ar": "سبحة فضية بالكامل عيار 925، تتميز بلمعان لا ينطفئ ووزن مثالي يبرز الفخامة والرقي في الاستخدام اليومي.",
      "brand": "Silver Elegance",
      "brand_name": "Silver Elegance",
      "stock": 5,
      "is_available": true,
      "sku": "ROS-SLV-925",
      "ingredients_ar": ["فضة خالصة عيار 925"],
      "benefits_ar": ["فخامة لا تضاهى", "لا يتغير لونها مع الزمن", "ملمس بارد ومميز"],
      "usage_ar": "للمناسبات الرسمية وكهدية للآباء وكبار الشخصيات.",
      "variants": [],
      "reviews": [
        {
          "id": 4,
          "user_name": "Khaled",
          "rating": 5,
          "comment": "فخامة لا توصف، تصلح كهدية قيمة جداً.",
          "date": "2024-01-10T16:20:00Z",
          "is_verified_purchase": true
        }
      ]
    }
  };

  Map<String, dynamic> addToCart(int productId, int quantity) {
    final items = cartItems;
    
    // Check if product exists in cart
    final existingIndex = items.indexWhere((i) => i['product_id'] == productId);
    
    if (existingIndex >= 0) {
      items[existingIndex]['quantity'] += quantity;
    } else {
      final product = mockProducts[productId];
      if (product != null) {
        items.add({
          "id": DateTime.now().millisecondsSinceEpoch,
          "product_id": productId,
          "quantity": quantity,
          "price": product['price'],
          "total": product['price'] * quantity,
          "product": product
        });
      }
    }
    
    saveCart(items);
    return getCartResponse();
  }

  Map<String, dynamic> updateCartItem(int itemId, int quantity) {
      final items = cartItems;
      final index = items.indexWhere((i) => i['id'] == itemId || i['product_id'] == itemId);
      if (index >= 0) {
        if (quantity <= 0) {
          items.removeAt(index);
        } else {
          items[index]['quantity'] = quantity;
          items[index]['total'] = items[index]['price'] * quantity;
        }
      }
      saveCart(items);
      return getCartResponse();
    }

    Map<String, dynamic> removeCartItem(int itemId) {
      final items = cartItems;
      items.removeWhere((i) => i['id'] == itemId || i['product_id'] == itemId);
      saveCart(items);
      return getCartResponse();
    }

  List<Map<String, dynamic>> get orders {
    final str = prefs.getString('orders');
    return str != null ? List<Map<String, dynamic>>.from(jsonDecode(str)) : [];
  }

  void saveOrders(List<Map<String, dynamic>> o) {
    prefs.setString('orders', jsonEncode(o));
  }

  Map<String, dynamic> placeOrder(Map<String, dynamic> body) {
    final cart = getCartResponse()['data'];
    double total = cart['total'] ?? 0;
    
    // Deduct wallet if used
    if (body['payment_method_id'] == 10) { // Assuming 10 is wallet
       prefs.setDouble('wallet_balance', walletBalance - total);
    }

    final newOrder = {
      "id": DateTime.now().millisecondsSinceEpoch,
      "order_number": "ORD-${DateTime.now().millisecondsSinceEpoch}",
      "status": "processing",
      "created_at": DateTime.now().toIso8601String(),
      "subtotal": cart['subtotal'],
      "shipping_cost": cart['shipping_cost'] ?? 0,
      "vat_amount": cart['tax_total'] ?? 0,
      "total": total,
      "payment_method": "Cash on Delivery",
      "shipping_address": "Riyadh, Saudi Arabia",
      "items": cart['items'].map((i) => {
        "id": i['id'],
        "product_id": i['product_id'],
        "name": i['product']?['name'] ?? "Product",
        "image_url": i['product']?['image'] ?? "",
        "price": i['price'],
        "quantity": i['quantity']
      }).toList(),
      "timeline": [
        {
          "status": "processing",
          "title": "Order Placed",
          "description": "Your order has been placed successfully.",
          "occurred_at": DateTime.now().toIso8601String()
        }
      ]
    };

    final currentOrders = orders;
    currentOrders.insert(0, newOrder);
    saveOrders(currentOrders);

    clearCart();
    
    return {
      "data": {
        "order": newOrder
      },
      "message": "Order placed successfully"
    };
  }

  List<dynamic> getOrders() {
    return orders;
  }

  Map<String, dynamic>? getOrder(String id) {
    return orders.firstWhere((o) => o['id'].toString() == id || o['order_number'] == id, orElse: () => {});
  }
}
