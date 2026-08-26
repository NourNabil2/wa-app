// lib/features/home/domain/entities/category_entity.dart
// BUG-13,72 FIX: Added nameAr field and localizedName() for bilingual support
import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String name;    // English name
  final String nameAr; // Arabic name (BUG-13 FIX)
  final String iconUrl;
  final String? image;
  final String? imageMobile;
  final String? color;
  final bool hasChildren;
  final List<CategoryEntity> children;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.iconUrl,
    this.image,
    this.imageMobile,
    this.color,
    this.hasChildren = false,
    this.children = const [],
  });

  /// Returns the localized name based on current locale
  String localizedName(String locale) => locale == 'ar' ? nameAr : name;

  @override
  List<Object?> get props => [id, name, nameAr, iconUrl, image, imageMobile, color, hasChildren, children];
}