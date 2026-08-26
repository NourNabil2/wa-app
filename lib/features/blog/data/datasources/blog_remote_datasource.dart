import 'package:fastway/core/api/base_api_services.dart';
import 'package:dio/dio.dart';
import 'package:fastway/core/api/model/endpoints.dart';
import 'package:fastway/core/api/model/http_method.dart';
import 'package:fastway/features/blog/domain/entities/blog_entity.dart';

abstract class BlogRemoteDataSource {
  Future<List<BlogCategory>> getCategories();
  Future<List<BlogPost>> getPosts({int page = 1, int perPage = 20, String? categoryId});
  Future<BlogPost> getPost(String slug);
}

class BlogRemoteDataSourceImpl implements BlogRemoteDataSource {
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

  final BaseApiServices _api;

  BlogRemoteDataSourceImpl(this._api);

  @override
  Future<List<BlogCategory>> getCategories() async {
    final response = await _api.request(
      method: HttpMethod.get,
      url: Endpoints.blogCategories,
    );
    final list = response['data'] as List? ?? [];
    return list
        .map((json) => BlogCategory.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<BlogPost>> getPosts({int page = 1, int perPage = 20, String? categoryId}) async {
    final response = await _api.request(
      method: HttpMethod.get,
      url: Endpoints.blog,
      queryParams: {
        'page':     page,
        'per_page': perPage,
        if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
      },
    );

    final data  = response['data'] ?? {};
    final posts = (data['posts'] as List? ?? [])
        .map((json) => BlogPost.fromJson(json as Map<String, dynamic>))
        .toList();
    return posts;
  }

  @override
  Future<BlogPost> getPost(String slug) async {
    final response = await _api.request(
      method: HttpMethod.get,
      url: '${Endpoints.blog}/$slug',
    );
    return BlogPost.fromJson(response['data'] as Map<String, dynamic>);
  }
}
