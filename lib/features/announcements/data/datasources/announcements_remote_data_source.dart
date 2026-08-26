import 'package:dio/dio.dart';
import 'package:fastway/core/api/model/endpoints.dart';
import 'package:fastway/core/errors/exceptions.dart';
import '../models/announcement_model.dart';

abstract class AnnouncementsRemoteDataSource {
  Future<List<AnnouncementModel>> getAnnouncements();
}

class AnnouncementsRemoteDataSourceImpl implements AnnouncementsRemoteDataSource {
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
      case 400: return 'طلب غير صحيح';
      case 401: return 'يرجى تسجيل الدخول أولاً';
      case 403: return 'غير مسموح بهذا الإجراء';
      case 404: return 'البيانات غير موجودة';
      case 422: return 'البيانات المدخلة غير صحيحة';
      case 429: return 'طلبات كثيرة، يرجى الانتظار';
      case 500: return 'خطأ في الخادم، حاول لاحقاً';
      default:
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout) {
          return 'تحقق من اتصالك بالإنترنت';
        }
        return 'حدث خطأ غير متوقع';
    }
  }

  final Dio dio;

  AnnouncementsRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<AnnouncementModel>> getAnnouncements() async {
    try {
      final response = await dio.get(Endpoints.announcements);
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => AnnouncementModel.fromJson(json)).toList();
      } else {
        throw ServerException('Failed to fetch announcements');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
