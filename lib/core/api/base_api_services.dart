import 'model/http_method.dart';

abstract class BaseApiServices {
  /// Unified method to handle all HTTP requests
  ///
  /// [method]     - The HTTP verb (GET, POST, PUT, DELETE, PATCH, ...)
  /// [url]        - Endpoint (relative or absolute)
  /// [body]       - Request body (Map, String, FormData for Dio, etc.)
  /// [queryParams]- Optional query parameters
  /// [headers]    - Optional additional headers (Authorization is handled automatically)
  Future<dynamic> request({
    required HttpMethod method,
    required String url,
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  });
}