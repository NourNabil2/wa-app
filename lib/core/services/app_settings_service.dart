import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../di/injection_container.dart';

class AppSettingsService {
  AppSettingsService._();
  static final AppSettingsService instance = AppSettingsService._();

  double _minOrderAmount = 0.0;
  int _returnWindowDays = 14;
  double _freeShippingThreshold = 0.0;
  double _pointsEarningRate = 1.0;
  double _pointsRedemptionRate = 1.0;
  bool _vatEnabled = false;
  double _vatRate = 0.0;

  // Seller / company block for the ZATCA-style invoice view.
  String _vatNumber = '';
  String _sellerName = '';
  String _sellerCity = '';
  String _sellerAddress = '';
  String _sellerPhone = '';
  String _sellerEmail = '';

  double get minOrderAmount => _minOrderAmount;
  int get returnWindowDays => _returnWindowDays;
  double get freeShippingThreshold => _freeShippingThreshold;
  double get pointsEarningRate => _pointsEarningRate;
  double get pointsRedemptionRate => _pointsRedemptionRate;
  bool get vatEnabled => _vatEnabled;
  double get vatRate => _vatRate;
  /// True if VAT should be shown in the UI — either backend flag or rate is set.
  bool get vatVisible => _vatEnabled || _vatRate > 0;

  String get vatNumber => _vatNumber;
  String get sellerName => _sellerName;
  String get sellerCity => _sellerCity;
  String get sellerAddress => _sellerAddress;
  String get sellerPhone => _sellerPhone;
  String get sellerEmail => _sellerEmail;

  bool canReturn(DateTime date) => DateTime.now().difference(date).inDays <= _returnWindowDays;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load from cache
    _minOrderAmount = prefs.getDouble('settings_min_order_amount') ?? 0.0;
    _returnWindowDays = prefs.getInt('settings_return_window_days') ?? 14;
    _freeShippingThreshold = prefs.getDouble('settings_free_shipping_threshold') ?? 0.0;
    _pointsEarningRate = prefs.getDouble('settings_points_earning_rate') ?? 1.0;
    _pointsRedemptionRate = prefs.getDouble('settings_points_redemption_rate') ?? 1.0;
    _vatEnabled = prefs.getBool('settings_vat_enabled') ?? false;
    _vatRate = prefs.getDouble('settings_vat_rate') ?? 0.0;
    _vatNumber = prefs.getString('settings_vat_number') ?? '';
    _sellerName = prefs.getString('settings_seller_name') ?? '';
    _sellerCity = prefs.getString('settings_seller_city') ?? '';
    _sellerAddress = prefs.getString('settings_seller_address') ?? '';
    _sellerPhone = prefs.getString('settings_seller_phone') ?? '';
    _sellerEmail = prefs.getString('settings_seller_email') ?? '';

    // Fetch fresh from API
    try {
      final dio = sl<Dio>();
      final response = await dio.get('/app/settings');
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        
        _minOrderAmount = _parseDouble(data['min_order_amount']) ?? 0.0;
        _returnWindowDays = _parseInt(data['return_window_days']) ?? 14;
        _freeShippingThreshold = _parseDouble(data['free_shipping_threshold']) ?? 0.0;
        _pointsEarningRate = _parseDouble(data['points_earning_rate']) ?? 1.0;
        _pointsRedemptionRate = _parseDouble(data['points_redemption_rate']) ?? 1.0;
        _vatEnabled = data['vat_enabled'] == true || data['vat_enabled'] == 1;
        _vatRate = _parseDouble(data['vat_default_rate']) ?? 0.0;
        _vatNumber = _parseString(data['vat_number']);
        _sellerName = _parseString(data['sender_name']);
        _sellerCity = _parseString(data['sender_city']);
        _sellerAddress = _parseString(data['sender_address']);
        _sellerPhone = _parseString(data['sender_phone']);
        _sellerEmail = _parseString(data['smtp_from_address']);

        await prefs.setDouble('settings_min_order_amount', _minOrderAmount);
        await prefs.setInt('settings_return_window_days', _returnWindowDays);
        await prefs.setDouble('settings_free_shipping_threshold', _freeShippingThreshold);
        await prefs.setDouble('settings_points_earning_rate', _pointsEarningRate);
        await prefs.setDouble('settings_points_redemption_rate', _pointsRedemptionRate);
        await prefs.setBool('settings_vat_enabled', _vatEnabled);
        await prefs.setDouble('settings_vat_rate', _vatRate);
        await prefs.setString('settings_vat_number', _vatNumber);
        await prefs.setString('settings_seller_name', _sellerName);
        await prefs.setString('settings_seller_city', _sellerCity);
        await prefs.setString('settings_seller_address', _sellerAddress);
        await prefs.setString('settings_seller_phone', _sellerPhone);
        await prefs.setString('settings_seller_email', _sellerEmail);
      }
    } catch (e) {
      // Keep cached values
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    // A numeric-looking value (e.g. VAT number) may arrive as num — avoid the
    // trailing ".0" that toString() adds to whole doubles.
    if (value is double && value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}
