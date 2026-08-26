// lib/core/utils/platform_reload_web.dart
// Used on web — reloads the browser page so translations reload fully.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void reloadApp() {
  html.window.location.reload();
}
