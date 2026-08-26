import 'package:fastway/core/api/model/endpoints.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fastway/core/api/api_error_handler.dart';
import 'package:fastway/features/home/data/model/category_model.dart';
import 'package:fastway/features/home/data/model/product_model.dart';
import 'package:fastway/features/home/domain/entities/banner_entity.dart';
import '../../../../core/api/base_api_services.dart';
import '../../../../core/api/model/http_method.dart';
import '../../../../core/errors/exceptions.dart';

abstract class ProductsRemoteDataSource {
  Future<List<ProductModel>> getProducts({int page, int perPage});
  Future<List<ProductModel>> getFeatured();
  Future<List<ProductModel>> getNewArrivals();
  Future<List<CategoryModel>> getCategories();
  Future<List<BannerEntity>> getBanners();
  Future<Map<String, dynamic>> getHome({double? lat, double? lng, String? addressId});
  Future<Map<String, dynamic>> searchProducts(String query, {int page});
}

class ProductsRemoteDataSourceImpl implements ProductsRemoteDataSource {
  final BaseApiServices _apiServices;

  ProductsRemoteDataSourceImpl(this._apiServices);

  @override
  Future<List<ProductModel>> getProducts({int page = 1, int perPage = 10}) async {
    return _processRequest<ProductModel>(
      url: Endpoints.products,
      queryParams: {'page': page, 'per_page': perPage},
      mapper: (json) => ProductModel.fromJson(json),
      errorLabel: 'PRODUCTS_FETCH_ERROR',
    );
  }

  @override
  Future<List<ProductModel>> getFeatured() async {
    return _processRequest<ProductModel>(
      url: Endpoints.featured,
      mapper: (json) => ProductModel.fromJson(json),
      errorLabel: 'FEATURED_FETCH_ERROR',
    );
  }

  @override
  Future<List<ProductModel>> getNewArrivals() async {
    return _processRequest<ProductModel>(
      url: Endpoints.newArrivals,
      mapper: (json) => ProductModel.fromJson(json),
      errorLabel: 'NEW_ARRIVALS_FETCH_ERROR',
    );
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    return _processRequest<CategoryModel>(
      url: Endpoints.categories,
      mapper: (json) => CategoryModel.fromJson(json),
      errorLabel: 'CATEGORIES_FETCH_ERROR',
    );
  }

  @override
  Future<List<BannerEntity>> getBanners() async {
    final primaryEndpoint = kIsWeb ? Endpoints.banners : Endpoints.mobileBanners;
    final fallbackEndpoint = kIsWeb ? Endpoints.mobileBanners : Endpoints.banners;

    try {
      final banners = await _processRequest<BannerEntity>(
        url: primaryEndpoint,
        mapper: (json) => BannerEntity(
          id: json['id'].toString(),
          title: (json['title'] ?? '') as String,
          titleAr: (json['title_ar'] ?? '') as String,
          imageUrl: (json['image_url'] ?? json['image'] ?? '') as String,
          linkUrl: json['link'] as String?,
        ),
        errorLabel: 'PRIMARY_BANNERS_FETCH_ERROR',
      );
      
      if (banners.isNotEmpty) {
        return banners;
      }
    } catch (_) {
      // Fallback if the endpoint fails (e.g., 404 or not implemented yet)
    }

    // Fallback to default banners
    return _processRequest<BannerEntity>(
      url: fallbackEndpoint,
      mapper: (json) => BannerEntity(
        id: json['id'].toString(),
        title: (json['title'] ?? '') as String,
        titleAr: (json['title_ar'] ?? '') as String,
          imageUrl: (json['image_url'] ?? json['image'] ?? '') as String,
        linkUrl: json['link'] as String?,
      ),
      errorLabel: 'FALLBACK_BANNERS_FETCH_ERROR',
    );
  }

  @override
  Future<Map<String, dynamic>> getHome({double? lat, double? lng, String? addressId}) async {
    try {
      final params = <String, dynamic>{};
      // Priority: address_id (selected address) > explicit lat/lng (GPS)
      // The backend ResolveDeliveryCoordinates middleware uses address_id as
      // Priority 2, which overrides the default-address fallback entirely.
      if (addressId != null) {
        params['address_id'] = addressId;
      } else if (lat != null && lng != null) {
        params['lat'] = lat;
        params['lng'] = lng;
      }
      final response = await _apiServices.request(
        method: HttpMethod.get,
        url: Endpoints.home,
        queryParams: params.isEmpty ? null : params,
      );
      return (response['data'] ?? response) as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'HOME_FETCH_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'HOME_FETCH_ERROR');
    }
  }

  @override
  Future<Map<String, dynamic>> searchProducts(String query, {int page = 1}) async {
    try {
      final response = await _apiServices.request(
        method: HttpMethod.get,
        url: Endpoints.search,
        queryParams: {'q': query, 'page': page},
      );
      return (response['data'] ?? response) as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), 'SEARCH_FETCH_ERROR');
    } catch (e) {
      throw ServerException(e.toString(), 'SEARCH_FETCH_ERROR');
    }
  }

  /// Generic Helper Method for API Requests
  Future<List<T>> _processRequest<T>({
    required String url,
    required T Function(Map<String, dynamic> json) mapper,
    required String errorLabel,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _apiServices.request(
        method: HttpMethod.get,
        url: url,
        queryParams: queryParams,
      );

      List<dynamic> data = [];

      if (response['data'] is List) {
        data = response['data'] as List<dynamic>;
      } else if (response['data'] is Map && response['data']['data'] is List) {
        data = response['data']['data'] as List<dynamic>;
      }

      return data.map((item) => mapper(item as Map<String, dynamic>)).toList();
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(ApiErrorHandler.getMessage(e), errorLabel);
    } catch (e) {
      throw ServerException(e.toString(), errorLabel);
    }
  }
}