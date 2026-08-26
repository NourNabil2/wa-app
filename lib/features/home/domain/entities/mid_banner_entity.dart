// lib/features/home/domain/entities/mid_banner_entity.dart
import 'package:equatable/equatable.dart';

class MidBannerEntity extends Equatable {
  final String layout;   // 'single' | 'grid'
  final String imageUrl;
  final String? linkUrl;
  final String? imageUrl2;
  final String? linkUrl2;

  const MidBannerEntity({
    this.layout = 'single',
    required this.imageUrl,
    this.linkUrl,
    this.imageUrl2,
    this.linkUrl2,
  });

  bool get isGrid => layout == 'grid' && imageUrl2 != null && imageUrl2!.isNotEmpty;

  @override
  List<Object?> get props => [layout, imageUrl, linkUrl, imageUrl2, linkUrl2];
}
