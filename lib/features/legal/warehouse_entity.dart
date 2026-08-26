// lib/features/legal/warehouse_entity.dart

class WarehouseEntity {
  final int id;
  final String name;
  final String nameAr;
  final String city;
  final String? district;
  final String address;
  final String? phone;
  final bool isDefault;
  final bool isExpress;
  final double? lat;
  final double? lng;

  const WarehouseEntity({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.city,
    this.district,
    required this.address,
    this.phone,
    required this.isDefault,
    required this.isExpress,
    this.lat,
    this.lng,
  });

  factory WarehouseEntity.fromJson(Map<String, dynamic> json) {
    return WarehouseEntity(
      id:        json['id'] as int,
      name:      json['name'] as String? ?? '',
      nameAr:    json['name_ar'] as String? ?? json['name'] as String? ?? '',
      city:      json['city'] as String? ?? '',
      district:  json['district'] as String?,
      address:   json['address'] as String? ?? '',
      phone:     json['phone'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      isExpress: json['is_express'] as bool? ?? false,
      lat:       (json['lat'] as num?)?.toDouble(),
      lng:       (json['lng'] as num?)?.toDouble(),
    );
  }

  bool get hasLocation => lat != null && lng != null;
  bool get hasPhone    => phone != null && phone!.isNotEmpty;

  /// Full formatted address combining district + city
  String get fullAddressEn {
    final parts = [address, if (district != null) district!, city]
        .where((p) => p.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  String get fullAddressAr => fullAddressEn; // TODO: add name_ar fields for city/district if backend adds them
}
