import 'package:equatable/equatable.dart';

class CityEntity extends Equatable {
  final String name;
  final String nameAr;
  final String code;
  final double lat;
  final double lng;

  const CityEntity({
    required this.name,
    required this.nameAr,
    required this.code,
    required this.lat,
    required this.lng,
  });

  @override
  List<Object?> get props => [code];
}

class CountryEntity extends Equatable {
  final String code;
  final String name;
  final String nameAr;
  final String currency;
  final String phoneCode;

  const CountryEntity({
    required this.code,
    required this.name,
    required this.nameAr,
    required this.currency,
    required this.phoneCode,
  });

  @override
  List<Object?> get props => [code];
}