// lib/core/utils/platform_reload.dart
//
// Conditional import: on web uses dart:html window.location.reload(),
// on native (iOS/Android) does a Flutter engine restart equivalent.

export 'platform_reload_stub.dart'
    if (dart.library.html) 'platform_reload_web.dart';
