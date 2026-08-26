// lib/core/layout/web_url_helper_web.dart
// WEB IMPLEMENTATION — only compiled on Flutter Web (dart:html available).
//
// IMPORTANT: We push state objects WITHOUT Flutter's 'serialCount' key.
// This means Flutter's internal BrowserHistory ignores our entries when
// popstate fires (it checks serialCount and skips if unrecognised).
// Our own popstate listener handles navigation for these entries instead.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class WebUrlHelper {
  /// When true, the next popstate event is ignored by our listener.
  /// Set by [goBack] to prevent the history.back() call from
  /// triggering a second maybePop (Flutter already handled the pop).
  static bool _ignoreNextPopState = false;

  /// Returns the current browser path (e.g. '/blog', '/profile').
  static String currentPath() {
    try {
      return html.window.location.pathname ?? '/';
    } catch (_) {
      return '/';
    }
  }

  /// Adds a new browser history entry with our custom state (no serialCount).
  /// Flutter's engine ignores entries without serialCount in popstate events,
  /// so our own listener handles the back button for these entries.
  static void pushPath(String path) {
    try {
      html.window.history.pushState(null, '', path);
    } catch (_) {}
  }

  /// Replaces the current history entry's URL (no new back-button step).
  static void replacePath(String path) {
    try {
      html.window.history.replaceState(null, '', path);
    } catch (_) {}
  }

  /// Navigates the browser back one history entry.
  /// Sets [_ignoreNextPopState] so our popstate listener skips the resulting
  /// event (Flutter already popped the route before this was called).
  static void goBack() {
    _ignoreNextPopState = true;
    html.window.history.back();
  }

  /// Registers a listener for the browser back/forward button (popstate).
  /// Call once at startup. [onBack] fires when the user presses the browser
  /// back button, allowing us to pop Flutter's route stack in sync.
  static void initBackButtonHandler(Future<void> Function() onBack) {
    html.window.onPopState.listen((_) {
      if (_ignoreNextPopState) {
        _ignoreNextPopState = false;
        return;
      }
      onBack();
    });
  }
}
