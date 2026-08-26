import 'package:fastway/features/checkout/domain/entities/city_entity.dart';

String _s(dynamic v, [String fallback = '']) {
  if (v == null) return fallback;
  if (v is String) return v;
  if (v is Map) return v['en']?.toString() ?? v.values.firstOrNull?.toString() ?? fallback;
  return v.toString();
}

class CityModel extends CityEntity {
  const CityModel({
    required super.name,
    required super.nameAr,
    required super.code,
    required super.lat,
    required super.lng,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      name: _s(json['name']),
      nameAr: _s(json['name_ar']),
      code: _s(json['code']),
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'name_ar': nameAr,
    'code': code,
    'lat': lat,
    'lng': lng,
  };
}

class CountryModel extends CountryEntity {
  const CountryModel({
    required super.code,
    required super.name,
    required super.nameAr,
    required super.currency,
    required super.phoneCode,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      code: _s(json['code']),
      name: _s(json['name']),
      nameAr: _s(json['name_ar']),
      currency: _s(json['currency']),
      phoneCode: _s(json['phone_code']),
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'name_ar': nameAr,
    'currency': currency,
    'phone_code': phoneCode,
  };
}