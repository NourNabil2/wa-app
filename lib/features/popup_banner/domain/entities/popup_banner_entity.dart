import 'package:equatable/equatable.dart';

class PopupBannerEntity extends Equatable {
  final int id;
  final String imageUrl;
  final String? title;
  final String? titleAr;
  final String? link;

  const PopupBannerEntity({
    required this.id,
    required this.imageUrl,
    this.title,
    this.titleAr,
    this.link,
  });

  @override
  List<Object?> get props => [id, imageUrl, title, titleAr, link];
}
