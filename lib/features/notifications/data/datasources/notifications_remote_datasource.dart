import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/api/base_api_services.dart';
import '../../../../core/api/model/http_method.dart';
import '../../../../core/api/model/endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/notification_entity.dart';

abstract class NotificationsRemoteDataSource {
  Future<List<NotificationEntity>> getNotifications({int page = 1});
  Future<void> markAsRead(List<String> ids);
  Future<int> getUnreadCount();
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  /// Returns the backend's human-readable message from a DioException.
  /// Priority: JSON `message` → JSON `error` → status-code fallback.
  static String _dioMsg(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'] ?? data['error'];
      if (msg != null && msg.toString().trim().isNotEmpty) return msg.toString().trim();
      // Laravel validation: {"errors":{"field":["msg"]}}
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
    }
    switch (e.response?.statusCode) {
      case 400: return 'errors.server.badRequest'.tr();
      case 401: return 'errors.auth.subtitle'.tr();
      case 403: return 'errors.server.forbidden'.tr();
      case 404: return 'errors.server.notFound'.tr();
      case 422: return 'errors.server.invalidData'.tr();
      case 429: return 'errors.server.tooManyRequests'.tr();
      case 500: return 'errors.server.internal'.tr();
      default:
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout) {
          return 'errors.network.connection'.tr();
        }
        return 'errors.server.unexpected'.tr();
    }
  }

  // Use the shared API service (not a raw Dio) so the auth Bearer + X-Session-ID
  // headers are ALWAYS attached by its interceptor. The previous raw-Dio injection
  // depended on DioApiService being lazily constructed first to install the
  // interceptor — otherwise these requests went out unauthenticated (401) and the
  // bell silently showed nothing.
  final BaseApiServices api;

  NotificationsRemoteDataSourceImpl({required this.api});

  @override
  Future<List<NotificationEntity>> getNotifications({int page = 1}) async {
    try {
      // request() returns the decoded body directly. Backend shape:
      //   { status, unread_count, data: { current_page, data: [ ...items ] }, meta }
      final body = await api.request(
        method: HttpMethod.get,
        url: Endpoints.notifications,
        queryParams: {'page': page},
      );
      final List data = body?['data']?['data'] ?? [];
      return data.map((e) => NotificationEntity.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ServerException(_dioMsg(e), 'DIO_ERROR');
    }
  }

  @override
  Future<void> markAsRead(List<String> ids) async {
    try {
      await api.request(
        method: HttpMethod.post,
        url: Endpoints.notificationsMarkRead,
        body: ids.isNotEmpty ? {'ids': ids} : {},
      );
    } on DioException catch (e) {
      throw ServerException(_dioMsg(e), 'DIO_ERROR');
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final body = await api.request(
        method: HttpMethod.get,
        url: Endpoints.notificationsUnreadCount,
      );
      // unread_count is TOP-LEVEL, NOT nested under `data` (was the bug that kept
      // the bell badge stuck at 0).
      return (body?['unread_count'] as num?)?.toInt() ?? 0;
    } on DioException {
      return 0;
    }
  }
}
