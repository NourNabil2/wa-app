import '../../domain/entities/popup_banner_entity.dart';

class PopupBannerModel extends PopupBannerEntity {
  const PopupBannerModel({
    required super.id,
    required super.imageUrl,
    super.title,
    super.titleAr,
    super.link,
  });

  factory PopupBannerModel.fromJson(Map<String, dynamic> json) {
    return PopupBannerModel(
      id: json['id'],
      imageUrl: json['image_url'] ?? '',
      title: json['title'],
      titleAr: json['title_ar'],
      link: json['link'],
    );
  }
}
