// lib/features/home/data/model/category_model.dart
import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.nameAr,
    required super.iconUrl,
    super.image,
    super.imageMobile,
    super.color,
    super.hasChildren,
    super.children,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    String ss(dynamic v, [String fallback = '']) {
      if (v == null) return fallback;
      if (v is String) return v;
      if (v is Map) return v['en']?.toString() ?? v.values.firstOrNull?.toString() ?? fallback;
      return v.toString();
    }
    String? ssOpt(dynamic v) {
      if (v == null) return null;
      if (v is String) return v.isEmpty ? null : v;
      if (v is Map) return v['en']?.toString() ?? v.values.firstOrNull?.toString();
      return v.toString();
    }

    return CategoryModel(
      id: json['id'].toString(),
      name: ss(json['name']),
      nameAr: ss(json['name_ar'] ?? json['name']),
      iconUrl: ss(json['icon_url'] ?? json['image_url']),
      image: ssOpt(json['image']),
      imageMobile: ssOpt(json['image_mobile']),
      color: ssOpt(json['color']),
      hasChildren: json['has_children'] as bool? ?? false,
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'name_ar': nameAr,
    'icon_url': iconUrl,
    'image': image,
    'image_mobile': imageMobile,
    'color': color,
    'has_children': hasChildren,
    'children': children.map((e) {
      if (e is CategoryModel) return e.toJson();
      // Fallback: wrap plain entity into a model first
      return CategoryModel(
        id: e.id, name: e.name, nameAr: e.nameAr, iconUrl: e.iconUrl,
        image: e.image, imageMobile: e.imageMobile, color: e.color,
        hasChildren: e.hasChildren, children: e.children,
      ).toJson();
    }).toList(),
  };

  CategoryEntity toEntity() => CategoryEntity(
    id: id,
    name: name,
    nameAr: nameAr,
    iconUrl: iconUrl,
    image: image,
    imageMobile: imageMobile,
    color: color,
    hasChildren: hasChildren,
    children: children,
  );
}
