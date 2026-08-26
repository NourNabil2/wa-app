// lib/core/layout/web_nav_controller.dart
//
// Syncs the tab index with the browser URL on Flutter Web.
// On mobile (iOS/Android), URL syncing is a no-op — the index logic is identical.
//
// Tab → URL mapping:
//   0 = /                (Home)
//   1 = /blog            (Articles)
//   2 = /cart            (Cart)
//   3 = /profile         (Profile)
//   4 = /orders          (Orders)
//
// Points is NOT a Dashboard tab — it has no slot in the IndexedStack.
// It's always reached via a standalone route push
// (AppNavigator.pushNamed(context, Routes.points)), never via navigateTo().

import 'package:flutter/foundation.dart';

// Conditional import: dart:html on web, a stub on native.
import 'web_url_helper.dart'
    if (dart.library.html) 'web_url_helper_web.dart';

class WebNavController extends ChangeNotifier {
  static final WebNavController instance = WebNavController._internal();

  factory WebNavController() {
    return instance;
  }

  WebNavController._internal();

  static const List<String> _tabUrls = [
    '/',              // 0 — Home
    '/blog',          // 1 — Articles / Blog
    '/cart',          // 2 — Cart
    '/profile',       // 3 — Profile
    '/orders',        // 4 — Orders
  ];

  /// On web: determine tab from the current browser path on first load.
  /// On mobile: always start at 0 (Home).
  static int _indexFromCurrentUrl() {
    if (!kIsWeb) return 0;
    final path = WebUrlHelper.currentPath();
    // Match most-specific first (profile/points before profile)
    for (int i = _tabUrls.length - 1; i >= 0; i--) {
      if (_tabUrls[i] != '/' && path.startsWith(_tabUrls[i])) return i;
    }
    return 0; // '/' or unknown → Home
  }

  int _currentIndex = _indexFromCurrentUrl();

  int get currentIndex => _currentIndex;

  /// Navigate to tab [index].
  /// On web: also updates the browser address bar.
  void navigateTo(int index) {
    if (index < 0 || index >= _tabUrls.length) return;
    if (_currentIndex != index) {
      _currentIndex = index;
      WebUrlHelper.pushPath(_tabUrls[index]);
      notifyListeners();
    }
  }
}