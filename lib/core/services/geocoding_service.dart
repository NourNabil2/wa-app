import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

abstract class GeocodingService {
  Future<String?> getCityFromCoordinates(double lat, double lng);
  Future<String?> getAddressFromCoordinates(double lat, double lng);
}

class GeocodingServiceImpl implements GeocodingService {
  final Dio _dio;
  static const String _googleKey = String.fromEnvironment('GOOGLE_GEOCODING_KEY');

  GeocodingServiceImpl(this._dio);

  @override
  Future<String?> getCityFromCoordinates(double lat, double lng) async {
    if (_googleKey.isNotEmpty) {
      return _getCityFromGoogle(lat, lng);
    } else {
      return _getCityFromNominatim(lat, lng);
    }
  }

  @override
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    if (_googleKey.isNotEmpty) {
      return _getAddressFromGoogle(lat, lng);
    } else {
      return _getAddressFromNominatim(lat, lng);
    }
  }

  Future<String?> _getCityFromGoogle(double lat, double lng) async {
    try {
      final res = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '$lat,$lng',
          'key': _googleKey,
          'result_type': 'locality',
          'language': 'en',
        },
      );
      if (res.data['status'] == 'OK' && res.data['results'].isNotEmpty) {
        return res.data['results'][0]['address_components'][0]['long_name'];
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _getAddressFromGoogle(double lat, double lng) async {
    try {
      final res = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '$lat,$lng',
          'key': _googleKey,
          'language': 'en',
        },
      );
      if (res.data['status'] == 'OK' && res.data['results'].isNotEmpty) {
        return res.data['results'][0]['formatted_address'];
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _getCityFromNominatim(double lat, double lng) async {
    try {
      final res = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        // Browsers block User-Agent as an unsafe header — skip it on web
        options: kIsWeb ? null : Options(headers: {'User-Agent': 'FastwayApp/1.0'}),
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'jsonv2',
          'accept-language': 'en',
        },
      );
      final address = res.data['address'];
      return address['city'] ?? address['town'] ?? address['village'] ?? address['state'];
    } catch (_) {}
    return null;
  }

  Future<String?> _getAddressFromNominatim(double lat, double lng) async {
    try {
      final res = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        options: kIsWeb ? null : Options(headers: {'User-Agent': 'FastwayApp/1.0'}),
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'jsonv2',
          'accept-language': 'en',
        },
      );
      return res.data['display_name'];
    } catch (_) {}
    return null;
  }
}
