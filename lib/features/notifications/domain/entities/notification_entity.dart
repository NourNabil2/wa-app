import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String type;
  final String title;
  final String titleAr;
  final String body;
  final String bodyAr;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.titleAr,
    required this.body,
    required this.bodyAr,
    this.data,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  /// Title for the given locale, falling back to the other language when one
  /// side is empty (e.g. older notifications stored before AR was populated).
  String localizedTitle(String languageCode) =>
      languageCode == 'ar'
          ? (titleAr.isNotEmpty ? titleAr : title)
          : (title.isNotEmpty ? title : titleAr);

  /// Body for the given locale, with the same EN/AR fallback as [localizedTitle].
  String localizedBody(String languageCode) =>
      languageCode == 'ar'
          ? (bodyAr.isNotEmpty ? bodyAr : body)
          : (body.isNotEmpty ? body : bodyAr);

  NotificationEntity copyWith({
    String? id,
    String? type,
    String? title,
    String? titleAr,
    String? body,
    String? bodyAr,
    Map<String, dynamic>? data,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      titleAr: titleAr ?? this.titleAr,
      body: body ?? this.body,
      bodyAr: bodyAr ?? this.bodyAr,
      data: data ?? this.data,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    // Backend item carries the full notification payload under `data`, which
    // includes both languages: title/title_ar and body/body_ar.
    final dataObj = json['data'] as Map<String, dynamic>?;
    return NotificationEntity(
      id: json['id'] as String,
      type: json['type'] as String,
      title: dataObj?['title'] as String? ?? 'Notification',
      titleAr: dataObj?['title_ar'] as String? ?? '',
      body: dataObj?['body'] as String? ?? '',
      bodyAr: dataObj?['body_ar'] as String? ?? '',
      data: dataObj,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  @override
  List<Object?> get props =>
      [id, type, title, titleAr, body, bodyAr, data, readAt, createdAt];
}
