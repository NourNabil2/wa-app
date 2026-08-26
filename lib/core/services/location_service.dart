// lib/core/services/location_service.dart

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Lightweight singleton that fetches & caches the device's GPS position.
///
/// KEY RULE — never trigger the browser permission dialog automatically.
/// Location is only fetched if the user has ALREADY granted permission.
/// If permission is not yet granted, we return null silently so the page
/// loads instantly. The user can grant location via the manual "Deliver to"
/// picker in the header.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Position? _cached;
  DateTime? _cachedAt;
  static const _cacheDuration = Duration(minutes: 10);

  /// Returns [Position] if location is ALREADY granted and available.
  /// NEVER shows a permission dialog — returns null silently if not granted.
  Future<Position?> getPosition() async {
    // Return cache if still fresh
    if (_cached != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheDuration) {
      return _cached;
    }

    try {
      // On web, check if service is supported
      final isSupported = await Geolocator.isLocationServiceEnabled();
      if (!isSupported) return null;

      // Only check existing permission — NEVER call requestPermission() here.
      // Showing the browser dialog on every page load is terrible UX.
      final permission = await Geolocator.checkPermission();

      // Only proceed if already granted — never prompt automatically
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );

      _cached = position;
      _cachedAt = DateTime.now();
      return position;
    } catch (e) {
      if (kDebugMode) debugPrint('[LocationService] Failed to get position: $e');
      return null;
    }
  }

  /// Request permission explicitly — only call when user taps the location button.
  /// This is the ONLY place the browser dialog should ever appear.
  Future<Position?> requestAndGetPosition() async {
    try {
      final isSupported = await Geolocator.isLocationServiceEnabled();
      if (!isSupported) return null;

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.deniedForever) return null;

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      _cached = position;
      _cachedAt = DateTime.now();
      return position;
    } catch (e) {
      if (kDebugMode) debugPrint('[LocationService] requestAndGetPosition failed: $e');
      return null;
    }
  }

  /// Convenience: returns {"lat": ..., "lng": ...} map or empty map.
  Future<Map<String, double>> getLatLng() async {
    final pos = await getPosition();
    if (pos == null) return {};
    return {'lat': pos.latitude, 'lng': pos.longitude};
  }

  /// Clear cache (e.g. user changes city manually).
  void clearCache() {
    _cached = null;
    _cachedAt = null;
  }
}
