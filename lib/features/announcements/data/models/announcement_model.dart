import '../../domain/entities/announcement_entity.dart';

class AnnouncementModel extends AnnouncementEntity {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.titleAr,
    required super.body,
    required super.bodyAr,
    super.link,
    super.bgColor,
    super.textColor,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'],
      title: json['title'] ?? '',
      titleAr: json['title_ar'] ?? '',
      body: json['body'] ?? '',
      bodyAr: json['body_ar'] ?? '',
      link: json['link'],
      bgColor: json['bg_color'],
      textColor: json['text_color'],
    );
  }
}
