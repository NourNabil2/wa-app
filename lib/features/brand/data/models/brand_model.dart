// lib/features/brand/data/models/brand_model.dart
import 'package:fastway/features/brand/domain/entities/brand_entity.dart';
import 'package:fastway/features/home/data/model/product_model.dart';

class BrandModel extends BrandEntity {
  const BrandModel({
    required super.id,
    required super.name,
    super.nameAr,
    super.logoUrl,
    super.description,
    super.country,
    super.products,
    super.total,
    super.currentPage,
    super.lastPage,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    String ss(dynamic v, [String fallback = '']) {
      if (v == null) return fallback;
      if (v is String) return v;
      if (v is Map) return v['en']?.toString() ?? v.values.firstOrNull?.toString() ?? fallback;
      return v.toString();
    }
    final brandJson = json['brand'] as Map<String, dynamic>? ?? json;
    final rawProducts = json['products'] as List<dynamic>? ?? [];
    return BrandModel(
      id: brandJson['id'].toString(),
      name: ss(brandJson['name']),
      nameAr: brandJson['name_ar'] != null ? ss(brandJson['name_ar']) : null,
      logoUrl: brandJson['logo_url']?.toString(),
      description: brandJson['description'] != null ? ss(brandJson['description']) : null,
      country: brandJson['country']?.toString(),
      products: rawProducts.map((p) => ProductModel.fromJson(p as Map<String, dynamic>)).toList(),
      total: json['total'] as int? ?? 0,
      currentPage: json['current_page'] as int? ?? 1,
      lastPage: json['last_page'] as int? ?? 1,
    );
  }
}
