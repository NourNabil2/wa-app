import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_constans.dart';
import 'exceptions.dart';
import 'failures.dart';

class ErrorHandler {

  static const Map<String, String> _serverMessageMap = {
    'please verify your email first.':      'errors.server.accountNotVerified',
    'please verify your email first':       'errors.server.accountNotVerified',
    'invalid credentials.':                 'errors.server.invalidCredentials',
    'unauthenticated':                      'errors.server.unauthorized',
    'unauthorized':                         'errors.server.unauthorized',
    'email already taken':                  'errors.server.emailTaken',
    'email has already been taken':         'errors.server.emailTaken',
    'the email has already been taken':     'errors.server.emailTaken',
    'user not found':                       'errors.server.userNotFound',
    'wrong password':                       'errors.server.invalidCredentials',
    'token expired':                        'errors.server.tokenExpired',
    'token is invalid':                     'errors.server.tokenExpired',
    'server error':                         'errors.server.internal',
    'too many requests':                    'errors.server.tooManyRequests',
    'validation error':                     'errors.server.invalidData',
    'not found':                            'errors.server.notFound',
    'forbidden':                            'errors.server.forbidden',
  };

  static String _translateMessage(String raw) {
    if (raw.isEmpty) return raw;
    final key = _serverMessageMap[raw.toLowerCase().trim()];
    return key != null ? key.tr() : raw;
  }

  static Failure handleException(Object error, [StackTrace? stackTrace]) {
    _logError(error, stackTrace);

    if (error is ServerException) {
      return ServerFailure(_translateMessage(error.message), error.code);
    } else if (error is NetworkException) {
      return NetworkFailure(error.message, error.code);
    } else if (error is CacheException) {
      return CacheFailure(error.message, error.code);
    } else if (error is ValidationException) {
      return ValidationFailure(_translateMessage(error.message), error.code);
    } else if (error is UnauthorizedException) {
      return UnauthorizedFailure(_translateMessage(error.message), error.code);
    } else if (error is DioException) {
      return _handleDioError(error);
    } else {
      return ServerFailure('errors.server.unexpected'.tr(), 'UNKNOWN_ERROR');
    }
  }

  static Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure('errors.network.timeout'.tr(), ErrorMessages.connectionTimeout);
      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);
      case DioExceptionType.cancel:
        return NetworkFailure('errors.network.cancelled'.tr(), ErrorMessages.cancelledRequest);
      case DioExceptionType.connectionError:
        return NetworkFailure('errors.network.connection'.tr(), ErrorMessages.networkError);
      case DioExceptionType.badCertificate:
        return NetworkFailure('errors.network.certificate'.tr(), 'CERTIFICATE_ERROR');
      case DioExceptionType.unknown:
        return NetworkFailure('errors.network.serverConnection'.tr(), 'CONNECTION_ERROR');
    }
  }

  static Failure _handleResponseError(Response? response) {
    if (response == null) {
      return ServerFailure('errors.network.noResponse'.tr(), 'NO_RESPONSE');
    }

    final statusCode = response.statusCode ?? 0;
    final rawMessage = _extractErrorMessage(response.data);
    final message = _translateMessage(rawMessage);

    switch (statusCode) {
      case 400:
        return ServerFailure(
          message.isNotEmpty ? message : 'errors.server.badRequest'.tr(),
          ErrorMessages.badRequest,
        );
      case 401:
        return UnauthorizedFailure(
          message.isNotEmpty ? message : 'errors.server.unauthorized'.tr(),
          ErrorMessages.unauthorized,
        );
      case 403:
        return ServerFailure(
          message.isNotEmpty ? message : 'errors.server.forbidden'.tr(),
          ErrorMessages.forbidden,
        );
      case 404:
        return ServerFailure(
          message.isNotEmpty ? message : 'errors.server.notFound'.tr(),
          ErrorMessages.notFound,
        );
      case 422:
        return ValidationFailure(
          message.isNotEmpty ? message : 'errors.server.invalidData'.tr(),
          ErrorMessages.unexpectedError,
        );
      case 500:
      case 502:
      case 503:
        return ServerFailure('errors.server.internal'.tr(), ErrorMessages.serverError);
      default:
        return ServerFailure(
          message.isNotEmpty ? message : 'errors.server.unexpected'.tr(),
          'HTTP_$statusCode',
        );
    }
  }

  static String _extractErrorMessage(dynamic data) {
    if (data == null) return '';

    if (data is Map<String, dynamic>) {
      if (data.containsKey('message')) {
        return data['message'].toString();
      }
      if (data.containsKey('error')) {
        final error = data['error'];
        if (error is String) return error;
        if (error is Map && error.containsKey('message')) {
          return error['message'].toString();
        }
      }
      if (data.containsKey('errors')) {
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          }
          return firstError.toString();
        }
        if (errors is List && errors.isNotEmpty) {
          return errors.first.toString();
        }
      }
    }

    if (data is String) return data;
    return '';
  }

  static void _logError(Object error, StackTrace? stackTrace) {
    debugPrint('Error: $error');
    if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
  }
}
