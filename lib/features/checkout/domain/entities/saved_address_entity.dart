// lib/features/addresses/domain/entities/address_entity.dart

class AddressEntity {
  final String id;
  final String label;
  final String fullAddress;
  final String phone;
  final String city;
  final bool isDefault;
  final String? building;
  final String? street;
  final String? district;
  final String? shortAddress;
  final String? postalCode;
  final String? additionalNumber;
  final double? lat;
  final double? lng;

  const AddressEntity({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.phone,
    required this.city,
    required this.isDefault,
    this.building,
    this.street,
    this.district,
    this.shortAddress,
    this.postalCode,
    this.additionalNumber,
    this.lat,
    this.lng,
  });

  AddressEntity copyWith({
    String? id,
    String? label,
    String? fullAddress,
    String? phone,
    String? city,
    bool? isDefault,
    String? building,
    String? street,
    String? district,
    String? shortAddress,
    String? postalCode,
    String? additionalNumber,
    double? lat,
    double? lng,
  }) {
    return AddressEntity(
      id: id ?? this.id,
      label: label ?? this.label,
      fullAddress: fullAddress ?? this.fullAddress,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      isDefault: isDefault ?? this.isDefault,
      building: building ?? this.building,
      street: street ?? this.street,
      district: district ?? this.district,
      shortAddress: shortAddress ?? this.shortAddress,
      postalCode: postalCode ?? this.postalCode,
      additionalNumber: additionalNumber ?? this.additionalNumber,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}