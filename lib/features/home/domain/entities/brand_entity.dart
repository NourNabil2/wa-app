import 'package:equatable/equatable.dart';

class BrandEntity extends Equatable {
  final String id;
  final String name;
  final String? nameAr;
  final String logoUrl;
  final String? country;

  const BrandEntity({
    required this.id,
    required this.name,
    this.nameAr,
    required this.logoUrl,
    this.country,
  });

  @override
  List<Object?> get props => [id, name, nameAr, logoUrl, country];
}
