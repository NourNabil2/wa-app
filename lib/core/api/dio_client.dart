import 'package:flutter/foundation.dart';
import 'package:fastway/core/api/base_api_services.dart';
import 'package:fastway/core/api/model/http_method.dart';
import 'package:fastway/core/routes/routes.dart';
import 'package:fastway/core/utils/app_constans.dart';
import 'package:fastway/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:fastway/features/user_data/user_repo.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioApiService extends BaseApiServices {
  final Dio _dio;

  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  DioApiService(this._dio) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();

          // 1. Bearer token — authenticated users only
          final token = UserRepository().currentUser?.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // 2. X-Session-ID — ALWAYS sent (guest cart + cart-merge on login)
          final sessionId = prefs.getString(AppConstants.sessionKey);
          if (sessionId != null && sessionId.isNotEmpty) {
            options.headers['X-Session-ID'] = sessionId;
          }

          // 3. Accept + Accept-Language
          //
          // The language MUST come from the persisted setting, not from a widget
          // context: SettingsCubit writes this key on every switch and main() reads
          // it back as EasyLocalization's startLocale, so it is always in sync with
          // the UI. Reading it here also keeps the header correct for requests that
          // fire before the first frame, when no context exists yet.
          //
          // (This used to resolve the locale through a GlobalKey declared on this
          // class, which was never handed to MaterialApp — that uses
          // AppRouter.navigatorKey. currentContext was therefore always null and
          // every request silently claimed 'ar', whatever the app language.)
          options.headers['Accept'] = 'application/json';
          options.headers['Accept-Language'] =
              prefs.getString(SettingsCubit.langKey) ?? 'ar';

          handler.next(options);
        },

        onError: (DioException error, handler) {
          if (error.response?.statusCode == 401) {
            UserRepository().clearUser();
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              Routes.auth,
                  (route) => false,
            );
          }
          handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }
  }

  @override
  Future<dynamic> request({
    required HttpMethod method,
    required String url,
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.request(
        url,
        data: body,
        queryParameters: queryParams,
        options: Options(
          method: method.name.toUpperCase(),
          headers: headers,
        ),
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}