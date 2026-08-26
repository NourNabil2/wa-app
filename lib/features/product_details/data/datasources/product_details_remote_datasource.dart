// lib/features/product_details/data/datasources/product_details_remote_datasource.dart

import 'package:fastway/core/api/base_api_services.dart';
import 'package:dio/dio.dart';
import 'package:fastway/core/api/api_error_handler.dart';
import 'package:fastway/core/api/model/endpoints.dart';
import 'package:fastway/core/api/model/http_method.dart';
import 'package:fastway/core/errors/exceptions.dart';
import '../models/product_details_model.dart';

abstract class ProductDetailsRemoteDataSource {
  Future<ProductDetailsModel> getProductDetails(String productId, {double? lat, double? lng});
  Future<String> joinWaitlist(String productId);
  Future<String> notifyMe(String productId);
  Future<List<Map<String, dynamic>>> fetchQuestions(String productId);
  Future<String> submitQuestion(String productId, String question);
  Future<String> submitReview(String productId, int rating, String? comment);
}

class ProductDetailsRemoteDataSourceImpl implements ProductDetailsRemoteDataSource {
  final BaseApiServices _api;
  ProductDetailsRemoteDataSourceImpl(this._api);

  @override
  Future<ProductDetailsModel> getProductDetails(String productId, {double? lat, double? lng}) async {
    try {
      final params = <String, dynamic>{};
      if (lat != null && lng != null) {
        params['lat'] = lat;
        params['lng'] = lng;
      }
      final res = await _api.request(
        method: HttpMethod.get,
        url: '${Endpoints.products}/$productId',
        queryParams: params.isEmpty ? null : params,
      );
      final data = res['data'] ?? res;
      return ProductDetailsModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'PRODUCT_DETAILS_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'PRODUCT_DETAILS_ERROR');
    }
  }

  @override
  Future<String> joinWaitlist(String productId) async {
    try {
      final res = await _api.request(
        method: HttpMethod.post,
        url: '${Endpoints.products}/$productId/waitlist',
      );
      return res['message']?.toString() ?? 'You will be notified when this product is back in stock.';
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'WAITLIST_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'WAITLIST_ERROR');
    }
  }

  @override
  Future<String> notifyMe(String productId) async {
    try {
      final res = await _api.request(
        method: HttpMethod.post,
        url: Endpoints.stockNotifications,
        body: {'product_id': productId},
      );
      return res['message']?.toString() ?? 'You will be notified when this product is back in stock.';
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'NOTIFY_ME_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'NOTIFY_ME_ERROR');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchQuestions(String productId) async {
    try {
      final res = await _api.request(
        method: HttpMethod.get,
        url: '${Endpoints.products}/$productId/questions',
      );
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final list = data['questions'] as List<dynamic>? ?? [];
      return list.map((q) => q as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'QUESTIONS_FETCH_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'QUESTIONS_FETCH_ERROR');
    }
  }

  @override
  Future<String> submitQuestion(String productId, String question) async {
    try {
      final res = await _api.request(
        method: HttpMethod.post,
        url: '${Endpoints.products}/$productId/questions',
        body: {'question': question},
      );
      return res['message']?.toString() ?? 'Your question has been submitted.';
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'QUESTION_SUBMIT_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'QUESTION_SUBMIT_ERROR');
    }
  }

  @override
  Future<String> submitReview(String productId, int rating, String? comment) async {
    try {
      final res = await _api.request(
        method: HttpMethod.post,
        url: '${Endpoints.products}/$productId/reviews',
        body: {'rating': rating, 'comment': comment},
      );
      return res['message']?.toString() ?? 'Your review has been submitted.';
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'REVIEW_SUBMIT_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'REVIEW_SUBMIT_ERROR');
    }
  }
}