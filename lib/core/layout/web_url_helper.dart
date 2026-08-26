// lib/core/layout/web_url_helper.dart
// STUB — used on mobile (iOS, Android, desktop).
// All methods are no-ops so mobile builds are completely unaffected.

class WebUrlHelper {
  /// Returns the current browser path. On mobile always '/'.
  static String currentPath() => '/';

  /// Updates the browser address bar. No-op on mobile.
  static void pushPath(String path) {}

  /// Replaces the current URL. No-op on mobile.
  static void replacePath(String path) {}

  /// Navigates browser back one entry. No-op on mobile.
  static void goBack() {}

  /// Listens to the browser back-button (popstate). No-op on mobile.
  static void initBackButtonHandler(Future<void> Function() onBack) {}
}
