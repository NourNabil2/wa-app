// lib/features/brand/domain/entities/brand_entity.dart
import 'package:equatable/equatable.dart';
import 'package:fastway/features/home/domain/entities/product_entity.dart';

class BrandEntity extends Equatable {
  final String id;
  final String name;
  final String? nameAr;
  final String? logoUrl;
  final String? description;
  final String? country;
  final List<ProductEntity> products;
  final int total;
  final int currentPage;
  final int lastPage;

  const BrandEntity({
    required this.id,
    required this.name,
    this.nameAr,
    this.logoUrl,
    this.description,
    this.country,
    this.products = const [],
    this.total = 0,
    this.currentPage = 1,
    this.lastPage = 1,
  });

  @override
  List<Object?> get props => [id, name, nameAr, logoUrl, description, country, products, total, currentPage, lastPage];
}
