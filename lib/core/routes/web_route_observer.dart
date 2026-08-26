// lib/core/routes/web_route_observer.dart
//
// NavigatorObserver that keeps the browser URL and history stack in sync
// with Flutter's Navigator on web.
//
// Two sources of navigation:
//
// 1. IN-APP navigation (user taps a link or AppBar back arrow):
//    - didPush → pushState (adds browser history entry)
//    - didPop  → history.back() (moves browser back to match)
//
// 2. BROWSER navigation (user clicks browser back/forward):
//    - Our popstate listener in main.dart sets [handlingBrowserBack] = true
//      then calls maybePop(). When didPop fires, we skip history.back()
//      because the browser already moved — calling it again would double-back.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fastway/core/layout/web_url_helper.dart'
    if (dart.library.html) 'package:fastway/core/layout/web_url_helper_web.dart';

class WebRouteObserver extends NavigatorObserver {
  /// Set to true by the popstate handler in main.dart BEFORE calling
  /// Navigator.maybePop(). Cleared in didPop so it's reset per pop.
  ///
  /// When true, didPop skips calling WebUrlHelper.goBack() because the
  /// browser already navigated back via its own back button.
  static bool handlingBrowserBack = false;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!kIsWeb) return;
    if (route is! PageRoute) return;
    
    final name = route.settings.name;
    if (name == null || name.isEmpty) return;

    // Skip if the browser is already at this URL (e.g. initial '/' on startup).
    // Without this check, a phantom duplicate entry is created that wastes
    // one back-button press.
    if (WebUrlHelper.currentPath() == name) return;

    WebUrlHelper.pushPath(name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!kIsWeb) return;
    if (route is! PageRoute) return;

    final name = route.settings.name;
    if (name == null || name.isEmpty) return;

    if (handlingBrowserBack) {
      // Pop was triggered by the browser back button. The browser already
      // moved back — its URL and history are correct. Do nothing.
      return;
    }

    // Pop was triggered in-app (e.g. AppBar back arrow, Navigator.pop()).
    // The browser doesn't know about this — sync by calling history.back().
    // WebUrlHelper.goBack() sets an internal flag so that the resulting
    // popstate event is ignored by our listener (preventing a double-pop).
    WebUrlHelper.goBack();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (!kIsWeb) return;
    if (newRoute != null && newRoute is PageRoute) {
      final name = newRoute.settings.name;
      if (name == null || name.isEmpty) return;
      WebUrlHelper.replacePath(name);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Route removed from the stack (e.g. pushAndRemoveUntil).
    // Browser history entries for removed routes remain but are harmless —
    // if the user navigates back to them, onGenerateRoute will handle it.
  }
}
