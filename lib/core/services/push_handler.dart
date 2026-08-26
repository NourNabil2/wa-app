// lib/core/services/push_handler.dart
//
// Handles FCM push notification lifecycle for all platforms:
//   - Android / iOS: full local notification display + tap navigation
//   - Web: token registration via VAPID key, foreground message listener

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../api/base_api_services.dart';
import '../api/model/endpoints.dart';
import '../api/model/http_method.dart';
import '../di/injection_container.dart';
import '../routes/routes.dart';

// Top-level handler required by Firebase for background message processing.
// On web this function is never registered.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM BG] ${message.notification?.title}: ${message.notification?.body}');
}

class PushHandler {
  PushHandler._();

  static final _instance = PushHandler._();
  static PushHandler get instance => _instance;

  // VAPID public key for Web Push — fastway-64ae7 project
  // Firebase Console → fastway-64ae7 → Project Settings → Cloud Messaging → Web Push certificates
  static const _vapidKey =
      'BKnZ7z_mRJ3K3LiQ9L1bRD97VQcUycr8w5D3Az7UEZAGlDozcjBtKPG4RI5EYoq9__OOeqkz2lyyaEQc2IJpv9Q';

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  // Android high-priority channel
  static const _androidChannel = AndroidNotificationChannel(
    'fastway_orders',
    'Order Updates',
    description: 'Notifications for order status changes',
    importance: Importance.max,
    playSound: true,
  );

  /// Call once from main() after Firebase.initializeApp().
  Future<void> initialize({required GlobalKey<NavigatorState> navigatorKey}) async {
    if (kIsWeb) {
      await _initializeWeb();
      return;
    }

    await _initializeNative(navigatorKey);
  }

  // ── Web ──────────────────────────────────────────────────────────────────

  Future<void> _initializeWeb() async {
    try {
      // Request notification permission from the browser
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[FCM Web] Permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('[FCM Web] Permission denied — skipping token registration.');
        return;
      }

      // Get the web push token using the VAPID key
      final token = await _fcm.getToken(vapidKey: _vapidKey);
      if (token != null) {
        await _postToken(token);
      }

      // Refresh token listener
      _fcm.onTokenRefresh.listen(_postToken);

      // Foreground message listener for web
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('[FCM Web] Foreground: ${message.notification?.title}');
        // Web shows its own browser notification — no local_notifications needed
      });

      debugPrint('[FCM Web] Initialized successfully.');
    } catch (e) {
      debugPrint('[FCM Web] Initialization failed: $e');
    }
  }

  // ── Native (Android + iOS) ────────────────────────────────────────────────

  Future<void> _initializeNative(GlobalKey<NavigatorState> navigatorKey) async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Set up local notifications plugin for foreground display
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (details) {
        _handleTap(details.payload, navigatorKey);
      },
    );

    // Create Android channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // iOS foreground presentation
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _requestPermissionNative();
    await _registerTokenNative();

    _fcm.onTokenRefresh.listen(_postToken);

    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message, navigatorKey);
    });

    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationTap(initialMessage, navigatorKey);
      });
    }
  }

  Future<void> _requestPermissionNative() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');
  }

  Future<void> _registerTokenNative() async {
    try {
      // iOS-only: FirebaseMessaging.getToken() returns null if the APNs token
      // isn't set yet. On a fresh launch APNs registration is async, so we must
      // wait for it before asking FCM for a token — otherwise iOS silently never
      // registers a device token and no push can ever arrive (the exact "Android
      // works, iOS doesn't" symptom). Android has no APNs layer, so skip the wait.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _waitForApnsToken();
      }

      final token = await _fcm.getToken();
      if (token != null) {
        await _postToken(token);
      } else {
        debugPrint('[FCM] getToken() returned null (APNs not ready?).');
      }
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }
  }

  /// Poll for the APNs token (iOS). Returns once available or after a timeout.
  Future<void> _waitForApnsToken() async {
    const maxAttempts = 10; // ~5s total
    for (var i = 0; i < maxAttempts; i++) {
      final apns = await _fcm.getAPNSToken();
      if (apns != null) {
        debugPrint('[FCM] APNs token ready.');
        return;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    debugPrint('[FCM] APNs token not available after waiting — proceeding anyway.');
  }

  // ── Shared ────────────────────────────────────────────────────────────────

  // Cache the last FCM token we obtained so we can re-register (claim) it to the
  // user after login without having to re-query Firebase.
  String? _lastToken;

  Future<void> _postToken(String token) async {
    _lastToken = token;
    try {
      // Use the app's shared API service. Its interceptor automatically attaches
      // BOTH the Authorization bearer (from UserRepository.currentUser) AND the
      // X-Session-ID header — so a logged-in user's token gets linked to their
      // account, and a guest's token gets linked to their session_id (enabling
      // guest push). The previous raw-Dio call read a non-existent 'token' pref
      // key (always null) and never sent X-Session-ID, so EVERY token landed with
      // user_id AND session_id null and could never be targeted.
      final api = sl<BaseApiServices>();
      await api.request(
        method: HttpMethod.post,
        url: Endpoints.deviceTokens,
        body: {
          'token': token,
          'platform': kIsWeb
              ? 'web'
              : defaultTargetPlatform == TargetPlatform.iOS
                  ? 'ios'
                  : 'android',
        },
      );
      debugPrint('[FCM] Token registered: ${token.substring(0, 20)}...');
    } catch (e) {
      debugPrint('[FCM] Token POST failed: $e');
    }
  }

  /// Re-register the current device token so the backend can CLAIM it to the
  /// now-authenticated user. Call this right after a successful login/registration
  /// (the token was first posted at app launch while still a guest, so without
  /// this it would stay unlinked until the next cold start).
  Future<void> refreshRegistration() async {
    final token = _lastToken ?? await _fcm.getToken();
    if (token != null) {
      await _postToken(token);
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['type'] != null
          ? _encodePayload(message.data)
          : null,
    );
  }

  // payload string format: type|order_id|order_number|code
  // (code is used by cart_discount to auto-apply the coupon in the cart)
  String _encodePayload(Map<String, dynamic> data) =>
      '${data['type']}|${data['order_id'] ?? ''}|${data['order_number'] ?? ''}|${data['code'] ?? ''}';

  void _handleNotificationTap(
      RemoteMessage message, GlobalKey<NavigatorState> navigatorKey) {
    _handleTap(_encodePayload(message.data), navigatorKey);
  }

  void _handleTap(String? payload, GlobalKey<NavigatorState> navigatorKey) {
    if (payload == null || payload.isEmpty) return;
    final parts = payload.split('|');
    final type = parts.isNotEmpty ? parts[0] : '';
    final orderId = parts.length > 1 ? parts[1] : '';
    final code = parts.length > 3 ? parts[3] : '';

    switch (type) {
      case 'order_placed':
      case 'order_status':
      case 'order_update':
        if (orderId.isNotEmpty) {
          navigatorKey.currentState?.pushNamed('${Routes.orderDetails}/$orderId');
        } else {
          navigatorKey.currentState?.pushNamed(Routes.orders);
        }
        break;
      case 'cart_abandonment':
        navigatorKey.currentState?.pushNamed(Routes.cart);
        break;
      case 'cart_discount':
        // Deep-link to the cart and auto-apply the discount code from the push.
        navigatorKey.currentState?.pushNamed(
          Routes.cart,
          arguments: code.isNotEmpty ? {'coupon': code} : null,
        );
        break;
      case 'return':
      case 'return_submitted':
        navigatorKey.currentState?.pushNamed(Routes.orders);
        break;
      case 'back_in_stock':
        final productId = parts.length > 1 ? parts[1] : '';
        if (productId.isNotEmpty) {
          navigatorKey.currentState?.pushNamed('${Routes.productDetails}/$productId');
        }
        break;
      default:
        navigatorKey.currentState?.pushNamed(Routes.dashBoard);
    }
  }
}
