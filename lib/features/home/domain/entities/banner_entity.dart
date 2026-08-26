// lib/features/home/domain/entities/banner_entity.dart
// BUG-25,47: BannerEntity for API-driven home screen banners
import 'package:equatable/equatable.dart';

class BannerEntity extends Equatable {
  final String id;
  final String title;
  final String titleAr;
  final String imageUrl;
  final String? linkUrl; // BUG-47 FIX: link URL now part of entity

  const BannerEntity({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.imageUrl,
    this.linkUrl,
  });

  @override
  List<Object?> get props => [id, title, titleAr, imageUrl, linkUrl];
}
