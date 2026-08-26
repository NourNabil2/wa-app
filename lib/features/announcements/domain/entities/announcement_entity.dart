import 'package:equatable/equatable.dart';

class AnnouncementEntity extends Equatable {
  final int id;
  final String title;
  final String titleAr;
  final String body;
  final String bodyAr;
  final String? link;
  /// Hex color string from admin e.g. "#1A1A1A". Null → use theme default.
  final String? bgColor;
  /// Hex color string from admin e.g. "#FFFFFF". Null → use theme default.
  final String? textColor;

  const AnnouncementEntity({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.body,
    required this.bodyAr,
    this.link,
    this.bgColor,
    this.textColor,
  });

  @override
  List<Object?> get props => [id, title, titleAr, body, bodyAr, link, bgColor, textColor];
}
