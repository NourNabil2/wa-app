// lib/core/api/api_error_handler.dart

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fastway/core/routes/app_routes.dart';

class ApiErrorHandler {
  /// Returns a user-facing, locale-aware error message.
  ///
  /// Priority:
  ///  1. `message_ar` / `message_en`  — explicit locale field from backend
  ///  2. `message` / `error`           — raw backend text (accept-language driven)
  ///  3. Laravel `errors` bag          — first validation message
  ///  4. HTTP status-code              — always translated via .tr()
  ///  5. Dio network error             — always translated via .tr()
  static String getMessage(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final data   = error.response!.data;
        final locale = _locale();

        if (data is Map) {
          // 1. Explicit locale-specific field (message_ar / message_en)
          final localized = data['message_$locale']?.toString().trim();
          if (localized != null && localized.isNotEmpty) return localized;

          // 2. Backend message (backend should have received Accept-Language header)
          final msg = data['message']?.toString().trim();
          if (msg != null && msg.isNotEmpty && msg.toLowerCase() != 'server error') {
            return msg;
          }
          final err = data['error']?.toString().trim();
          if (err != null && err.isNotEmpty) return err;

          // 3. Laravel validation errors bag
          final errors = data['errors'];
          if (errors is Map && errors.isNotEmpty) {
            final first = errors.values.first;
            if (first is List && first.isNotEmpty) return first.first.toString();
          }
        }

        // 4. HTTP status-code fallback — always uses app locale via .tr()
        switch (error.response!.statusCode) {
          case 400: return 'core.errors.bad_request'.tr();
          case 401: return 'core.errors.unauthorized'.tr();
          case 403: return 'core.errors.forbidden'.tr();
          case 404: return 'core.errors.not_found'.tr();
          case 422: return 'core.errors.validation_error'.tr();
          case 429: return 'core.errors.too_many_requests'.tr();
          case 500:
          case 502:
          case 503: return 'core.errors.server_error'.tr();
          default:  return 'core.errors.unexpected'.tr();
        }
      }

      // 5. Network / timeout — always localized via .tr()
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'core.errors.timeout'.tr();
        case DioExceptionType.connectionError:
          return 'core.errors.no_internet'.tr();
        case DioExceptionType.cancel:
          return 'core.errors.cancelled'.tr();
        default:
          return 'core.errors.connection_error'.tr();
      }
    }

    return 'core.errors.unknown_error'.tr();
  }

  /// Current app locale code ('ar' or 'en').
  static String _locale() {
    try {
      final ctx = AppRouter.navigatorKey.currentContext;
      if (ctx != null) {
        return EasyLocalization.of(ctx)?.locale.languageCode ?? 'ar';
      }
    } catch (_) {}
    return 'ar';
  }
}